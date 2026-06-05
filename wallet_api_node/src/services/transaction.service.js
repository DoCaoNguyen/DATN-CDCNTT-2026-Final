const pool = require('../config/db');
const repo = require('../repositories/transaction.repository');

const transactionService = {
    depositMock: async (userId, amount) => { 
        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); 

            const balanceBefore = await repo.lockAndGetBalance(client, wallet.id);
            const balanceAfter = await repo.addBalance(client, wallet.id, amount);

            const ledgerTxId = await repo.createLedgerTransaction(client, 'DEPOSIT', wallet.id, 'Nạp tiền giả lập từ ngân hàng');

            await repo.createLedgerEntry(client, ledgerTxId, wallet.id, 'CREDIT', amount, balanceBefore, balanceAfter);

            await repo.recordDeposit(client, wallet.id, amount, ledgerTxId);

            await client.query('COMMIT'); 
            
            return { 
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

    transfer: async (senderUserId, receiverIdentifier, amount, note) => {
        const senderWallet = await repo.getWalletByUserId(senderUserId);
        const receiverWallet = await repo.getWalletByIdentifier(receiverIdentifier);

        if (!senderWallet) throw new Error('Sender_Wallet_Not_Found');
        if (!receiverWallet) throw new Error('Receiver_Wallet_Not_Found');
        if (senderWallet.id === receiverWallet.id) throw new Error('Self_Transfer_Not_Allowed');

        // --- ĐÃ SỬA: CHẶN CHUYỂN TIỀN NẾU NGƯỜI NHẬN CHƯA KYC ---
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

            await repo.recordTransfer(client, senderWallet.id, receiverWallet.id, amount, note, ledgerTxId);

            await client.query('COMMIT');
            
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
    }
};

module.exports = transactionService;