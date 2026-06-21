const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const transactionRepository = {
    getWalletByUserId: async (userId) => {
        const query = `
            SELECT w.id, w.user_id, u.is_kyc_verified, u.full_name, u.phone
            FROM wallets w
            JOIN users u ON w.user_id = u.id
            WHERE w.user_id = $1
        `;
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
            VALUES ($1, $2, $3, 'LINKED_BANK', 'SUCCESS', $4, $5, $6);
        `;
        await client.query(query, [newId, walletId, amount.toString(), ledgerId, linkedBankId, externalReference]);
        return newId;
    },

    recordBankTransfer: async (client, walletId, amount, ledgerId, bankCode, accountNumber, externalReference = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO withdrawal_transactions (id, wallet_id, amount, withdrawal_method, status, ledger_transaction_id, linked_bank_id, bank_code, account_number, external_reference)
            VALUES ($1, $2, $3, 'BANK_TRANSFER', 'SUCCESS', $4, NULL, $5, $6, $7);
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

        // Filter theo ngày bắt đầu
        if (filters.startDate) {
            paramIndex++;
            whereExtra += ` AND le.created_at >= $${paramIndex}`;
            params.push(new Date(filters.startDate));
        }

        // Filter theo ngày kết thúc
        if (filters.endDate) {
            paramIndex++;
            whereExtra += ` AND le.created_at <= $${paramIndex}`;
            // Đặt endDate về cuối ngày
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
                le.transaction_id,
                lt.transaction_type,
                COALESCE(wt.category_name, lt.category_name) AS category_name,
                lt.is_expense_counted,
                le.entry_type,
                le.amount,
                le.balance_before,
                le.balance_after,
                lt.description,
                lt.status,
                le.created_at,
                wt.note AS transfer_note,
                COALESCE(u_sender.full_name, u_payer.full_name) AS sender_name,
                COALESCE(u_sender.phone, u_payer.phone) AS sender_phone,
                COALESCE(u_receiver.full_name, m.merchant_name) AS receiver_name,
                u_receiver.phone AS receiver_phone,
                COALESCE(dt.external_reference, wt_act.external_reference, wt.reference_code, po.order_code) AS external_reference
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.transaction_id = lt.id
            LEFT JOIN wallet_transfers wt ON lt.id = wt.transaction_id
            LEFT JOIN wallets w_sender ON wt.sender_wallet_id = w_sender.id
            LEFT JOIN users u_sender ON w_sender.user_id = u_sender.id
            LEFT JOIN wallets w_receiver ON wt.receiver_wallet_id = w_receiver.id
            LEFT JOIN users u_receiver ON w_receiver.user_id = u_receiver.id
            LEFT JOIN deposit_transactions dt ON lt.id = dt.ledger_transaction_id
            LEFT JOIN withdrawal_transactions wt_act ON lt.id = wt_act.ledger_transaction_id
            LEFT JOIN payment_transactions pt_pay ON lt.id = pt_pay.ledger_transaction_id
            LEFT JOIN payment_orders po ON pt_pay.payment_order_id = po.id
            LEFT JOIN merchants m ON po.merchant_id = m.id
            LEFT JOIN wallets w_payer ON pt_pay.payer_wallet_id = w_payer.id
            LEFT JOIN users u_payer ON w_payer.user_id = u_payer.id
            WHERE le.wallet_id = $1${whereExtra}
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
                le.transaction_id,
                lt.transaction_type,
                COALESCE(wt.category_name, lt.category_name) AS category_name,
                lt.is_expense_counted,
                le.entry_type,
                le.amount,
                le.balance_before,
                le.balance_after,
                lt.description,
                lt.status,
                le.created_at,
                wt.note AS transfer_note,
                COALESCE(u_sender.full_name, u_payer.full_name) AS sender_name,
                COALESCE(u_sender.phone, u_payer.phone) AS sender_phone,
                COALESCE(u_receiver.full_name, m.merchant_name) AS receiver_name,
                u_receiver.phone AS receiver_phone,
                COALESCE(dt.external_reference, wt_act.external_reference, wt.reference_code, po.order_code) AS external_reference
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.transaction_id = lt.id
            LEFT JOIN wallet_transfers wt ON lt.id = wt.transaction_id
            LEFT JOIN wallets w_sender ON wt.sender_wallet_id = w_sender.id
            LEFT JOIN users u_sender ON w_sender.user_id = u_sender.id
            LEFT JOIN wallets w_receiver ON wt.receiver_wallet_id = w_receiver.id
            LEFT JOIN users u_receiver ON w_receiver.user_id = u_receiver.id
            LEFT JOIN deposit_transactions dt ON lt.id = dt.ledger_transaction_id
            LEFT JOIN withdrawal_transactions wt_act ON lt.id = wt_act.ledger_transaction_id
            LEFT JOIN payment_transactions pt_pay ON lt.id = pt_pay.ledger_transaction_id
            LEFT JOIN payment_orders po ON pt_pay.payment_order_id = po.id
            LEFT JOIN merchants m ON po.merchant_id = m.id
            LEFT JOIN wallets w_payer ON pt_pay.payer_wallet_id = w_payer.id
            LEFT JOIN users u_payer ON w_payer.user_id = u_payer.id
            WHERE le.wallet_id = $1 AND le.created_at >= CURRENT_DATE - INTERVAL '1 year'
            ORDER BY le.created_at DESC
            LIMIT 500;
        `;
        const result = await pool.query(query, [walletId]);
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
    },

    getMonthlyStats: async (walletId) => {
        const query = `
            SELECT 
                COALESCE(SUM(CASE WHEN le.entry_type = 'DEBIT' AND EXTRACT(MONTH FROM le.created_at) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(YEAR FROM le.created_at) = EXTRACT(YEAR FROM CURRENT_DATE) THEN le.amount ELSE 0 END), 0) AS total_spend_this_month,
                COALESCE(SUM(CASE WHEN le.entry_type = 'CREDIT' AND EXTRACT(MONTH FROM le.created_at) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(YEAR FROM le.created_at) = EXTRACT(YEAR FROM CURRENT_DATE) THEN le.amount ELSE 0 END), 0) AS total_receive_this_month,
                COALESCE(SUM(CASE WHEN le.entry_type = 'DEBIT' AND EXTRACT(MONTH FROM le.created_at) = EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 month') AND EXTRACT(YEAR FROM le.created_at) = EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 month') THEN le.amount ELSE 0 END), 0) AS total_spend_last_month
            FROM ledger_entries le
            WHERE le.wallet_id = $1;
        `;
        const result = await pool.query(query, [walletId]);
        return result.rows[0];
    },

    getTransactionsByMonth: async (walletId, month, year) => {
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
                COALESCE(u_sender.full_name, u_payer.full_name) AS sender_name,
                COALESCE(u_sender.phone, u_payer.phone) AS sender_phone,
                COALESCE(u_receiver.full_name, m.merchant_name) AS receiver_name,
                u_receiver.phone AS receiver_phone,
                COALESCE(dt.external_reference, wt_act.external_reference, wt.reference_code, po.order_code) AS external_reference
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.transaction_id = lt.id
            LEFT JOIN wallet_transfers wt ON lt.id = wt.transaction_id
            LEFT JOIN wallets w_sender ON wt.sender_wallet_id = w_sender.id
            LEFT JOIN users u_sender ON w_sender.user_id = u_sender.id
            LEFT JOIN wallets w_receiver ON wt.receiver_wallet_id = w_receiver.id
            LEFT JOIN users u_receiver ON w_receiver.user_id = u_receiver.id
            LEFT JOIN deposit_transactions dt ON lt.id = dt.ledger_transaction_id
            LEFT JOIN withdrawal_transactions wt_act ON lt.id = wt_act.ledger_transaction_id
            LEFT JOIN payment_transactions pt_pay ON lt.id = pt_pay.ledger_transaction_id
            LEFT JOIN payment_orders po ON pt_pay.payment_order_id = po.id
            LEFT JOIN merchants m ON po.merchant_id = m.id
            LEFT JOIN wallets w_payer ON pt_pay.payer_wallet_id = w_payer.id
            LEFT JOIN users u_payer ON w_payer.user_id = u_payer.id
            WHERE le.wallet_id = $1 
              AND EXTRACT(MONTH FROM le.created_at) = $2 
              AND EXTRACT(YEAR FROM le.created_at) = $3
            ORDER BY le.created_at DESC;
        `;
        const result = await pool.query(query, [walletId, month, year]);
        return result.rows;
    },

    getChatList: async (walletId) => {
        const query = `
            WITH CTE AS (
                SELECT 
                    wt.id,
                    wt.amount,
                    lt.created_at,
                    CASE WHEN wt.sender_wallet_id = $1 THEN wt.receiver_wallet_id ELSE wt.sender_wallet_id END as counterparty_wallet_id,
                    CASE WHEN wt.sender_wallet_id = $1 THEN 'SEND' ELSE 'RECEIVE' END as direction,
                    wt.note,
                    'TRANSACTION' as message_type
                FROM wallet_transfers wt
                JOIN ledger_transactions lt ON wt.transaction_id = lt.id
                WHERE wt.sender_wallet_id = $1 OR wt.receiver_wallet_id = $1
                
                UNION ALL
                
                SELECT 
                    cm.id,
                    0 as amount,
                    cm.created_at,
                    CASE WHEN cm.sender_wallet_id = $1 THEN cm.receiver_wallet_id ELSE cm.sender_wallet_id END as counterparty_wallet_id,
                    CASE WHEN cm.sender_wallet_id = $1 THEN 'SEND' ELSE 'RECEIVE' END as direction,
                    cm.content as note,
                    cm.message_type
                FROM chat_messages cm
                WHERE cm.sender_wallet_id = $1 OR cm.receiver_wallet_id = $1
            )
            SELECT 
                c.counterparty_wallet_id,
                u.full_name as counterparty_name,
                u.phone as counterparty_phone,
                MAX(c.created_at) as latest_transaction_date
            FROM CTE c
            JOIN wallets w ON c.counterparty_wallet_id = w.id
            JOIN users u ON w.user_id = u.id
            GROUP BY c.counterparty_wallet_id, u.full_name, u.phone
            ORDER BY latest_transaction_date DESC;
        `;
        const result = await pool.query(query, [walletId]);
        return result.rows;
    },

    getChatHistory: async (walletId, counterpartyPhone, limit = 20, offset = 0) => {
        const query = `
            WITH AllMessages AS (
                SELECT 
                    wt.id as transfer_id,
                    wt.amount, 
                    wt.note, 
                    lt.created_at,
                    CASE WHEN wt.sender_wallet_id = $1 THEN 'SEND' ELSE 'RECEIVE' END as direction,
                    u_counterparty.full_name as counterparty_name,
                    u_counterparty.phone as counterparty_phone,
                    'TRANSACTION' as message_type
                FROM wallet_transfers wt
                JOIN ledger_transactions lt ON wt.transaction_id = lt.id
                JOIN wallets w_sender ON wt.sender_wallet_id = w_sender.id
                JOIN wallets w_receiver ON wt.receiver_wallet_id = w_receiver.id
                JOIN users u_sender ON w_sender.user_id = u_sender.id
                JOIN users u_receiver ON w_receiver.user_id = u_receiver.id
                JOIN users u_counterparty ON (CASE WHEN wt.sender_wallet_id = $1 THEN w_receiver.user_id ELSE w_sender.user_id END) = u_counterparty.id
                WHERE 
                    (wt.sender_wallet_id = $1 AND u_receiver.phone = $2)
                    OR 
                    (wt.receiver_wallet_id = $1 AND u_sender.phone = $2)
                
                UNION ALL
                
                SELECT 
                    cm.id as transfer_id,
                    0 as amount,
                    cm.content as note,
                    cm.created_at,
                    CASE WHEN cm.sender_wallet_id = $1 THEN 'SEND' ELSE 'RECEIVE' END as direction,
                    u_counterparty.full_name as counterparty_name,
                    u_counterparty.phone as counterparty_phone,
                    cm.message_type
                FROM chat_messages cm
                JOIN wallets w_sender ON cm.sender_wallet_id = w_sender.id
                JOIN wallets w_receiver ON cm.receiver_wallet_id = w_receiver.id
                JOIN users u_sender ON w_sender.user_id = u_sender.id
                JOIN users u_receiver ON w_receiver.user_id = u_receiver.id
                JOIN users u_counterparty ON (CASE WHEN cm.sender_wallet_id = $1 THEN w_receiver.user_id ELSE w_sender.user_id END) = u_counterparty.id
                WHERE 
                    (cm.sender_wallet_id = $1 AND u_receiver.phone = $2)
                    OR 
                    (cm.receiver_wallet_id = $1 AND u_sender.phone = $2)
            )
            SELECT * FROM AllMessages
            ORDER BY created_at DESC
            LIMIT $3 OFFSET $4;
        `;
        const result = await pool.query(query, [walletId, counterpartyPhone, limit, offset]);
        return result.rows;
    },
    saveChatMessage: async (senderWalletId, receiverWalletId, content) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO chat_messages (id, sender_wallet_id, receiver_wallet_id, content)
            VALUES ($1, $2, $3, $4)
            RETURNING *;
        `;
        const result = await pool.query(query, [newId, senderWalletId, receiverWalletId, content]);
        return result.rows[0];
    }
};

module.exports = transactionRepository;