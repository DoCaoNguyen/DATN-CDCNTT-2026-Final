const pool = require('../config/db');

const transactionRepository = {
    getWalletByUserId: async (userId) => {
        const query = `SELECT id FROM wallets WHERE user_id = $1`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    // --- ĐÃ SỬA TẠI ĐÂY ---
    getWalletByIdentifier: async (identifier) => {
        const query = `
            SELECT w.id, u.is_kyc_verified 
            FROM wallets w
            JOIN users u ON w.user_id = u.id
            WHERE u.phone = $1 OR u.email = $1 OR w.wallet_code = $1
        `;
        const result = await pool.query(query, [identifier]);
        return result.rows[0];
    },

    lockAndGetBalance: async (client, walletId) => {
        await client.query(`
            INSERT INTO wallet_balances (wallet_id, available_balance, locked_balance)
            VALUES ($1, 0, 0)
            ON CONFLICT (wallet_id) DO NOTHING;
        `, [walletId]);

        const query = `
            SELECT available_balance 
            FROM wallet_balances 
            WHERE wallet_id = $1 
            FOR UPDATE;
        `;
        const result = await client.query(query, [walletId]);
        return BigInt(result.rows[0].available_balance); 
    },

    addBalance: async (client, walletId, amount) => {
        const query = `
            UPDATE wallet_balances 
            SET available_balance = available_balance + $1, updated_at = CURRENT_TIMESTAMP
            WHERE wallet_id = $2
            RETURNING available_balance;
        `;
        const result = await client.query(query, [amount.toString(), walletId]);
        return BigInt(result.rows[0].available_balance);
    },

    subtractBalance: async (client, walletId, amount) => {
        const query = `
            UPDATE wallet_balances 
            SET available_balance = available_balance - $1, updated_at = CURRENT_TIMESTAMP
            WHERE wallet_id = $2
            RETURNING available_balance;
        `;
        const result = await client.query(query, [amount.toString(), walletId]);
        return BigInt(result.rows[0].available_balance);
    },

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
        await client.query(query, [transactionId, walletId, type, amount.toString(), balanceBefore.toString(), balanceAfter.toString()]);
    },

    recordDeposit: async (client, walletId, amount, ledgerId) => {
        const query = `
            INSERT INTO deposit_transactions (wallet_id, amount, deposit_method, status, ledger_transaction_id)
            VALUES ($1, $2, 'MOCK_BANK', 'SUCCESS', $3);
        `;
        await client.query(query, [walletId, amount.toString(), ledgerId]);
    },

    recordTransfer: async (client, senderId, receiverId, amount, note, ledgerId) => {
        const query = `
            INSERT INTO wallet_transfers (sender_wallet_id, receiver_wallet_id, amount, note, transaction_id, status)
            VALUES ($1, $2, $3, $4, $5, 'SUCCESS');
        `;
        await client.query(query, [senderId, receiverId, amount.toString(), note, ledgerId]);
    }
};

module.exports = transactionRepository;