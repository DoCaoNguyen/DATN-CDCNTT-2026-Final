const bcrypt = require('bcrypt');
const walletRepository = require('./wallet.repository');
const transactionRepo = require('../transaction/transaction.repository');

const walletService = {
    getWalletInfo: async (userId) => {
        const wallet = await walletRepository.getBalanceByUserId(userId);
        
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }

        return {
            wallet_code: wallet.wallet_code,
            currency: wallet.currency,
            status: wallet.status,
            available_balance: wallet.available_balance ? wallet.available_balance.toString() : "0",
            locked_balance: wallet.locked_balance ? wallet.locked_balance.toString() : "0",
            loyalty_points: wallet.loyalty_points ? Math.floor(Number(wallet.loyalty_points)).toString() : "0",
            is_pin_set: !!wallet.pin_hash
        };
    },

    verifyPin: async (userId, pin) => {
        const wallet = await walletRepository.findByUserId(userId);
        if (!wallet || !wallet.pin_hash) {
            throw new Error('Pin_Not_Set');
        }

        const isValid = await bcrypt.compare(pin, wallet.pin_hash);
        return isValid;
    },

    getWalletSummary: async (userId) => {
        const wallet = await walletService.getWalletInfo(userId);
        return {
            wallet,
            capabilities: {
                can_topup: wallet.status === 'ACTIVE',
                can_transfer: wallet.status === 'ACTIVE',
                can_payment: wallet.status === 'ACTIVE'
            }
        };
    },

    lockByAdmin: async ({ walletId, actorId, reason, ipAddress, userAgent }) => {
        if (!reason || !String(reason).trim()) throw new Error('Reason_Required');
        const pool = require('../../config/db');
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const wallet = await walletRepository.findByIdForUpdate(client, walletId);
            if (!wallet) throw new Error('Wallet_Not_Found');
            if (wallet.status === 'CLOSED') throw new Error('Wallet_Closed');
            if (wallet.status === 'LOCKED') throw new Error('Wallet_Already_Locked');

            const updated = await walletRepository.lockByAdmin(client, {
                walletId,
                actorId,
                reason: String(reason).trim()
            });

            const AuditLog = require('../system/models/audit_log.model');
            try {
                await AuditLog.create({
                    trace_id: `trace-wallet-${Date.now()}`,
                    actor_type: 'ADMIN',
                    actor_id: actorId,
                    action: 'WALLET_LOCKED',
                    entity_type: 'wallets',
                    entity_id: walletId,
                    old_data: { status: wallet.status },
                    new_data: { status: updated.status, lock_reason: updated.lock_reason, locked_at: updated.locked_at, locked_by: updated.locked_by },
                    metadata: { wallet_no: wallet.wallet_no },
                    reason: String(reason).trim(),
                    ip_address: ipAddress || null,
                    user_agent: userAgent || null
                });
            } catch (err) {
                console.error('[AuditLog] Error writing to MongoDB:', err);
            }

            await client.query('COMMIT');
            return updated;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    unlockByAdmin: async ({ walletId, actorId, reason, ipAddress, userAgent }) => {
        if (!reason || !String(reason).trim()) throw new Error('Reason_Required');
        const pool = require('../../config/db');
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const wallet = await walletRepository.findByIdForUpdate(client, walletId);
            if (!wallet) throw new Error('Wallet_Not_Found');
            if (wallet.status === 'CLOSED') throw new Error('Wallet_Closed');
            if (wallet.status !== 'LOCKED') throw new Error('Wallet_Not_Locked');

            const updated = await walletRepository.unlockByAdmin(client, walletId);

            const AuditLog = require('../system/models/audit_log.model');
            try {
                await AuditLog.create({
                    trace_id: `trace-wallet-${Date.now()}`,
                    actor_type: 'ADMIN',
                    actor_id: actorId,
                    action: 'WALLET_UNLOCKED',
                    entity_type: 'wallets',
                    entity_id: walletId,
                    old_data: { status: wallet.status, lock_reason: wallet.lock_reason, locked_at: wallet.locked_at, locked_by: wallet.locked_by },
                    new_data: { status: updated.status },
                    metadata: { wallet_no: wallet.wallet_no, previous_lock_reason: wallet.lock_reason },
                    reason: String(reason).trim(),
                    ip_address: ipAddress || null,
                    user_agent: userAgent || null
                });
            } catch (err) {
                console.error('[AuditLog] Error writing to MongoDB:', err);
            }

            await client.query('COMMIT');
            return updated;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    getLimits: async (userId) => {
        const wallet = await walletRepository.findByUserId(userId);
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }
        return await walletRepository.getLimitsAndUsage(wallet.id);
    },

    setWalletCode: async (userId, pinCode) => {
        try {
            const saltRounds = 10;
            const pinHash = await bcrypt.hash(pinCode, saltRounds);
            
            const result = await walletRepository.updatePinHash(userId, pinHash);
            
            // Unlock wallet if it was locked
            const txRepo = require('../transaction/transaction.repository');
            const wallet = await txRepo.getWalletByUserId(userId);
            if (wallet) {
                await txRepo.resetPinAttempts(wallet.id);
            }
            
            if (!result) {
                throw new Error('Wallet_Not_Found');
            }
            
            return pinCode;

        } catch (error) {
            throw error; 
        }
    },

    getPersonalQR: async (userId, amount, note) => {
        const user = await walletRepository.getUserInfoForQR(userId);
        if (!user) {
            throw new Error('User_Not_Found');
        }

        let qrContent = `viwallet://transfer?phone=${encodeURIComponent(user.phone || '')}&name=${encodeURIComponent(user.full_name || '')}`;
        if (amount) {
            qrContent += `&amount=${amount}`;
        }
        if (note) {
            qrContent += `&note=${encodeURIComponent(note)}`;
        }

        const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=400x400&ecc=L&data=${encodeURIComponent(qrContent)}`;

        return {
            phone: user.phone,
            full_name: user.full_name,
            amount: amount ? amount.toString() : null,
            note: note || null,
            qr_content: qrContent,
            qr_image_url: qrImageUrl
        };
    },

    getLinkedBanks: async (userId) => {
        const wallet = await walletRepository.findByUserId(userId);
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }
        return await walletRepository.getLinkedBanks(wallet.id);
    },

    linkBank: async (userId, bankName, bankCode, cardNumber, cardHolderName, pin) => {
        const wallet = await transactionRepo.getWalletForPinCheck(userId);
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }

        if (wallet.pin_locked_until) {
            const now = new Date();
            const lockedUntil = new Date(wallet.pin_locked_until);
            if (now < lockedUntil) {
                throw new Error('Wallet_Locked_PIN');
            } else {
                await transactionRepo.resetPinAttempts(wallet.id);
                wallet.pin_failed_attempts = 0;
            }
        }

        if (!wallet.pin_hash) {
            throw new Error('PIN_Not_Set');
        }

        const isPinMatch = await bcrypt.compare(pin, wallet.pin_hash);
        if (!isPinMatch) {
            const newAttempts = (wallet.pin_failed_attempts || 0) + 1;
            
            if (newAttempts >= 3) {
                const lockTime = new Date(Date.now() + 30 * 60000);
                await transactionRepo.updatePinAttempts(wallet.id, newAttempts, lockTime);
                throw new Error('Wallet_Locked_PIN');
            } else {
                await transactionRepo.updatePinAttempts(wallet.id, newAttempts, null);
                throw new Error(`Wrong_PIN_${3 - newAttempts}`);
            }
        }

        if (wallet.pin_failed_attempts > 0) {
            await transactionRepo.resetPinAttempts(wallet.id);
        }

        return await walletRepository.linkBank(wallet.id, bankName, bankCode, cardNumber, cardHolderName);
    },

    verifyPin: async (userId, pin) => {
        const wallet = await transactionRepo.getWalletForPinCheck(userId);
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }

        if (wallet.pin_locked_until) {
            const now = new Date();
            const lockedUntil = new Date(wallet.pin_locked_until);
            if (now < lockedUntil) {
                throw new Error('Wallet_Locked_PIN');
            } else {
                await transactionRepo.resetPinAttempts(wallet.id);
                wallet.pin_failed_attempts = 0;
            }
        }

        if (!wallet.pin_hash) {
            throw new Error('PIN_Not_Set');
        }

        const isPinMatch = await bcrypt.compare(pin, wallet.pin_hash);
        if (!isPinMatch) {
            const newAttempts = (wallet.pin_failed_attempts || 0) + 1;
            
            if (newAttempts >= 3) {
                const lockTime = new Date(Date.now() + 30 * 60000);
                await transactionRepo.updatePinAttempts(wallet.id, newAttempts, lockTime);
                throw new Error('Wallet_Locked_PIN');
            } else {
                await transactionRepo.updatePinAttempts(wallet.id, newAttempts, null);
                throw new Error(`Wrong_PIN_${3 - newAttempts}`);
            }
        }

        if (wallet.pin_failed_attempts > 0) {
            await transactionRepo.resetPinAttempts(wallet.id);
        }

        return true;
    }
};

module.exports = walletService;