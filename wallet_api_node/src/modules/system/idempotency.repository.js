const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const idempotencyRepository = {
    findByKey: async (actorType, actorId, key) => {
        const query = `SELECT response_body FROM idempotency_keys WHERE actor_type = $1 AND actor_id = $2 AND idempotency_key = $3`;
        const result = await pool.query(query, [actorType, actorId, key]);
        return result.rows[0];
    },

    saveKey: async (actorType, actorId, requestPath, key, requestHash, responseData) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO idempotency_keys (id, actor_type, actor_id, request_path, idempotency_key, request_hash, response_body, expires_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP + INTERVAL '24 hours')
            ON CONFLICT (actor_type, actor_id, idempotency_key) DO NOTHING;
        `;
        
        await pool.query(query, [newId, actorType, actorId, requestPath, key, requestHash, JSON.stringify(responseData)]);
        return newId;
    }
};

module.exports = idempotencyRepository;