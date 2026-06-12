const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const authRepository = {
    checkExists: async (email, phone) => {
        const query = 'SELECT id FROM users WHERE email = $1 OR phone = $2';
        const result = await pool.query(query, [email, phone]);
        return result.rows.length > 0;
    },

    create: async (client, email, phone, passwordHash) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO users (id, email, phone, password_hash) 
            VALUES ($1, $2, $3, $4) RETURNING id
        `;
        const result = await client.query(query, [newId, email, phone, passwordHash]);
        return result.rows[0].id;
    },

    findByEmailOrPhone: async (identifier) => {
        const query = `
            SELECT id, email, phone, password_hash, role, status, failed_login_attempts, locked_until, is_kyc_verified, token_version 
            FROM users 
            WHERE email = $1 OR phone = $1
        `;
        const result = await pool.query(query, [identifier]);
        return result.rows[0]; 
    },

    updateFailedLogin: async (userId, attempts, lockMinutes = 0) => {
        let query;
        if (lockMinutes > 0) {
            query = `UPDATE users SET failed_login_attempts = $1, locked_until = NOW() + INTERVAL '${lockMinutes} minutes' WHERE id = $2`;
        } else {
            query = `UPDATE users SET failed_login_attempts = $1 WHERE id = $2`;
        }
        await pool.query(query, [attempts, userId]);
    },

    resetFailedLogin: async (userId) => {
        const query = `UPDATE users SET failed_login_attempts = 0, locked_until = NULL WHERE id = $1`;
        await pool.query(query, [userId]);
    },

    incrementTokenVersion: async (userId) => {
        const query = `
            UPDATE users 
            SET token_version = token_version + 1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $1 
            RETURNING token_version
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0].token_version;
    },

    saveRefreshToken: async (userId, tokenHash, tokenFamilyId, expiresAt, ipAddress, userAgent) => {
        const id = uuidv7();
        const query = `
            INSERT INTO refresh_tokens (id, user_id, token_hash, token_family_id, expires_at, created_by_ip, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `;
        await pool.query(query, [id, userId, tokenHash, tokenFamilyId, expiresAt, ipAddress, userAgent]);
    },

    findRefreshToken: async (tokenHash) => {
        const query = `SELECT * FROM refresh_tokens WHERE token_hash = $1`;
        const result = await pool.query(query, [tokenHash]);
        return result.rows[0];
    },

    revokeRefreshTokenFamily: async (tokenFamilyId, ipAddress) => {
        const query = `
            UPDATE refresh_tokens 
            SET revoked_at = CURRENT_TIMESTAMP, revoked_by_ip = $2
            WHERE token_family_id = $1 AND revoked_at IS NULL
        `;
        await pool.query(query, [tokenFamilyId, ipAddress]);
    },
    
    markRefreshTokenAsReused: async (tokenHash) => {
        const query = `UPDATE refresh_tokens SET reused_at = CURRENT_TIMESTAMP WHERE token_hash = $1`;
        await pool.query(query, [tokenHash]);
    }
};

module.exports = authRepository;