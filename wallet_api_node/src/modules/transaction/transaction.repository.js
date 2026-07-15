const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const transactionRepository = {
    getWalletByUserId: async (userId) => {
        const query = `
            SELECT w.id, w.status, w.user_id, u.is_kyc_verified, u.full_name, u.phone
            FROM wallets w
            JOIN users u ON w.user_id = u.id
            WHERE w.user_id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getWalletByIdentifier: async (identifier) => {
        const query = `
            SELECT w.id, w.status, w.user_id, u.is_kyc_verified, u.full_name, u.phone
            FROM wallets w
            JOIN users u ON w.user_id = u.id
            WHERE u.phone = $1 OR u.email = $1
        `;
        const result = await pool.query(query, [identifier]);
        return result.rows[0];
    },

    lockAndGetBalance: async (client, walletId) => {
        await client.query(`
            INSERT INTO wallet_balances (wallet_id, currency, available_balance, locked_balance)
            VALUES ($1, 'VND', 0, 0)
            ON CONFLICT (wallet_id, currency) DO NOTHING;
        `, [walletId]);

        const query = `
            SELECT available_balance 
            FROM wallet_balances 
            WHERE wallet_id = $1 AND currency = 'VND'
            FOR UPDATE;
        `;
        const result = await client.query(query, [walletId]);
        return BigInt(result.rows[0].available_balance); 
    },

    addBalance: async (client, walletId, amount) => {
        const query = `
            UPDATE wallet_balances 
            SET available_balance = available_balance + $1, updated_at = CURRENT_TIMESTAMP
            WHERE wallet_id = $2 AND currency = 'VND'
            RETURNING available_balance;
        `;
        const result = await client.query(query, [amount.toString(), walletId]);
        return BigInt(result.rows[0].available_balance);
    },

    getWalletIdByMerchantId: async (merchantId) => {
        const query = `
            SELECT w.id 
            FROM wallets w 
            JOIN merchants m ON m.user_id = w.user_id 
            WHERE m.id = $1 
            LIMIT 1;
        `;
        const result = await pool.query(query, [merchantId]);
        return result.rows.length > 0 ? result.rows[0].id : null;
    },

    subtractBalance: async (client, walletId, amount) => {
        const query = `
            UPDATE wallet_balances 
            SET available_balance = available_balance - $1, updated_at = CURRENT_TIMESTAMP
            WHERE wallet_id = $2 AND currency = 'VND'
            RETURNING available_balance;
        `;
        const result = await client.query(query, [amount.toString(), walletId]);
        return BigInt(result.rows[0].available_balance);
    },

    createLedgerTransaction: async (client, type, sourceId, sourceType, description, amount, currency = 'VND', metadata = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO ledger_transactions (id, transaction_type, source_id, source_type, status, description, amount, currency, completed_at, metadata)
            VALUES ($1, $2, $3, $4, 'SUCCESS', $5, $6, $7, CURRENT_TIMESTAMP, $8) RETURNING id;
        `;
        const result = await client.query(query, [newId, type, sourceId, sourceType, description, amount.toString(), currency, metadata]);
        return result.rows[0].id;
    },

    createFailedLedgerTransaction: async (type, description, amount, createdBy = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO ledger_transactions (id, transaction_type, status, description, amount, created_by, completed_at)
            VALUES ($1, $2, 'FAILED', $3, $4, $5, CURRENT_TIMESTAMP) RETURNING id;
        `;
        const result = await pool.query(query, [newId, type, description, amount.toString(), createdBy]);
        return result.rows[0].id;
    },

    createLedgerEntry: async (client, ledgerTransactionId, accountId, type, amount, balanceBefore, balanceAfter, accountType = 'PERSONAL') => {
        const newId = uuidv7();
        const mappedAccountType = accountType === 'PERSONAL' ? 'USER_WALLET' : accountType;
        
        const query = `
            INSERT INTO ledger_entries (id, ledger_transaction_id, wallet_id, entry_type, amount, balance_before, balance_after, account_type)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
        `;
        
        const params = [newId, ledgerTransactionId, accountId, type, amount.toString(), balanceBefore.toString(), balanceAfter.toString(), mappedAccountType];
        await client.query(query, params);
        return newId;
    },

    createSystemLedgerEntry: async (client, ledgerTransactionId, systemAccountCode, type, amount, _merchantId = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO ledger_entries (id, ledger_transaction_id, system_account_code, entry_type, amount, balance_before, balance_after, account_type)
            VALUES ($1, $2, $3, $4, $5, 0, 0, 'SYSTEM_ACCOUNT');
        `;
        await client.query(query, [newId, ledgerTransactionId, systemAccountCode, type, amount.toString()]);
        return newId;
    },


    recordDeposit: async (client, id, userId, walletId, amount, linkedBankId, externalReference = null, idempotencyKey) => {
        const metadata = JSON.stringify({
            linked_bank_id: linkedBankId,
            external_reference: externalReference
        });
        const query = `
            INSERT INTO transactions (id, transaction_no, transaction_type, user_id, wallet_id, amount, status, metadata, idempotency_key)
            VALUES ($1, nextval('transaction_ref_seq')::text, 'DEPOSIT', $2, $3, $4, 'COMPLETED', $5::jsonb, $6)
            RETURNING transaction_no;
        `;
        const result = await client.query(query, [id, userId, walletId, amount.toString(), metadata, idempotencyKey]);
        return result.rows[0].transaction_no;
    },


    recordWithdrawal: async (client, id, userId, walletId, amount, linkedBankId, externalReference = null, idempotencyKey) => {
        const metadata = JSON.stringify({
            linked_bank_id: linkedBankId,
            external_reference: externalReference
        });

        const query = `
            INSERT INTO transactions (id, transaction_no, transaction_type, user_id, wallet_id, amount, status, metadata, idempotency_key)
            VALUES ($1, nextval('transaction_ref_seq')::text, 'WITHDRAWAL', $2, $3, $4, 'COMPLETED', $5::jsonb, $6)
            RETURNING transaction_no;
        `;
        
        const result = await client.query(query, [id, userId, walletId, amount.toString(), metadata, idempotencyKey]);
        return result.rows[0].transaction_no;
    },

    recordBankTransfer: async (client, id, userId, walletId, amount, bankCode, accountNumber, externalReference = null, idempotencyKey) => {
        const metadata = JSON.stringify({
            bank_code: bankCode,
            account_number: accountNumber,
            external_reference: externalReference
        });

        const query = `
            INSERT INTO transactions (id, transaction_no, transaction_type, user_id, wallet_id, amount, status, metadata, idempotency_key)
            VALUES ($1, nextval('transaction_ref_seq')::text, 'WITHDRAWAL', $2, $3, $4, 'COMPLETED', $5::jsonb, $6)
            RETURNING transaction_no;
        `;
        
        const result = await client.query(query, [id, userId, walletId, amount.toString(), metadata, idempotencyKey]);
        return result.rows[0].transaction_no;
    },

    recordTransfer: async (client, id, senderUserId, senderWalletId, receiverUserId, receiverWalletId, amount, description, idempotencyKey, receiverName = null, receiverPhone = null) => {
        // Lưu metadata đầy đủ: receiver info để query lịch sử dùng được không cần JOIN bảng cũ
        const metadata = JSON.stringify({
            receiver_user_id: receiverUserId,
            receiver_wallet_id: receiverWalletId,
            receiver_name: receiverName,
            receiver_phone: receiverPhone
        });

        const query = `
            INSERT INTO transactions (id, transaction_no, transaction_type, user_id, wallet_id, amount, status, description, metadata, idempotency_key)
            VALUES ($1, nextval('transaction_ref_seq')::text, 'TRANSFER', $2, $3, $4, 'COMPLETED', $5, $6::jsonb, $7)
            RETURNING transaction_no;
        `;

        const result = await client.query(query, [id, senderUserId, senderWalletId, amount.toString(), description, metadata, idempotencyKey]);
        return result.rows[0].transaction_no;
    },


    getUserKycFaceImage: async (userId) => {
        const query = `SELECT face_image FROM user_kyc WHERE user_id = $1 AND kyc_status = 'APPROVED'`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getWalletForPinCheck: async (userId) => {
        const query = `
            SELECT 
                w.id, 
                w.status,
                u.phone AS wallet_code, 
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

    getMonthlyDebitTotal: async (walletId) => {
        const query = `
            SELECT COALESCE(SUM(le.amount), 0) as total
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            WHERE le.wallet_id = $1 
              AND le.entry_type = 'DEBIT' 
              AND lt.transaction_type IN ('TRANSFER', 'BANK_TRANSFER')
              AND EXTRACT(MONTH FROM le.created_at) = EXTRACT(MONTH FROM CURRENT_DATE)
              AND EXTRACT(YEAR FROM le.created_at) = EXTRACT(YEAR FROM CURRENT_DATE)
        `;
        const result = await pool.query(query, [walletId]);
        return BigInt(result.rows[0].total);
    },

    getDailyTotal: async (walletId, type) => {
        const entryType = type === 'DEPOSIT' ? 'CREDIT' : 'DEBIT';
        const query = `
            SELECT COALESCE(SUM(le.amount), 0) as total
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            WHERE le.wallet_id = $1 
              AND le.entry_type = $2
              AND lt.transaction_type = $3
              AND le.created_at >= CURRENT_DATE 
              AND le.created_at < CURRENT_DATE + INTERVAL '1 day'
        `;
        const result = await pool.query(query, [walletId, entryType, type]);
        return BigInt(result.rows[0].total);
    },

    getTransactionHistory: async (walletId, limit = 20, offset = 0, filters = {}) => {
        let paramIndex = 1;
        const params = [walletId];
        let whereExtra = '';

        // Filter theo loại giao dịch (DEPOSIT, TRANSFER, WITHDRAW, PAYMENT)
        if (filters.type) {
            paramIndex++;
            whereExtra += ` AND lt.transaction_type = $${paramIndex}`;
            params.push(filters.type.toUpperCase());
        }

        
        if (filters.startDate) {
            paramIndex++;
            whereExtra += ` AND le.created_at >= $${paramIndex}`;
            params.push(new Date(filters.startDate));
        }

        
        if (filters.endDate) {
            paramIndex++;
            whereExtra += ` AND le.created_at <= $${paramIndex}`;
            
            const endDate = new Date(filters.endDate);
            endDate.setHours(23, 59, 59, 999);
            params.push(endDate);
        }

        paramIndex++;
        const limitParam = paramIndex;
        params.push(limit);

        paramIndex++;
        const offsetParam = paramIndex;
        params.push(offset);

        const query = `
            SELECT 
                le.id AS entry_id,
                le.ledger_transaction_id AS transaction_id,
                tx.transaction_no,
                lt.transaction_type,
                COALESCE(lt.category_name, lt.transaction_type) AS category_name,
                COALESCE(lt.is_expense_counted, true) AS is_expense_counted,
                le.entry_type,
                le.amount,
                le.balance_before,
                le.balance_after,
                COALESCE(tx.description, lt.description) AS description,
                lt.status,
                lt.currency,
                lt.metadata,
                tx.metadata AS tx_metadata,
                le.created_at,
                -- Lấy thông tin người gửi qua tx.wallet_id (vì với TRANSFER thì tx.wallet_id là người gửi)
                CASE WHEN lt.transaction_type = 'TRANSFER' THEN u_sender.full_name ELSE NULL END AS sender_name,
                CASE WHEN lt.transaction_type = 'TRANSFER' THEN u_sender.phone ELSE NULL END AS sender_phone,
        
                CASE WHEN lt.transaction_type IN ('TRANSFER', 'PAYMENT') THEN
                    COALESCE(
                        (tx.metadata->>'receiver_name'),
                        (SELECT m.merchant_name FROM payment_orders po JOIN merchants m ON po.merchant_id = m.id WHERE po.id = (tx.metadata->>'payment_order_id')::uuid)
                    )
                ELSE NULL END AS receiver_name,
                (tx.metadata->>'receiver_phone') AS receiver_phone,
                -- external_reference lấy từ metadata
                COALESCE(tx.metadata->>'external_reference', tx.metadata->>'payment_no') AS external_reference
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            -- Join vào bảng transactions thống nhất qua source_id
            LEFT JOIN transactions tx ON lt.source_id = tx.id
            -- Lấy thông tin sender cho TRANSFER
            LEFT JOIN wallets w_sender ON tx.wallet_id = w_sender.id
            LEFT JOIN users u_sender ON w_sender.user_id = u_sender.id
            WHERE le.wallet_id = $1 AND (lt.currency IS NULL OR lt.currency != 'POINT')${whereExtra}
            ORDER BY le.created_at DESC
            LIMIT $${limitParam} OFFSET $${offsetParam};
        `;
        const result = await pool.query(query, params);
        return result.rows;
    },

    getTransactionHistoryForAI: async (walletId) => {
        const query = `
            SELECT 
                le.id AS entry_id,
                le.ledger_transaction_id AS transaction_id,
                lt.transaction_type,
                COALESCE(lt.category_name, lt.transaction_type) AS category_name,
                COALESCE(lt.is_expense_counted, true) AS is_expense_counted,
                le.entry_type,
                le.amount,
                le.balance_before,
                le.balance_after,
                COALESCE(tx.description, lt.description) AS description,
                lt.status,
                lt.currency,
                le.created_at,
                tx.transaction_no,
                tx.metadata AS tx_metadata,
                COALESCE(tx.metadata->>'external_reference', tx.metadata->>'payment_no') AS external_reference
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            LEFT JOIN transactions tx ON lt.source_id = tx.id
            WHERE le.wallet_id = $1 AND (lt.currency IS NULL OR lt.currency != 'POINT') AND le.created_at >= CURRENT_DATE - INTERVAL '3 months'
            ORDER BY le.created_at DESC
            LIMIT 50;
        `;
        const result = await pool.query(query, [walletId]);
        return result.rows;
    },

    getMonthlySummaryForAI: async (walletId) => {
        const query = `
            SELECT 
                TO_CHAR(le.created_at, 'YYYY-MM') as month,
                le.entry_type,
                COALESCE(lt.category_name, lt.transaction_type) AS category_name,
                SUM(le.amount) as total_amount
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            WHERE le.wallet_id = $1 
              AND (lt.currency IS NULL OR lt.currency != 'POINT')
              AND le.created_at >= CURRENT_DATE - INTERVAL '6 months'
            GROUP BY month, le.entry_type, category_name
            ORDER BY month DESC, le.entry_type, category_name;
        `;
        const result = await pool.query(query, [walletId]);
        return result.rows;
    },

    checkTransactionOwnership: async (transactionId, walletId) => {
        const query = `
            SELECT 1 FROM ledger_entries 
            WHERE ledger_transaction_id = $1 AND wallet_id = $2
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
    },

    getMonthlyStats: async (walletId) => {
        const query = `
            SELECT 
                COALESCE(SUM(CASE WHEN le.entry_type = 'DEBIT' AND EXTRACT(MONTH FROM le.created_at) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(YEAR FROM le.created_at) = EXTRACT(YEAR FROM CURRENT_DATE) THEN le.amount ELSE 0 END), 0) AS total_spend_this_month,
                COALESCE(SUM(CASE WHEN le.entry_type = 'CREDIT' AND EXTRACT(MONTH FROM le.created_at) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(YEAR FROM le.created_at) = EXTRACT(YEAR FROM CURRENT_DATE) THEN le.amount ELSE 0 END), 0) AS total_receive_this_month,
                COALESCE(SUM(CASE WHEN le.entry_type = 'DEBIT' AND EXTRACT(MONTH FROM le.created_at) = EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 month') AND EXTRACT(YEAR FROM le.created_at) = EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 month') THEN le.amount ELSE 0 END), 0) AS total_spend_last_month
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            WHERE le.wallet_id = $1 AND (lt.currency IS NULL OR lt.currency != 'POINT');
        `;
        const result = await pool.query(query, [walletId]);
        return result.rows[0];
    },

    getTransactionsByMonth: async (walletId, month, year) => {
        const query = `
            SELECT 
                le.id AS entry_id,
                le.ledger_transaction_id AS transaction_id,
                tx.transaction_no,
                lt.transaction_type,
                lt.transaction_type AS category_name,
                true AS is_expense_counted,
                le.entry_type,
                le.amount,
                le.balance_before,
                le.balance_after,
                COALESCE(tx.description, lt.description) AS description,
                lt.status,
                le.created_at,
                -- Receiver info từ metadata
                (tx.metadata->>'receiver_name') AS receiver_name,
                (tx.metadata->>'receiver_phone') AS receiver_phone,
                COALESCE(tx.metadata->>'external_reference', tx.metadata->>'payment_no') AS external_reference,
                tx.metadata AS tx_metadata
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            LEFT JOIN transactions tx ON lt.source_id = tx.id
            WHERE le.wallet_id = $1 
              AND (lt.currency IS NULL OR lt.currency != 'POINT')
              AND EXTRACT(MONTH FROM le.created_at) = $2 
              AND EXTRACT(YEAR FROM le.created_at) = $3
            ORDER BY le.created_at DESC;
        `;
        const result = await pool.query(query, [walletId, month, year]);
        return result.rows;
    },

};

module.exports = transactionRepository;