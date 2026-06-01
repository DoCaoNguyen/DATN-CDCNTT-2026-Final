const pool = require('../config/db');

const transactionRepository = {
    // Lấy thông tin Ví của một User
    getWalletByUserId: async (userId) => {
        const query = `SELECT id FROM wallets WHERE user_id = $1`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    // Kiểm tra ví nhận tiền (Dùng số điện thoại hoặc email)
    getWalletByIdentifier: async (identifier) => {
        const query = `
            SELECT w.id 
            FROM wallets w
            JOIN users u ON w.user_id = u.id
            WHERE u.phone = $1 OR u.email = $1
        `;
        const result = await pool.query(query, [identifier]);
        return result.rows[0];
    },

    // Cập nhật số dư an toàn với UPSERT (Nạp tiền)
    addBalance: async (client, walletId, amount) => {
        const query = `
            INSERT INTO wallet_balances (wallet_id, available_balance, locked_balance)
            VALUES ($1, $2, 0)
            ON CONFLICT (wallet_id) 
            DO UPDATE SET 
                available_balance = wallet_balances.available_balance + $2,
                updated_at = CURRENT_TIMESTAMP
            RETURNING available_balance;
        `;
        const result = await client.query(query, [walletId, amount]);
        return result.rows[0].available_balance;
    },

    // Lấy số dư hiện tại và KHÓA DÒNG (Dành cho Chuyển tiền)
    lockAndGetBalance: async (client, walletId) => {
        const query = `
            SELECT available_balance 
            FROM wallet_balances 
            WHERE wallet_id = $1 
            FOR UPDATE; -- Khóa dòng này lại cho đến khi COMMIT hoặc ROLLBACK
        `;
        const result = await client.query(query, [walletId]);
        // Nếu ví chưa từng có số dư, mặc định là 0
        return result.rows.length > 0 ? Number(result.rows[0].available_balance) : 0;
    },

    // Trừ số dư
    subtractBalance: async (client, walletId, amount) => {
        const query = `
            UPDATE wallet_balances 
            SET available_balance = available_balance - $1, updated_at = CURRENT_TIMESTAMP
            WHERE wallet_id = $2
            RETURNING available_balance;
        `;
        const result = await client.query(query, [amount, walletId]);
        return result.rows[0].available_balance;
    },

    // Ghi Sổ cái (Ledger)
    createLedgerTransaction: async (client, type, referenceId, description) => {
        const query = `
            INSERT INTO ledger_transactions (transaction_type, reference_id, status, description)
            VALUES ($1, $2, 'SUCCESS', $3) RETURNING id;
        `;
        const result = await client.query(query, [type, referenceId, description]);
        return result.rows[0].id;
    },

    createLedgerEntry: async (client, transactionId, walletId, type, amount, balanceBefore, balanceAfter) => {
        const query = `
            INSERT INTO ledger_entries (transaction_id, wallet_id, entry_type, amount, balance_before, balance_after)
            VALUES ($1, $2, $3, $4, $5, $6);
        `;
        await client.query(query, [transactionId, walletId, type, amount, balanceBefore, balanceAfter]);
    },

    // Ghi lịch sử Nạp / Chuyển chi tiết
    recordDeposit: async (client, walletId, amount, ledgerId) => {
        const query = `
            INSERT INTO deposit_transactions (wallet_id, amount, deposit_method, status, ledger_transaction_id)
            VALUES ($1, $2, 'MOCK_BANK', 'SUCCESS', $3);
        `;
        await client.query(query, [walletId, amount, ledgerId]);
    },

    recordTransfer: async (client, senderId, receiverId, amount, note, ledgerId) => {
        const query = `
            INSERT INTO wallet_transfers (sender_wallet_id, receiver_wallet_id, amount, note, transaction_id, status)
            VALUES ($1, $2, $3, $4, $5, 'SUCCESS');
        `;
        await client.query(query, [senderId, receiverId, amount, note, ledgerId]);
    }
};

module.exports = transactionRepository;