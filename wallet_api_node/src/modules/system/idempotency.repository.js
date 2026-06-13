const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const idempotencyRepository = {
    findByKey: async (key) => {
        const query = `SELECT response_data FROM idempotency_keys WHERE idempotency_key = $1`;
        const result = await pool.query(query, [key]);
        return result.rows[0];
    },

    saveKey: async (key, requestHash, responseData) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO idempotency_keys (id, idempotency_key, request_hash, response_data, expired_at)
            VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP + INTERVAL '24 hours')
            ON CONFLICT (idempotency_key) DO NOTHING;
        `;
        
        await pool.query(query, [newId, key, requestHash, JSON.stringify(responseData)]);
        return newId;
    }
};

module.exports = idempotencyRepository;