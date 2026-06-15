const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const transactionRepository = {
    getWalletByUserId: async (userId) => {
        const query = `SELECT id FROM wallets WHERE user_id = $1`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getWalletByIdentifier: async (identifier) => {
        const query = `
            SELECT w.id, w.user_id, u.is_kyc_verified, u.full_name
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
        const newId = uuidv7();
        const query = `
            INSERT INTO ledger_transactions (id, transaction_type, reference_id, status, description)
            VALUES ($1, $2, $3, 'SUCCESS', $4) RETURNING id;
        `;
        const result = await client.query(query, [newId, type, referenceId, description]);
        return result.rows[0].id;
    },

    createLedgerEntry: async (client, transactionId, walletId, type, amount, balanceBefore, balanceAfter) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO ledger_entries (id, transaction_id, wallet_id, entry_type, amount, balance_before, balance_after)
            VALUES ($1, $2, $3, $4, $5, $6, $7);
        `;
        await client.query(query, [newId, transactionId, walletId, type, amount.toString(), balanceBefore.toString(), balanceAfter.toString()]);
        return newId;
    },

    recordDeposit: async (client, walletId, amount, ledgerId, depositMethod = 'LINKED_BANK', externalReference = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO deposit_transactions (id, wallet_id, amount, deposit_method, status, ledger_transaction_id, external_reference)
            VALUES ($1, $2, $3, $4, 'SUCCESS', $5, $6);
        `;
        await client.query(query, [newId, walletId, amount.toString(), depositMethod, ledgerId, externalReference]);
        return newId;
    },

    recordWithdrawal: async (client, walletId, amount, ledgerId, linkedBankId, externalReference = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO withdrawal_transactions (id, wallet_id, amount, withdrawal_method, status, ledger_transaction_id, linked_bank_id, external_reference)
            VALUES ($1, $2, 'LINKED_BANK', 'SUCCESS', $3, $4, $5);
        `;
        await client.query(query, [newId, walletId, amount.toString(), ledgerId, linkedBankId, externalReference]);
        return newId;
    },

    recordBankTransfer: async (client, walletId, amount, ledgerId, bankCode, accountNumber, externalReference = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO withdrawal_transactions (id, wallet_id, amount, withdrawal_method, status, ledger_transaction_id, linked_bank_id, bank_code, account_number, external_reference)
            VALUES ($1, $2, 'BANK_TRANSFER', 'SUCCESS', $3, NULL, $4, $5, $6);
        `;
        await client.query(query, [newId, walletId, amount.toString(), ledgerId, bankCode, accountNumber, externalReference]);
        return newId;
    },

    getUserKycFaceImage: async (userId) => {
        const query = `SELECT face_image FROM user_kyc WHERE user_id = $1 AND kyc_status = 'VERIFIED'`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    recordTransfer: async (client, senderId, receiverId, amount, note, ledgerId, referenceCode) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO wallet_transfers (id, sender_wallet_id, receiver_wallet_id, amount, note, transaction_id, status, reference_code)
            VALUES ($1, $2, $3, $4, $5, $6, 'SUCCESS', $7);
        `;
        await client.query(query, [newId, senderId, receiverId, amount.toString(), note, ledgerId, referenceCode]);
        return newId;
    },

    getWalletForPinCheck: async (userId) => {
        const query = `
            SELECT 
                w.id, 
                COALESCE(w.wallet_code, u.phone) AS wallet_code, 
                w.pin_failed_attempts, 
                w.pin_locked_until,
                u.pin_hash,
                u.phone,
                u.full_name
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
                lt.category_name,
                lt.is_expense_counted,
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
    },

    checkTransactionOwnership: async (transactionId, walletId) => {
        const query = `
            SELECT 1 FROM ledger_entries 
            WHERE transaction_id = $1 AND wallet_id = $2
            LIMIT 1;
        `;
        const result = await pool.query(query, [transactionId, walletId]);
        return result.rows.length > 0;
    },

    updateTransactionCategory: async (transactionId, categoryName, isExpenseCounted) => {
        const query = `
            UPDATE ledger_transactions
            SET category_name = $1, is_expense_counted = $2
            WHERE id = $3
            RETURNING *;
        `;
        const result = await pool.query(query, [categoryName, isExpenseCounted, transactionId]);
        return result.rows[0];
    }
};

module.exports = transactionRepository;