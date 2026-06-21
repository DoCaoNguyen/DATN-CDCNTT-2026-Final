const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const merchantRepository = {
    registerMerchant: async (merchantData, apiKey) => {
        const client = await pool.connect();
        
        try {
            await client.query('BEGIN');
            
            // 1. Insert into merchants
            const merchantId = uuidv7();
            const merchantQuery = `
                INSERT INTO merchants (id, user_id, merchant_name, contact_phone, callback_url, status, secret_key)
                VALUES ($1, $2, $3, $4, $5, 'ACTIVE', $6)
                RETURNING id;
            `;
            const merchantValues = [
                merchantId,
                merchantData.user_id,
                merchantData.merchant_name,
                merchantData.contact_phone,
                merchantData.callback_url || null,
                merchantData.secret_key
            ];
            
            await client.query(merchantQuery, merchantValues);
            
            // 2. Insert into merchant_api_keys
            const apiKeyId = uuidv7();
            const apiKeyQuery = `
                INSERT INTO merchant_api_keys (id, merchant_id, api_key)
                VALUES ($1, $2, $3)
            `;
            const apiKeyValues = [apiKeyId, merchantId, apiKey];
            
            await client.query(apiKeyQuery, apiKeyValues);
            
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

    checkMerchantExistsByUser: async (userId) => {
        const query = 'SELECT id FROM merchants WHERE user_id = $1';
        const result = await pool.query(query, [userId]);
        return result.rows.length > 0;
    },
    
    getMerchantUserId: async (merchantId) => {
        const query = 'SELECT user_id FROM merchants WHERE id = $1';
        const result = await pool.query(query, [merchantId]);
        return result.rows.length > 0 ? result.rows[0].user_id : null;
    },

    getMerchantByUserId: async (userId) => {
        const query = `
            SELECT m.id as merchant_id, m.merchant_name, m.contact_phone, m.callback_url, m.status, m.secret_key,
                   mak.api_key
            FROM merchants m
            LEFT JOIN merchant_api_keys mak ON m.id = mak.merchant_id
            WHERE m.user_id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows.length > 0 ? result.rows[0] : null;
    },

    updateWebhookUrl: async (merchantId, callbackUrl) => {
        const query = 'UPDATE merchants SET callback_url = $1 WHERE id = $2 RETURNING callback_url';
        const result = await pool.query(query, [callbackUrl, merchantId]);
        return result.rows[0].callback_url;
    }
};

module.exports = merchantRepository;
