const pool = require('../../config/db');

const transactionRepository = {
    getWalletByUserId: async (userId) => {
        const query = `SELECT id FROM wallets WHERE user_id = $1`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

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

    recordDeposit: async (client, walletId, amount, ledgerId, depositMethod = 'LINKED_BANK', externalReference = null) => {
        const query = `
            INSERT INTO deposit_transactions (wallet_id, amount, deposit_method, status, ledger_transaction_id, external_reference)
            VALUES ($1, $2, $3, 'SUCCESS', $4, $5);
        `;
        await client.query(query, [walletId, amount.toString(), depositMethod, ledgerId, externalReference]);
    },

    recordWithdrawal: async (client, walletId, amount, ledgerId, linkedBankId, externalReference = null) => {
        const query = `
            INSERT INTO withdrawal_transactions (wallet_id, amount, withdrawal_method, status, ledger_transaction_id, linked_bank_id, external_reference)
            VALUES ($1, $2, 'LINKED_BANK', 'SUCCESS', $3, $4, $5);
        `;
        await client.query(query, [walletId, amount.toString(), ledgerId, linkedBankId, externalReference]);
    },

    getUserKycFaceImage: async (userId) => {
        const query = `SELECT face_image FROM user_kyc WHERE user_id = $1 AND kyc_status = 'VERIFIED'`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    recordTransfer: async (client, senderId, receiverId, amount, note, ledgerId, referenceCode) => {
        const query = `
            INSERT INTO wallet_transfers (sender_wallet_id, receiver_wallet_id, amount, note, transaction_id, status, reference_code)
            VALUES ($1, $2, $3, $4, $5, 'SUCCESS', $6);
        `;
        await client.query(query, [senderId, receiverId, amount.toString(), note, ledgerId, referenceCode]);
    },

    getWalletForPinCheck: async (userId) => {
        const query = `
            SELECT 
                w.id, 
                COALESCE(w.wallet_code, u.phone) AS wallet_code, 
                w.pin_failed_attempts, 
                w.pin_locked_until,
                u.pin_hash,
                u.phone
            FROM wallets w
            JOIN users u ON w.user_id = u.id
            WHERE w.user_id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    updatePinAttempts: async (walletId, attempts, lockedUntil = null) => {
        const query = `
            UPDATE wallets 
            SET pin_failed_attempts = $1, pin_locked_until = $2 
            WHERE id = $3
        `;
        await pool.query(query, [attempts, lockedUntil, walletId]);
    },

    resetPinAttempts: async (walletId) => {
        const query = `
            UPDATE wallets 
            SET pin_failed_attempts = 0, pin_locked_until = NULL 
            WHERE id = $1
        `;
        await pool.query(query, [walletId]);
    },

    getTransactionHistory: async (walletId, limit = 20, offset = 0) => {
        const query = `
            SELECT 
                le.id AS entry_id,
                le.transaction_id,
                lt.transaction_type,
                le.entry_type,
                le.amount,
                le.balance_before,
                le.balance_after,
                lt.description,
                lt.status,
                le.created_at,
                wt.note AS transfer_note,
                u_sender.full_name AS sender_name,
                u_sender.phone AS sender_phone,
                u_receiver.full_name AS receiver_name,
                u_receiver.phone AS receiver_phone,
                COALESCE(dt.external_reference, wt_act.external_reference, wt.reference_code) AS external_reference
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.transaction_id = lt.id
            LEFT JOIN wallet_transfers wt ON lt.id = wt.transaction_id
            LEFT JOIN wallets w_sender ON wt.sender_wallet_id = w_sender.id
            LEFT JOIN users u_sender ON w_sender.user_id = u_sender.id
            LEFT JOIN wallets w_receiver ON wt.receiver_wallet_id = w_receiver.id
            LEFT JOIN users u_receiver ON w_receiver.user_id = u_receiver.id
            LEFT JOIN deposit_transactions dt ON lt.id = dt.ledger_transaction_id
            LEFT JOIN withdrawal_transactions wt_act ON lt.id = wt_act.ledger_transaction_id
            WHERE le.wallet_id = $1
            ORDER BY le.created_at DESC
            LIMIT $2 OFFSET $3;
        `;
        const result = await pool.query(query, [walletId, limit, offset]);
        return result.rows;
    }
};

module.exports = transactionRepository;