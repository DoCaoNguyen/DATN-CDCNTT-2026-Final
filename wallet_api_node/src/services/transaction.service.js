const pool = require('../config/db');
const repo = require('../repositories/transaction.repository');

const transactionService = {
    depositMock: async (userId, amount) => {
        if (amount <= 0) throw new Error('Invalid_Amount');

        const wallet = await repo.getWalletByUserId(userId);
        if (!wallet) throw new Error('Wallet_Not_Found');

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); // Bắt đầu Transaction ACID

            // 1. Cổng giả lập: Cộng tiền trực tiếp vào số dư (UPSERT)
            // Trong thực tế, phải query lấy balance cũ để ghi Ledger cho chuẩn
            const balanceBefore = await repo.lockAndGetBalance(client, wallet.id);
            const balanceAfter = await repo.addBalance(client, wallet.id, amount);

            // 2. Tạo Transaction Sổ cái gốc
            const ledgerTxId = await repo.createLedgerTransaction(client, 'DEPOSIT', wallet.id, 'Nạp tiền giả lập từ ngân hàng');

            // 3. Ghi vào bút toán (Chỉ có CREDIT vì tiền vào ví)
            await repo.createLedgerEntry(client, ledgerTxId, wallet.id, 'CREDIT', amount, balanceBefore, balanceAfter);

            // 4. Ghi lịch sử Deposit
            await repo.recordDeposit(client, wallet.id, amount, ledgerTxId);

            await client.query('COMMIT'); // Hoàn tất an toàn
            return { balanceBefore, amount, balanceAfter };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    transfer: async (senderUserId, receiverIdentifier, amount, note) => {
        if (amount <= 0) throw new Error('Invalid_Amount');

        const senderWallet = await repo.getWalletByUserId(senderUserId);
        const receiverWallet = await repo.getWalletByIdentifier(receiverIdentifier);

        if (!senderWallet) throw new Error('Sender_Wallet_Not_Found');
        if (!receiverWallet) throw new Error('Receiver_Wallet_Not_Found');
        if (senderWallet.id === receiverWallet.id) throw new Error('Self_Transfer_Not_Allowed');

        const client = await pool.connect();
        try {
            await client.query('BEGIN'); // BẮT ĐẦU TRANSACTION CỰC KỲ NGHIÊM NGẶT

            // LƯU Ý KỸ THUẬT: Phải luôn khóa (lock) các dòng theo một thứ tự nhất định để tránh Deadlock.
            // Ở đây tôi sắp xếp theo UUID để quy định thứ tự khóa.
            const sortedWallets = [senderWallet.id, receiverWallet.id].sort();
            
            // 1. Khóa và lấy số dư của cả 2 ví
            let senderBalanceBefore, receiverBalanceBefore;
            for (let wId of sortedWallets) {
                const bal = await repo.lockAndGetBalance(client, wId);
                if (wId === senderWallet.id) senderBalanceBefore = bal;
                if (wId === receiverWallet.id) receiverBalanceBefore = bal;
            }

            // 2. Kiểm tra số dư người gửi
            if (senderBalanceBefore < amount) {
                throw new Error('Insufficient_Balance');
            }

            // 3. Trừ tiền người gửi & Cộng tiền người nhận
            const senderBalanceAfter = await repo.subtractBalance(client, senderWallet.id, amount);
            const receiverBalanceAfter = await repo.addBalance(client, receiverWallet.id, amount);

            // 4. Ghi Sổ cái gốc
            const ledgerTxId = await repo.createLedgerTransaction(client, 'TRANSFER', senderWallet.id, note || 'Chuyển tiền qua Ví');

            // 5. Ghi bút toán kép (Double-entry accounting)
            await repo.createLedgerEntry(client, ledgerTxId, senderWallet.id, 'DEBIT', amount, senderBalanceBefore, senderBalanceAfter);
            await repo.createLedgerEntry(client, ledgerTxId, receiverWallet.id, 'CREDIT', amount, receiverBalanceBefore, receiverBalanceAfter);

            // 6. Ghi lịch sử Chuyển tiền chi tiết
            await repo.recordTransfer(client, senderWallet.id, receiverWallet.id, amount, note, ledgerTxId);

            await client.query('COMMIT');
            return { amount, balanceAfter: senderBalanceAfter };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }
};

module.exports = transactionService;