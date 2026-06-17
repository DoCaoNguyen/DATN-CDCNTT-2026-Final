const pool = require('../../config/db');

const webhookService = {
    createLog: async (client, merchantId, transactionId, idempotencyKey, payload) => {
        const query = `
            INSERT INTO webhook_logs (merchant_id, transaction_id, idempotency_key, payload, status)
            VALUES ($1, $2, $3, $4, 'PENDING')
            RETURNING id;
        `;
        const values = [merchantId, transactionId, idempotencyKey, JSON.stringify(payload)];
        
        // Use provided transaction client or default pool
        const dbClient = client || pool;
        const result = await dbClient.query(query, values);
        return result.rows[0].id;
    },

    updateLogStatus: async (logId, status, lastError = null) => {
        const query = `
            UPDATE webhook_logs 
            SET status = $1, last_error = $2, updated_at = CURRENT_TIMESTAMP
            WHERE id = $3
        `;
        await pool.query(query, [status, lastError, logId]);
    },

    incrementRetry: async (logId, lastError = null) => {
        const query = `
            UPDATE webhook_logs 
            SET retry_count = retry_count + 1, last_error = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2
            RETURNING retry_count, max_retries;
        `;
        const result = await pool.query(query, [lastError, logId]);
        return result.rows[0];
    },

    getMerchantSecret: async (merchantId) => {
        const query = `SELECT secret_key, callback_url FROM merchants WHERE id = $1`;
        const result = await pool.query(query, [merchantId]);
        return result.rows[0];
    }
};

module.exports = webhookService;
