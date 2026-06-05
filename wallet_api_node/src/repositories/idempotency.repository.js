const pool = require('../config/db');

const idempotencyRepository = {
    findByKey: async (key) => {
        const query = `SELECT response_data FROM idempotency_keys WHERE idempotency_key = $1`;
        const result = await pool.query(query, [key]);
        return result.rows[0];
    },

    saveKey: async (key, requestHash, responseData) => {
        const query = `
            INSERT INTO idempotency_keys (idempotency_key, request_hash, response_data, expired_at)
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP + INTERVAL '24 hours')
            ON CONFLICT (idempotency_key) DO NOTHING;
        `;
        // Chuyển object responseData thành chuỗi JSON trước khi lưu vào cột jsonb
        await pool.query(query, [key, requestHash, JSON.stringify(responseData)]);
    }
};

module.exports = idempotencyRepository;