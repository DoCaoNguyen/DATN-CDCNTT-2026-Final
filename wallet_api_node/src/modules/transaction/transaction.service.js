const bcrypt = require('bcrypt');
const pool = require('../../config/db');
const repo = require('./transaction.repository');
const { emitToUser } = require('../../utils/socket');
const kycService = require('../kyc/kyc.service');

const transactionService = {
    deposit: async (userId, amount, pin, faceImagePath, externalReference) => { 
        const wallet = await repo.getWalletForPinCheck(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const extRef = (externalReference && /^\d{12}$/.test(externalReference))
            ? externalReference
            : Math.floor(100000000000 + Math.random() * 900000000000).toString();

        // Verify based on amount (50,000,000 VND)
        if (amount < 50000000n) {
            if (!pin) throw new Error('PIN_Required');
            if (wallet.pin_locked_until) {
                const now = new Date();
                const lockedUntil = new Date(wallet.pin_locked_until);
                if (now < lockedUntil) {
                    throw new Error('Wallet_Locked_PIN');
                } else {
                    await repo.resetPinAttempts(wallet.id);
                    wallet.pin_failed_attempts = 0;
                }
            }
            if (!wallet.pin_hash) throw new Error('Wallet_Not_Found');
            const isPinMatch = await bcrypt.compare(pin, wallet.pin_hash);
            if (!isPinMatch) {
                const newAttempts = (wallet.pin_failed_attempts || 0) + 1;
                if (newAttempts >= 3) {
                    const lockTime = new Date(Date.now() + 30 * 60000);
                    await repo.updatePinAttempts(wallet.id, newAttempts, lockTime);
                    throw new Error('Wallet_Locked_PIN');
                } else {
                    await repo.updatePinAttempts(wallet.id, newAttempts, null);
                    throw new Error(`Wrong_PIN_${3 - newAttempts}`);
                }
            }
            if (wallet.pin_failed_attempts > 0) {
                await repo.resetPinAttempts(wallet.id);
            }
        } else {
            if (!faceImagePath) throw new Error('Face_Verification_Required');
            const kycRecord = await repo.getUserKycFaceImage(userId);
            if (!kycRecord || !kycRecord.face_image) {
                throw new Error('No_KYC_Record_Found');
            }
            const matchResult = await kycService.verifyFaceMatchFacePlusPlus(kycRecord.face_image, faceImagePath);
            if (!matchResult.faceFound || !matchResult.isMatch) {
                throw new Error('Face_Verification_Failed');
            }
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); 

            const balanceBefore = await repo.lockAndGetBalance(client, wallet.id);
            const balanceAfter = await repo.addBalance(client, wallet.id, amount);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'DEPOSIT', wallet.id, 'Nạp tiền từ ngân hàng liên kết');

            await repo.createLedgerEntry(client, ledgerTxId, wallet.id, 'CREDIT', amount, balanceBefore, balanceAfter);

            await repo.recordDeposit(client, wallet.id, amount, ledgerTxId, 'LINKED_BANK', extRef);

            await client.query('COMMIT'); 
            
            emitToUser(userId, 'balance_update', {
                type: 'DEPOSIT',
                amount: amount.toString(),
                newBalance: balanceAfter.toString()
            });

            return { 
                id: extRef,
                external_reference: extRef,
                amount: amount.toString(), 
                balanceBefore: balanceBefore.toString(), 
                balanceAfter: balanceAfter.toString() 
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    withdraw: async (userId, amount, pin, faceImagePath, linkedBankId, externalReference) => { 
        const wallet = await repo.getWalletForPinCheck(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const extRef = (externalReference && /^\d{12}$/.test(externalReference))
            ? externalReference
            : Math.floor(100000000000 + Math.random() * 900000000000).toString();

        // Verify based on amount (50,000,000 VND)
        if (amount < 50000000n) {
            if (!pin) throw new Error('PIN_Required');
            if (wallet.pin_locked_until) {
                const now = new Date();
                const lockedUntil = new Date(wallet.pin_locked_until);
                if (now < lockedUntil) {
                    throw new Error('Wallet_Locked_PIN');
                } else {
                    await repo.resetPinAttempts(wallet.id);
                    wallet.pin_failed_attempts = 0;
                }
            }
            if (!wallet.pin_hash) throw new Error('Wallet_Not_Found');
            const isPinMatch = await bcrypt.compare(pin, wallet.pin_hash);
            if (!isPinMatch) {
                const newAttempts = (wallet.pin_failed_attempts || 0) + 1;
                if (newAttempts >= 3) {
                    const lockTime = new Date(Date.now() + 30 * 60000);
                    await repo.updatePinAttempts(wallet.id, newAttempts, lockTime);
                    throw new Error('Wallet_Locked_PIN');
                } else {
                    await repo.updatePinAttempts(wallet.id, newAttempts, null);
                    throw new Error(`Wrong_PIN_${3 - newAttempts}`);
                }
            }
            if (wallet.pin_failed_attempts > 0) {
                await repo.resetPinAttempts(wallet.id);
            }
        } else {
            if (!faceImagePath) throw new Error('Face_Verification_Required');
            const kycRecord = await repo.getUserKycFaceImage(userId);
            if (!kycRecord || !kycRecord.face_image) {
                throw new Error('No_KYC_Record_Found');
            }
            const matchResult = await kycService.verifyFaceMatchFacePlusPlus(kycRecord.face_image, faceImagePath);
            if (!matchResult.faceFound || !matchResult.isMatch) {
                throw new Error('Face_Verification_Failed');
            }
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); 

            const balanceBefore = await repo.lockAndGetBalance(client, wallet.id);
            if (balanceBefore < amount) {
                throw new Error('Insufficient_Balance');
            }
            const balanceAfter = await repo.subtractBalance(client, wallet.id, amount);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'WITHDRAW', wallet.id, 'Rút tiền về ngân hàng liên kết');

            await repo.createLedgerEntry(client, ledgerTxId, wallet.id, 'DEBIT', amount, balanceBefore, balanceAfter);

            await repo.recordWithdrawal(client, wallet.id, amount, ledgerTxId, linkedBankId, extRef);

            await client.query('COMMIT'); 
            
            emitToUser(userId, 'balance_update', {
                type: 'WITHDRAW',
                amount: amount.toString(),
                newBalance: balanceAfter.toString()
            });

            return { 
                id: extRef,
                external_reference: extRef,
                amount: amount.toString(), 
                balanceBefore: balanceBefore.toString(), 
                balanceAfter: balanceAfter.toString() 
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    transfer: async (senderUserId, receiverIdentifier, amount, note, referenceCode, pin) => {
        const senderWallet = await repo.getWalletForPinCheck(senderUserId);
        
        if (!senderWallet) {
            throw new Error('Sender_Wallet_Not_Found');
        }

        if (senderWallet.pin_locked_until) {
            const now = new Date();
            const lockedUntil = new Date(senderWallet.pin_locked_until);
            if (now < lockedUntil) {
                throw new Error('Wallet_Locked_PIN');
            } else {
                await repo.resetPinAttempts(senderWallet.id);
                senderWallet.pin_failed_attempts = 0; 
            }
        }

        if (!senderWallet.pin_hash) {
            throw new Error('Sender_Wallet_Not_Found');
        }
        const isPinMatch = await bcrypt.compare(pin, senderWallet.pin_hash);
        if (!isPinMatch) {
            const newAttempts = (senderWallet.pin_failed_attempts || 0) + 1;
            
            if (newAttempts >= 3) {
                const lockTime = new Date(Date.now() + 30 * 60000);
                await repo.updatePinAttempts(senderWallet.id, newAttempts, lockTime);
                throw new Error('Wallet_Locked_PIN');
            } else {
                await repo.updatePinAttempts(senderWallet.id, newAttempts, null);
                throw new Error(`Wrong_PIN_${3 - newAttempts}`);
            }
        }

        if (senderWallet.pin_failed_attempts > 0) {
            await repo.resetPinAttempts(senderWallet.id);
        }

        const receiverWallet = await repo.getWalletByIdentifier(receiverIdentifier);

        if (!receiverWallet) throw new Error('Receiver_Wallet_Not_Found');
        if (senderWallet.id === receiverWallet.id) throw new Error('Self_Transfer_Not_Allowed');

        if (receiverWallet.is_kyc_verified !== true) {
            throw new Error('Receiver_Not_KYC');
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const sortedWallets = [senderWallet.id, receiverWallet.id].sort();
            
            let senderBalanceBefore, receiverBalanceBefore;
            for (let wId of sortedWallets) {
                const bal = await repo.lockAndGetBalance(client, wId);
                if (wId === senderWallet.id) senderBalanceBefore = bal;
                if (wId === receiverWallet.id) receiverBalanceBefore = bal;
            }

            if (senderBalanceBefore < amount) {
                throw new Error('Insufficient_Balance');
            }

            const senderBalanceAfter = await repo.subtractBalance(client, senderWallet.id, amount);
            const receiverBalanceAfter = await repo.addBalance(client, receiverWallet.id, amount);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'TRANSFER', senderWallet.id, note || 'Chuyển tiền qua Ví');

            await repo.createLedgerEntry(client, ledgerTxId, senderWallet.id, 'DEBIT', amount, senderBalanceBefore, senderBalanceAfter);
            await repo.createLedgerEntry(client, ledgerTxId, receiverWallet.id, 'CREDIT', amount, receiverBalanceBefore, receiverBalanceAfter);

            await repo.recordTransfer(client, senderWallet.id, receiverWallet.id, amount, note, ledgerTxId, referenceCode);

            await client.query('COMMIT');
            
            // Gửi thông báo real-time cho người gửi
            emitToUser(senderUserId, 'balance_update', {
                type: 'TRANSFER_SENT',
                amount: amount.toString(),
                newBalance: senderBalanceAfter.toString()
            });

            // Gửi thông báo real-time cho người nhận
            // Lưu ý: receiverWallet ở đây có thể chỉ chứa info cơ bản, ta cần userId của người nhận
            // Dựa vào code repo.getWalletByIdentifier, ta giả định nó trả về đủ info bao gồm user_id
            if (receiverWallet.user_id) {
                emitToUser(receiverWallet.user_id, 'balance_update', {
                    type: 'TRANSFER_RECEIVED',
                    amount: amount.toString(),
                    newBalance: receiverBalanceAfter.toString(),
                    senderName: senderWallet.full_name // Nếu có
                });
            }

            return { 
                amount: amount.toString(), 
                balanceAfter: senderBalanceAfter.toString() 
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    getTransactionHistory: async (userId, page = 1, limit = 20) => {
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const offset = (page - 1) * limit;
        const history = await repo.getTransactionHistory(wallet.id, limit, offset);

        return history.map(item => ({
            ...item,
            amount: item.amount ? item.amount.toString() : '0',
            balance_before: item.balance_before ? item.balance_before.toString() : '0',
            balance_after: item.balance_after ? item.balance_after.toString() : '0'
        }));
    }
};

module.exports = transactionService;