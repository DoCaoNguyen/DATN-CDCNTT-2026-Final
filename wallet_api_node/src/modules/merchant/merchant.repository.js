const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const merchantRepository = {
    registerMerchant: async (merchantData, apiKey) => {
        const client = await pool.connect();
        
        try {
            await client.query('BEGIN');
            
            const merchantId = uuidv7();
            const merchantQuery = `
                INSERT INTO merchants (id, merchant_name, status, business_type, user_id)
                VALUES ($1, $2, 'ACTIVE', 'ONLINE', $3)
                RETURNING id;
            `;
            const merchantValues = [
                merchantId,
                merchantData.merchant_name,
                merchantData.user_id
            ];
            
            await client.query(merchantQuery, merchantValues);

            // 3. Update webhook_config
            await client.query(
                `UPDATE merchants 
                 SET webhook_config = jsonb_build_object(
                    'api_key', $1::text,
                    'callback_url', COALESCE($2::text, ''),
                    'redirect_url', COALESCE($3::text, ''),
                    'secret_hash', COALESCE($4::text, ''),
                    'is_enabled', true,
                    'retry_enabled', true
                 )
                 WHERE id = $5`,
                [apiKey, merchantData.callback_url || '', merchantData.redirect_url || '', merchantData.secret_key, merchantId]
            );

            // 6. Assign global MERCHANT_OWNER role to the user
            await client.query(`
                INSERT INTO user_roles (user_id, role_id)
                SELECT $1, id FROM roles WHERE code = 'MERCHANT_OWNER'
                ON CONFLICT DO NOTHING
            `, [merchantData.user_id]);
            
            await client.query('COMMIT');
            return merchantId;
            
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    
    findUserByPhone: async (phone) => {
        const query = 'SELECT id FROM users WHERE phone = $1';
        const result = await pool.query(query, [phone]);
        return result.rows.length > 0 ? result.rows[0].id : null;
    },

    getWalletIdByPhone: async (phone) => {
        const query = `
            SELECT w.id as wallet_id, u.id as user_id 
            FROM users u 
            JOIN wallets w ON u.id = w.user_id 
            WHERE u.phone = $1 LIMIT 1
        `;
        const result = await pool.query(query, [phone]);
        return result.rows.length > 0 ? result.rows[0] : null;
    },

    getLinkedService: async (userId, merchantId) => {
        const query = "SELECT limit_per_day, limit_per_transaction, status FROM user_linked_services WHERE user_id = $1 AND merchant_id = $2 LIMIT 1";
        const result = await pool.query(query, [userId, merchantId]);
        return result.rows.length > 0 ? result.rows[0] : null;
    },

    getDailyUsageForMerchant: async (walletId, merchantId) => {
        const query = `
            SELECT SUM(pt.amount) as total
            FROM payment_transactions pt
            JOIN payment_orders po ON pt.payment_order_id = po.id
            WHERE pt.payer_wallet_id = $1 
              AND po.merchant_id = $2 
              AND pt.created_at >= CURRENT_DATE
              AND pt.status = 'SUCCESS'
        `;
        const result = await pool.query(query, [walletId, merchantId]);
        return result.rows.length > 0 && result.rows[0].total ? BigInt(result.rows[0].total) : 0n;
    },

    getUserPinHashByPhone: async (phone) => {
        const query = 'SELECT pin_hash FROM users WHERE phone = $1 LIMIT 1';
        const result = await pool.query(query, [phone]);
        return result.rows.length > 0 ? result.rows[0].pin_hash : null;
    },

    getMerchantByApiKey: async (apiKey) => {
        const query = `
            SELECT m.id, m.merchant_name, m.user_id as merchant_user_id 
            FROM merchants m
            WHERE m.webhook_config->>'api_key' = $1 LIMIT 1
        `;
        const result = await pool.query(query, [apiKey]);
        return result.rows.length > 0 ? result.rows[0] : null;
    },

    checkMerchantExistsByUser: async (userId) => {
        const query = 'SELECT id FROM merchants WHERE user_id = $1 LIMIT 1';
        const result = await pool.query(query, [userId]);
        return result.rows.length > 0;
    },
    
    getMerchantUserId: async (merchantId) => {
        const query = 'SELECT user_id FROM merchants WHERE id = $1 LIMIT 1';
        const result = await pool.query(query, [merchantId]);
        return result.rows.length > 0 ? result.rows[0].user_id : null;
    },

    getMerchantByUserId: async (userId) => {
        const query = `
            SELECT m.id as merchant_id, m.merchant_name, 
                   m.webhook_config->>'callback_url' as callback_url, m.status, 
                   m.webhook_config->>'secret_hash' as secret_key,
                   m.webhook_config->>'api_key' as api_key
            FROM merchants m
            WHERE m.user_id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows.length > 0 ? result.rows[0] : null;
    },

    updateWebhookUrl: async (merchantId, callbackUrl) => {
        const query = `
            UPDATE merchants 
            SET webhook_config = jsonb_set(webhook_config, '{callback_url}', to_jsonb($1::text), true)
            WHERE id = $2 
            RETURNING webhook_config->>'callback_url' as callback_url
        `;
        const result = await pool.query(query, [callbackUrl, merchantId]);
        return result.rows[0].callback_url;
    },
    // --- MERCHANT PORTAL NEW APIs ---

    getMerchantProfile: async (merchantId) => {
        const query = `
            SELECT m.id, m.id AS merchant_id, m.user_id AS merchant_user_id, m.merchant_name, m.business_type, m.status,
                   m.webhook_config->>'callback_url' AS callback_url, 
                   m.webhook_config->>'redirect_url' AS default_redirect_url, 
                   (m.webhook_config->>'is_enabled')::boolean AS callback_enabled, 
                   (m.webhook_config->>'retry_enabled')::boolean AS retry_enabled,
                   m.webhook_config->>'api_key' AS api_key, 
                   m.webhook_config->>'secret_hash' AS secret_key
            FROM merchants m
            WHERE m.id = $1
            LIMIT 1
        `;
        const result = await pool.query(query, [merchantId]);
        return result.rows.length > 0 ? result.rows[0] : null;
    },

    updateCallbackConfig: async (merchantId, data) => {
        const query = `
            UPDATE merchants
            SET webhook_config = jsonb_set(
                jsonb_set(webhook_config, '{callback_url}', to_jsonb(COALESCE($1::text, webhook_config->>'callback_url')), true),
                '{redirect_url}', to_jsonb(COALESCE($2::text, webhook_config->>'redirect_url')), true
            )
            WHERE id = $3
            RETURNING webhook_config->>'callback_url' as default_callback_url, webhook_config->>'redirect_url' as default_redirect_url
        `;
        const result = await pool.query(query, [data.default_callback_url, data.default_redirect_url, merchantId]);
        return result.rows[0];
    },

    getApiKeys: async (merchantId) => {
        const result = await pool.query(`
            SELECT m.id as id, 'Default Key' as key_name, 
                   m.webhook_config->>'api_key' as api_key, 
                   m.webhook_config->>'secret_hash' as api_secret_hash, 
                   'PRODUCTION' as environment, 'ACTIVE' as status, m.created_at
            FROM merchants m
            WHERE m.id = $1 AND m.webhook_config->>'api_key' IS NOT NULL
        `, [merchantId]);
        return result.rows;
    },

    createApiKey: async (merchantId, keyName, apiKey, apiSecretHash, environment) => {
        const query = `
            UPDATE merchants
            SET webhook_config = jsonb_set(
                jsonb_set(webhook_config, '{api_key}', to_jsonb($1::text), true),
                '{secret_hash}', to_jsonb($2::text), true
            )
            WHERE id = $3
            RETURNING id, 'Default Key' as key_name, webhook_config->>'api_key' as api_key, 'PRODUCTION' as environment, 'ACTIVE' as status, updated_at as created_at
        `;
        const result = await pool.query(query, [apiKey, apiSecretHash, merchantId]);
        return result.rows[0];
    },

    getApiKeyByIdAndMerchant: async (keyId, merchantId) => {
        // Now there is only one key per merchant in webhook_config. We can just check the merchant.
        const result = await pool.query(`
            SELECT m.id as id, 'ACTIVE' as status, 'PRODUCTION' as environment
            FROM merchants m
            WHERE m.id = $1 AND m.webhook_config->>'api_key' IS NOT NULL
        `, [merchantId]);
        return result.rows[0];
    },

    updateApiSecretHash: async (keyId, secretHash) => {
        // keyId is basically merchantId or not needed since we only have one key
        // We will just use it as merchantId for simplicity or ignore.
        // Wait, the API calls this with `keyId` which was previously the `merchant_api_keys.id`.
        // We should fix the controller to pass `merchantId` instead of `keyId`.
        const result = await pool.query(`
            UPDATE merchants
            SET webhook_config = jsonb_set(webhook_config, '{secret_hash}', to_jsonb($1::text), true)
            WHERE id = $2
            RETURNING id, 'Default Key' as key_name, webhook_config->>'api_key' as api_key, 'PRODUCTION' as environment, 'ACTIVE' as status, updated_at
        `, [secretHash, keyId]);
        return result.rows[0];
    },

    revokeApiKey: async (keyId) => {
        await pool.query(`
            UPDATE merchants
            SET webhook_config = jsonb_set(webhook_config, '{api_key}', 'null'::jsonb, true)
            WHERE id = $1
        `, [keyId]);
    },

    getPaymentOrders: async (merchantId, filters) => {
        const { page = 1, limit = 20, status, date_from, date_to, keyword, sort_by = 'created_at', sort_order = 'desc' } = filters;
        const offset = (page - 1) * limit;
        const params = [merchantId];
        const where = ['merchant_id = $1'];

        if (status) {
            params.push(status);
            where.push(`status = $${params.length}`);
        }
        if (date_from) {
            params.push(date_from);
            where.push(`created_at >= $${params.length}`);
        }
        if (date_to) {
            params.push(date_to);
            where.push(`created_at <= $${params.length}`);
        }
        if (keyword) {
            params.push(`%${keyword}%`);
            where.push(`(payment_no ILIKE $${params.length} OR merchant_order_id ILIKE $${params.length})`);
        }

        const whereSql = where.join(' AND ');
        
        const countResult = await pool.query(`SELECT COUNT(*)::int as total FROM payment_orders WHERE ${whereSql}`, params);
        const total = countResult.rows[0].total;

        params.push(limit, offset);
        const result = await pool.query(`
            SELECT id, payment_no, merchant_order_id, amount, currency, status, created_at, expired_at
            FROM payment_orders
            WHERE ${whereSql}
            ORDER BY ${sort_by} ${sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC'}
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `, params);

        return { items: result.rows, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
    },

    getPaymentOrderById: async (merchantId, orderId) => {
        const query = `SELECT * FROM payment_orders WHERE merchant_id = $1 AND id = $2`;
        const result = await pool.query(query, [merchantId, orderId]);
        return result.rows[0];
    },

    getTransactions: async (merchantId, filters) => {
        const { page = 1, limit = 20, status, date_from, date_to, sort_by = 'created_at', sort_order = 'desc' } = filters;
        const offset = (page - 1) * limit;
        const params = [merchantId];
        
        // We join payment_orders to ensure we only get transactions for this merchant
        const where = ['po.merchant_id = $1'];

        if (status) {
            params.push(status);
            where.push(`pt.status = $${params.length}`);
        }
        if (date_from) {
            params.push(date_from);
            where.push(`pt.created_at >= $${params.length}`);
        }
        if (date_to) {
            params.push(date_to);
            where.push(`pt.created_at <= $${params.length}`);
        }

        const whereSql = where.join(' AND ');
        
        const countQuery = `
            SELECT COUNT(*)::int as total 
            FROM payment_transactions pt
            JOIN payment_orders po ON pt.payment_order_id = po.id
            WHERE ${whereSql}
        `;
        const countResult = await pool.query(countQuery, params);
        const total = countResult.rows[0].total;

        params.push(limit, offset);
        const result = await pool.query(`
            SELECT pt.id, pt.payment_order_id, pt.amount, pt.currency, pt.status, pt.paid_at, pt.created_at, po.payment_no
            FROM payment_transactions pt
            JOIN payment_orders po ON pt.payment_order_id = po.id
            WHERE ${whereSql}
            ORDER BY pt.${sort_by} ${sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC'}
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `, params);

        return { items: result.rows, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
    },

    getTransactionById: async (merchantId, transactionId) => {
        const query = `
            SELECT pt.*, po.payment_no 
            FROM payment_transactions pt
            JOIN payment_orders po ON pt.payment_order_id = po.id
            WHERE po.merchant_id = $1 AND pt.id = $2
        `;
        const result = await pool.query(query, [merchantId, transactionId]);
        return result.rows[0];
    },

    getWebhooks: async (merchantId, filters) => {
        const { page = 1, limit = 20, status, date_from, date_to, sort_by = 'created_at', sort_order = 'desc' } = filters;
        const offset = (page - 1) * limit;
        const params = [merchantId];
        
        const where = ["po.merchant_id = $1", "oe.aggregate_type = 'PAYMENT_ORDER'"];

        if (status) {
            params.push(status);
            where.push(`oe.status = $${params.length}`);
        }
        if (date_from) {
            params.push(date_from);
            where.push(`oe.created_at >= $${params.length}`);
        }
        if (date_to) {
            params.push(date_to);
            where.push(`oe.created_at <= $${params.length}`);
        }

        const whereSql = where.join(' AND ');
        
        const countQuery = `
            SELECT COUNT(*)::int as total 
            FROM outbox_events oe
            JOIN payment_orders po ON oe.aggregate_id::text = po.id::text
            WHERE ${whereSql}
        `;
        const countResult = await pool.query(countQuery, params);
        const total = countResult.rows[0].total;

        params.push(limit, offset);
        const result = await pool.query(`
            SELECT oe.id, oe.aggregate_id as payment_order_id, oe.event_type, oe.payload, oe.status, oe.created_at, po.payment_no
            FROM outbox_events oe
            JOIN payment_orders po ON oe.aggregate_id::text = po.id::text
            WHERE ${whereSql}
            ORDER BY oe.${sort_by} ${sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC'}
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `, params);

        return { items: result.rows, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
    },

    getWebhookById: async (merchantId, webhookId) => {
        const query = `
            SELECT oe.*, po.payment_no 
            FROM outbox_events oe
            JOIN payment_orders po ON oe.aggregate_id::text = po.id::text
            WHERE po.merchant_id = $1 AND oe.id = $2
        `;
        const result = await pool.query(query, [merchantId, webhookId]);
        return result.rows[0];
    },

    retryWebhook: async (merchantId, webhookId) => {
        
        const original = await merchantRepository.getWebhookById(merchantId, webhookId);
        if (!original) throw new Error('Webhook event not found');

        const { v7: uuidv7 } = require('uuid');
        const newId = uuidv7();
        
        const query = `
            INSERT INTO outbox_events (id, aggregate_type, aggregate_id, event_type, payload, status)
            VALUES ($1, $2, $3, $4, $5, 'PENDING')
            RETURNING id, status, created_at
        `;
        const newPayload = { ...original.payload, is_retry: true, original_event_id: original.id };
        const result = await pool.query(query, [newId, original.aggregate_type, original.aggregate_id, original.event_type, newPayload]);
        return result.rows[0];
    },

    getMerchantBalance: async (merchantId) => {
        const query = `
            SELECT wb.available_balance, 0 as pending_balance 
            FROM wallet_balances wb
            JOIN wallets w ON w.id = wb.wallet_id
            JOIN merchants m ON m.user_id = w.user_id
            WHERE m.id = $1 AND wb.currency = 'VND'
        `;
        const result = await pool.query(query, [merchantId]);
        return result.rows[0];
    },

    getMerchantStatement: async (merchantId, filters) => {
        const { page = 1, limit = 20, date_from, date_to, type, sort_by = 'created_at', sort_order = 'desc' } = filters;
        const offset = (page - 1) * limit;
        const params = [merchantId];
        const where = ["po.merchant_id = $1", "le.account_type = 'MERCHANT_OWNER_WALLET'"];

        if (date_from) {
            params.push(date_from);
            where.push(`le.created_at >= $${params.length}`);
        }
        if (date_to) {
            params.push(date_to);
            where.push(`le.created_at <= $${params.length}`);
        }
        if (type) {
            params.push(type.toUpperCase());
            where.push(`le.entry_type = $${params.length}`);
        }

        const whereSql = where.join(' AND ');
        
        const countQuery = `
            SELECT COUNT(*)::int as total 
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            JOIN payment_transactions pt ON lt.source_type = 'PAYMENT' AND lt.source_id = pt.id
            JOIN payment_orders po ON pt.payment_order_id = po.id
            WHERE ${whereSql}
        `;
        const countResult = await pool.query(countQuery, params);
        const total = countResult.rows[0].total;

        params.push(limit, offset);
        const result = await pool.query(`
            SELECT 
                le.id,
                le.ledger_transaction_id,
                le.entry_type,
                le.amount,
                le.balance_before,
                le.balance_after,
                le.created_at,
                lt.transaction_type,
                lt.source_type,
                lt.source_id,
                -- Thông tin đơn hàng (khi là CREDIT từ PAYMENT)
                po.payment_no,
                po.amount AS order_amount,
                -- Thông tin khách hàng thanh toán
                u_payer.full_name AS payer_name,
                u_payer.phone AS payer_phone,
                -- Thông tin rút tiền
                wlb.bank_code,
                wlb.card_number AS bank_account_number,
                -- Thông tin rút về ví cá nhân
                u_wallet.full_name AS wallet_owner_name,
                u_wallet.phone AS wallet_owner_phone
            FROM ledger_entries le
            JOIN ledger_transactions lt ON le.ledger_transaction_id = lt.id
            -- JOIN payment (nhận doanh thu từ đơn hàng)
            LEFT JOIN payment_transactions pt ON lt.source_type = 'PAYMENT' AND lt.source_id = pt.id
            LEFT JOIN payment_orders po ON pt.payment_order_id = po.id
            LEFT JOIN wallets w_payer ON pt.payer_wallet_id = w_payer.id
            LEFT JOIN users u_payer ON w_payer.user_id = u_payer.id
            -- JOIN withdrawal (rút về ngân hàng)
            LEFT JOIN withdrawal_transactions wt_act ON lt.source_type = 'WITHDRAWAL' AND lt.source_id = wt_act.id
            LEFT JOIN wallet_linked_banks wlb ON wt_act.linked_bank_id = wlb.id
            -- JOIN transfer (rút về ví cá nhân)
            LEFT JOIN wallet_transfers wtr ON lt.source_type = 'TRANSFER' AND lt.source_id = wtr.id
            LEFT JOIN wallets w_recv ON wtr.receiver_wallet_id = w_recv.id
            LEFT JOIN users u_wallet ON w_recv.user_id = u_wallet.id
            WHERE ${whereSql}
            ORDER BY le.created_at ${sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC'}
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `, params);

        return { items: result.rows, pagination: { page, limit, total, total_pages: Math.ceil(total / limit) } };
    }
};

module.exports = merchantRepository;
