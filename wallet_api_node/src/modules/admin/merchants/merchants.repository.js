const pool = require('../../../config/db');
const { buildPagination } = require('../_shared');
const { mapMerchantRow, mapMerchantDetailRow, mapApiKeyRow } = require('./merchants.mapper');

const merchantsRepository = {
    listMerchants: async (page, limit, search) => {
        const { limitVal, offsetVal } = buildPagination(page, limit);
        let whereClause = '1=1';
        const params = [];

        if (search) {
            whereClause += ` AND (merchant_name ILIKE $1)`;
            params.push(`%${search}%`);
        }

        const countQuery = `SELECT COUNT(*) FROM merchants WHERE ${whereClause}`;
        const countRes = await pool.query(countQuery, params);
        const total = parseInt(countRes.rows[0].count, 10);

        const listQuery = `
            SELECT id, merchant_name, business_type, status, created_at,
                   (merchants.webhook_config->>'api_key' IS NOT NULL) as has_api_key,
                   (merchants.webhook_config->>'callback_url') as default_callback_url,
                   (merchants.webhook_config->>'is_enabled')::boolean as callback_enabled
            FROM merchants
            WHERE ${whereClause}
            ORDER BY created_at DESC
            LIMIT $${params.length + 1} OFFSET $${params.length + 2}
        `;
        const listParams = [...params, limitVal, offsetVal];
        const listRes = await pool.query(listQuery, listParams);

        return {
            total,
            page: parseInt(page, 10) || 1,
            limit: limitVal,
            data: listRes.rows.map(mapMerchantRow)
        };
    },

    findMerchantById: async (id) => {
        const query = `
            SELECT id, merchant_name, business_type, 
                   status, created_at, updated_at
            FROM merchants
            WHERE id = $1
        `;
        const res = await pool.query(query, [id]);
        if (res.rows.length === 0) return null;
        return mapMerchantDetailRow(res.rows[0]);
    },

    updateMerchantStatus: async (id, status, client = pool) => {
        const query = `
            UPDATE merchants 
            SET status = $2, updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING *
        `;
        const res = await client.query(query, [id, status]);
        if (res.rows.length === 0) return null;
        return mapMerchantDetailRow(res.rows[0]);
    },

    getMerchantApiKeys: async (merchantId) => {
        const query = `
            SELECT m.id, 'Default Key' as key_name, m.webhook_config->>'api_key' as api_key, 
                   'PRODUCTION' as environment, 'ACTIVE' as status, m.created_at as created_at
            FROM merchants m
            WHERE m.id = $1 AND m.webhook_config->>'api_key' IS NOT NULL
        `;
        const res = await pool.query(query, [merchantId]);
        return res.rows.map(mapApiKeyRow);
    },

    generateNextMerchantCode: async (client) => {
        // 1. Sync if not exists
        await client.query(`
            INSERT INTO code_sequences (id, resource_name, prefix, current_value, padding, reset_policy)
            SELECT gen_random_uuid(), 'MERCHANT', 'MER', COALESCE((
                SELECT MAX(CAST(SUBSTRING(merchant_code FROM 4) AS INTEGER))
                FROM merchants
                WHERE merchant_code ~ '^MER[0-9]{6}$'
            ), 0), 6, 'NEVER'
            WHERE NOT EXISTS (SELECT 1 FROM code_sequences WHERE resource_name = 'MERCHANT');
        `);

        // 2. Increment and return
        const res = await client.query(`
            UPDATE code_sequences
            SET current_value = current_value + 1, updated_at = CURRENT_TIMESTAMP
            WHERE resource_name = 'MERCHANT'
            RETURNING prefix || LPAD(current_value::text, padding, '0') AS merchant_code
        `);
        return res.rows[0].merchant_code;
    },

    createMerchant: async (merchantData, client = pool) => {
        const { merchant_name, business_type, status = 'PENDING_REVIEW', user_id } = merchantData;
        const { v7: uuidv7 } = require('uuid');
        const newId = uuidv7();
        const query = `
            INSERT INTO merchants (id, merchant_name, business_type, status, user_id)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
        `;
        const params = [newId, merchant_name, business_type, status, user_id];
        const res = await client.query(query, params);
        return res.rows[0];
    },

    updateMerchantInfo: async (id, data, client = pool) => {
        const fields = [];
        const params = [id];
        let paramIdx = 2;

        const updatableFields = ['merchant_name', 'business_type', 'status'];
        
        for (const field of updatableFields) {
            if (data[field] !== undefined) {
                fields.push(`${field} = $${paramIdx}`);
                params.push(data[field]);
                paramIdx++;
            }
        }

        if (fields.length === 0) return null;

        const query = `
            UPDATE merchants 
            SET ${fields.join(', ')}, updated_at = NOW()
            WHERE id = $1
            RETURNING *
        `;
        const res = await client.query(query, params);
        return res.rows.length ? res.rows[0] : null;
    },

    findCallbackConfig: async (merchantId, client = pool) => {
        const res = await client.query('SELECT webhook_config->>\'callback_url\' as default_callback_url, webhook_config->>\'redirect_url\' as default_redirect_url, webhook_config->>\'secret_hash\' as webhook_secret_hash, (webhook_config->>\'is_enabled\')::boolean as callback_enabled, (webhook_config->>\'retry_enabled\')::boolean as retry_enabled FROM merchants WHERE id = $1', [merchantId]);
        return res.rows.length ? res.rows[0] : null;
    },

    createCallbackConfig: async (merchantId, data, client = pool) => {
        const crypto = require('crypto');
        const webhookSecret = data.webhook_secret_hash || crypto.randomBytes(32).toString('hex');
        const query = `
            UPDATE merchants
            SET webhook_config = jsonb_set(
                jsonb_set(
                    jsonb_set(
                        jsonb_set(
                            jsonb_set(webhook_config, '{callback_url}', to_jsonb(COALESCE($1::text, webhook_config->>'callback_url')), true),
                            '{redirect_url}', to_jsonb(COALESCE($2::text, webhook_config->>'redirect_url')), true
                        ),
                        '{secret_hash}', to_jsonb(COALESCE($3::text, webhook_config->>'secret_hash')), true
                    ),
                    '{is_enabled}', to_jsonb(COALESCE($4::boolean, (webhook_config->>'is_enabled')::boolean)), true
                ),
                '{retry_enabled}', to_jsonb(COALESCE($5::boolean, (webhook_config->>'retry_enabled')::boolean)), true
            )
            WHERE id = $6
            RETURNING webhook_config->>'callback_url' as default_callback_url, webhook_config->>'redirect_url' as default_redirect_url, webhook_config->>'secret_hash' as webhook_secret_hash, (webhook_config->>'is_enabled')::boolean as callback_enabled, (webhook_config->>'retry_enabled')::boolean as retry_enabled
        `;
        const params = [
            data.default_callback_url || null, 
            data.default_redirect_url || null, 
            webhookSecret, 
            data.callback_enabled ?? true, 
            data.retry_enabled ?? true,
            merchantId
        ];
        const res = await client.query(query, params);
        return res.rows[0];
    },

    updateCallbackConfig: async (id, data, client = pool) => {
        // id is merchant_id
        return merchantsRepository.createCallbackConfig(id, data, client);
    },

    createApiKey: async (merchantId, keyName, apiKey, apiSecretHash, environment, client = pool) => {
        const query = `
            UPDATE merchants
            SET webhook_config = jsonb_set(
                jsonb_set(webhook_config, '{api_key}', to_jsonb($1::text), true),
                '{secret_hash}', to_jsonb($2::text), true
            )
            WHERE id = $3
            RETURNING id, 'Default Key' as key_name, webhook_config->>'api_key' as api_key, 'PRODUCTION' as environment, 'ACTIVE' as status
        `;
        const res = await client.query(query, [apiKey, apiSecretHash, merchantId]);
        return res.rows[0];
    },

    findApiKeyById: async (keyId, client = pool) => {
        // keyId is used as merchant_id
        const query = `SELECT m.id as id, 'ACTIVE' as status, 'PRODUCTION' as environment FROM merchants m WHERE id = $1`;
        const res = await client.query(query, [keyId]);
        return res.rows.length ? res.rows[0] : null;
    },

    updateApiKeyStatus: async (keyId, status, client = pool) => {
        // Since there is only one key per merchant in webhook_config, we revoke it by setting it to null
        if (status === 'REVOKED') {
            const query = `
                UPDATE merchants
                SET webhook_config = jsonb_set(webhook_config, '{api_key}', 'null'::jsonb, true)
                WHERE id = $1
                RETURNING id, 'Default Key' as key_name, 'REVOKED' as status
            `;
            const res = await client.query(query, [keyId]);
            return res.rows.length ? res.rows[0] : null;
        }
        return null;
    },

    getPool: () => pool
};

module.exports = merchantsRepository;
