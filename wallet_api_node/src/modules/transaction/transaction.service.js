const bcrypt = require('bcrypt');
const { v7: uuidv7 } = require('uuid');
const pool = require('../../config/db');
const repo = require('./transaction.repository');
const { emitToUser } = require('../../utils/socket');
const kycService = require('../kyc/kyc.service');
const notificationService = require('../notification/notification.service');
const aiService = require('../ai/ai.service');

const transactionService = {
    deposit: async (userId, amount, pin, faceImagePath, externalReference) => { 
        const wallet = await repo.getWalletForPinCheck(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const dailyTotal = await repo.getDailyTotal(wallet.id, 'DEPOSIT');
        if (dailyTotal + amount > 50000000n) {
            throw new Error('Daily_Limit_Exceeded');
        }

        // Verify based on amount (30,000,000 VND)
        if (amount < 30000000n) {
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
            const matchResult = await kycService.verifyFaceMatchFptAi(kycRecord.face_image, faceImagePath);
            if (!matchResult.faceFound || !matchResult.isMatch) {
                throw new Error('Face_Verification_Failed');
            }
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); 

            // SANDBOX SIMULATION: Nạp tiền thất bại nếu số tiền có tận cùng là 999 (ví dụ: 10,999)
            if (amount % 1000n === 999n) {
                throw new Error('Bank_Insufficient_Balance');
            }

            const balanceBefore = await repo.lockAndGetBalance(client, wallet.id);
            const balanceAfter = await repo.addBalance(client, wallet.id, amount);

            const depositId = uuidv7();
            const hex = depositId.replace(/-/g, '').substring(0, 10);
            const extRef = (externalReference && /^\d{12}$/.test(externalReference)) ? externalReference : BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'DEPOSIT', depositId, 'DEPOSIT', 'Nạp tiền từ ngân hàng liên kết', amount);
            
            await repo.createLedgerEntry(client, ledgerTxId, wallet.id, 'CREDIT', amount, balanceBefore, balanceAfter);

            await repo.recordDeposit(client, depositId, 'DEP-' + extRef, userId, wallet.id, amount, ledgerTxId, 'LINKED_BANK', extRef);

            await client.query('COMMIT'); 
            
            emitToUser(userId, 'balance_update', {
                type: 'DEPOSIT',
                amount: amount.toString(),
                balance: balanceAfter.toString(),
                newBalance: balanceAfter.toString()
            });

            // Gửi Push Notification biến động số dư
            notificationService.sendBalanceChangeNotification(userId, amount, 'DEPOSIT', ledgerTxId).catch(err => {
                console.error('Lỗi gửi push notification nạp tiền:', err);
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

        const monthlyTotal = await repo.getMonthlyDebitTotal(wallet.id);
        if (monthlyTotal + amount > 100000000n) {
            throw new Error('Monthly_Limit_Exceeded');
        }

        const dailyTotal = await repo.getDailyTotal(wallet.id, 'WITHDRAW');
        if (dailyTotal + amount > 50000000n) {
            throw new Error('Daily_Limit_Exceeded');
        }

        // Verify based on amount (30,000,000 VND)
        if (amount < 30000000n) {
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
            const matchResult = await kycService.verifyFaceMatchFptAi(kycRecord.face_image, faceImagePath);
            if (!matchResult.faceFound || !matchResult.isMatch) {
                throw new Error('Face_Verification_Failed');
            }
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); 

            // SANDBOX SIMULATION: Rút tiền thất bại do ngân hàng bảo trì nếu số tiền tận cùng là 999
            if (amount % 1000n === 999n) {
                throw new Error('Bank_Maintenance');
            }

            const balanceBefore = await repo.lockAndGetBalance(client, wallet.id);
            if (balanceBefore < amount) {
                throw new Error('Insufficient_Balance');
            }
            const balanceAfter = await repo.subtractBalance(client, wallet.id, amount);

            const withdrawId = uuidv7();
            const hex = withdrawId.replace(/-/g, '').substring(0, 10);
            const extRef = (externalReference && /^\d{12}$/.test(externalReference)) ? externalReference : BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'WITHDRAW', withdrawId, 'WITHDRAWAL', 'Rút tiền về ngân hàng liên kết', amount);

            await repo.createLedgerEntry(client, ledgerTxId, wallet.id, 'DEBIT', amount, balanceBefore, balanceAfter);

            await repo.recordWithdrawal(client, withdrawId, 'WDR-' + extRef, userId, wallet.id, amount, ledgerTxId, linkedBankId, extRef);

            await client.query('COMMIT'); 
            
            emitToUser(userId, 'balance_update', {
                type: 'WITHDRAW',
                amount: amount.toString(),
                balance: balanceAfter.toString(),
                newBalance: balanceAfter.toString()
            });

            // Gửi Push Notification biến động số dư
            notificationService.sendBalanceChangeNotification(userId, amount, 'WITHDRAWAL', ledgerTxId).catch(err => {
                console.error('Lỗi gửi push notification rút tiền:', err);
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

    bankTransfer: async (userId, amount, pin, faceImagePath, bankCode, bankName, accountNumber, externalReference) => {
        const wallet = await repo.getWalletForPinCheck(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const monthlyTotal = await repo.getMonthlyDebitTotal(wallet.id);
        if (monthlyTotal + amount > 100000000n) {
            throw new Error('Monthly_Limit_Exceeded');
        }

        // Verify based on amount (30,000,000 VND)
        if (amount < 30000000n) {
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
            const matchResult = await kycService.verifyFaceMatchFptAi(kycRecord.face_image, faceImagePath);
            if (!matchResult.faceFound || !matchResult.isMatch) {
                throw new Error('Face_Verification_Failed');
            }
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); 

            // SANDBOX SIMULATION: Chuyển tiền tới ngân hàng thất bại nếu số tiền có tận cùng là 999
            if (amount % 1000n === 999n) {
                throw new Error('Bank_Maintenance');
            }

            const balanceBefore = await repo.lockAndGetBalance(client, wallet.id);
            if (balanceBefore < amount) {
                throw new Error('Insufficient_Balance');
            }
            const balanceAfter = await repo.subtractBalance(client, wallet.id, amount);

            const transferId = uuidv7();
            const hex = transferId.replace(/-/g, '').substring(0, 10);
            const extRef = (externalReference && /^\d{12}$/.test(externalReference)) ? externalReference : BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'BANK_TRANSFER', transferId, 'BANK_TRANSFER', `Chuyển tiền đến tài khoản ${accountNumber} - ${bankName}`, amount);
            
            await repo.createLedgerEntry(client, ledgerTxId, wallet.id, 'DEBIT', amount, balanceBefore, balanceAfter);

            await repo.recordBankTransfer(client, transferId, 'BNK-' + extRef, userId, wallet.id, amount, ledgerTxId, bankCode, accountNumber, extRef);

            await client.query('COMMIT'); 
            
            emitToUser(userId, 'balance_update', {
                type: 'WITHDRAW',
                amount: amount.toString(),
                balance: balanceAfter.toString(),
                newBalance: balanceAfter.toString()
            });

            // Gửi Push Notification biến động số dư
            notificationService.sendBalanceChangeNotification(userId, amount, 'WITHDRAWAL', ledgerTxId).catch(err => {
                console.error('Lỗi gửi push notification chuyển tiền ngân hàng:', err);
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

        const monthlyTotal = await repo.getMonthlyDebitTotal(senderWallet.id);
        if (monthlyTotal + amount > 100000000n) {
            throw new Error('Monthly_Limit_Exceeded');
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

            const tId = uuidv7();
            const hex = tId.replace(/-/g, '').substring(0, 10);
            const finalRef = BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'TRANSFER', tId, 'TRANSFER', note || 'Chuyển tiền qua Ví', amount);

            await repo.createLedgerEntry(client, ledgerTxId, senderWallet.id, 'DEBIT', amount, senderBalanceBefore, senderBalanceAfter);
            await repo.createLedgerEntry(client, ledgerTxId, receiverWallet.id, 'CREDIT', amount, receiverBalanceBefore, receiverBalanceAfter);

            const transferId = await repo.recordTransfer(client, tId, 'TRF-' + finalRef, senderUserId, senderWallet.id, receiverWallet.user_id, receiverWallet.id, amount, note, finalRef);

            // Auto check and mark split bill as paid if matched
            if (senderUserId && receiverWallet.user_id) {
                const fundingResult = await client.query(`
                    SELECT gfm.id, gf.id as funding_id 
                    FROM group_funding_members gfm
                    JOIN group_fundings gf ON gfm.group_funding_id = gf.id
                    WHERE gfm.user_id = $1 
                      AND gf.creator_user_id = $2 
                      AND gf.type = 'SPLIT_BILL'
                      AND gfm.status != 'PAID'
                      AND gfm.amount = $3
                    LIMIT 1
                `, [senderUserId, receiverWallet.user_id, amount]);

                if (fundingResult.rows.length > 0) {
                    const memberId = fundingResult.rows[0].id;
                    const fundingId = fundingResult.rows[0].funding_id;
                    
                    await client.query(`
                        UPDATE group_funding_members 
                        SET status = 'PAID', paid_at = CURRENT_TIMESTAMP 
                        WHERE id = $1
                    `, [memberId]);

                    const pendingResult = await client.query(`
                        SELECT id FROM group_funding_members 
                        WHERE group_funding_id = $1 AND status != 'PAID'
                    `, [fundingId]);
                    
                    if (pendingResult.rows.length === 0) {
                        await client.query(`
                            UPDATE group_fundings SET status = 'COMPLETED' WHERE id = $1
                        `, [fundingId]);
                    }
                }
            }

            await client.query('COMMIT');

            // Trigger AI Categorization in background
            aiService.categorizeTransaction(ledgerTxId, note);
            
            // Gửi thông báo real-time cho người gửi
            emitToUser(senderUserId, 'balance_update', {
                type: 'TRANSFER_SENT',
                amount: amount.toString(),
                balance: senderBalanceAfter.toString(),
                newBalance: senderBalanceAfter.toString()
            });

            // Gửi thông báo real-time cho người nhận
            if (receiverWallet.user_id) {
                emitToUser(receiverWallet.user_id, 'balance_update', {
                    type: 'TRANSFER_RECEIVED',
                    amount: amount.toString(),
                    balance: receiverBalanceAfter.toString(),
                    newBalance: receiverBalanceAfter.toString(),
                    senderName: senderWallet.full_name // Nếu có
                });
            }

            // Gửi Push Notification cho người gửi (Biến động giảm)
            notificationService.sendBalanceChangeNotification(
                senderUserId, 
                amount, 
                'TRANSFER_SEND', 
                ledgerTxId, 
                receiverWallet.full_name || receiverIdentifier
            ).catch(err => {
                console.error('Lỗi gửi push notification gửi tiền:', err);
            });

            // Gửi Push Notification cho người nhận (Biến động tăng)
            if (receiverWallet.user_id) {
                notificationService.sendBalanceChangeNotification(
                    receiverWallet.user_id, 
                    amount, 
                    'TRANSFER_RECEIVE', 
                    ledgerTxId, 
                    senderWallet.full_name || senderWallet.phone
                ).catch(err => {
                    console.error('Lỗi gửi push notification nhận tiền:', err);
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

    getTransactionHistory: async (userId, page = 1, limit = 20, filters = {}) => {
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const offset = (page - 1) * limit;
        const history = await repo.getTransactionHistory(wallet.id, limit, offset, filters);

        return history.map(item => {
            let ref = item.external_reference;
            if (item.transaction_id) {
                const hex = item.transaction_id.replace(/-/g, '').substring(0, 10);
                ref = BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);
            }
            return {
                ...item,
                external_reference: ref,
                amount: item.amount ? item.amount.toString() : '0',
                balance_before: item.balance_before ? item.balance_before.toString() : '0',
                balance_after: item.balance_after ? item.balance_after.toString() : '0'
            };
        });
    },

    updateTransactionCategory: async (userId, transactionId, categoryName, isExpenseCounted) => {
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }

        const isOwner = await repo.checkTransactionOwnership(transactionId, wallet.id);
        if (!isOwner) {
            throw new Error('Forbidden_Error');
        }

        const result = await repo.updateTransactionCategory(transactionId, categoryName, isExpenseCounted);
        if (!result) {
            throw new Error('Transaction_Not_Found');
        }
        return result;
    },

    getMonthlyStats: async (userId) => {
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');
        
        const stats = await repo.getMonthlyStats(wallet.id);
        return {
            totalSpendThisMonth: stats.total_spend_this_month ? stats.total_spend_this_month.toString() : '0',
            totalReceiveThisMonth: stats.total_receive_this_month ? stats.total_receive_this_month.toString() : '0',
            totalSpendLastMonth: stats.total_spend_last_month ? stats.total_spend_last_month.toString() : '0',
        };
    },

    getTransactionsByMonth: async (userId, month, year) => {
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const transactions = await repo.getTransactionsByMonth(wallet.id, month, year);
        return transactions.map(item => {
            let ref = item.external_reference;
            if (item.transaction_id) {
                const hex = item.transaction_id.replace(/-/g, '').substring(0, 10);
                ref = BigInt('0x' + hex).toString().padStart(12, '0').slice(0, 12);
            }
            return {
                ...item,
                external_reference: ref,
                amount: item.amount ? item.amount.toString() : '0',
                balance_before: item.balance_before ? item.balance_before.toString() : '0',
                balance_after: item.balance_after ? item.balance_after.toString() : '0'
            };
        });
    },

    getChatList: async (userId) => {
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const chats = await repo.getChatList(wallet.id);
        return chats.map(item => ({
            ...item,
            latest_transaction_date: item.latest_transaction_date ? new Date(item.latest_transaction_date).toISOString() : null
        }));
    },

    getChatHistory: async (userId, counterpartyPhone, page = 1, limit = 20) => {
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const offset = (page - 1) * limit;
        const history = await repo.getChatHistory(wallet.id, counterpartyPhone, limit, offset);
        return history.map(item => ({
            ...item,
            amount: item.amount ? item.amount.toString() : '0',
            created_at: item.created_at ? new Date(item.created_at).toISOString() : null
        }));
    }
};

module.exports = transactionService;