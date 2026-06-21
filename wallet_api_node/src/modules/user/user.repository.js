const pool = require('../../config/db');

const userRepository = {
    searchUsers: async (searchQuery, currentUserId) => {
        const query = `
            SELECT u.id, u.full_name, u.phone, u.email
            FROM users u
            JOIN wallets w ON u.id = w.user_id
            WHERE u.id != $1 
              AND (u.phone = $2 OR u.full_name ILIKE $3 OR u.email ILIKE $3)
            LIMIT 20
        `;
        const result = await pool.query(query, [currentUserId, searchQuery, `%${searchQuery}%`]);
        return result.rows;
    },

    getUsersByPhones: async (phones, currentUserId) => {
        if (!phones || phones.length === 0) return [];
        const query = `
            SELECT u.id, u.full_name, u.phone, u.email
            FROM users u
            JOIN wallets w ON u.id = w.user_id
            WHERE u.id != $1 AND u.phone = ANY($2::text[])
        `;
        const result = await pool.query(query, [currentUserId, phones]);
        return result.rows;
    },

    getUserProfile: async (userId) => {
        const query = `
            SELECT u.full_name, u.phone, u.email, k.id_number as identity_number
            FROM users u
            LEFT JOIN user_kyc k ON u.id = k.user_id
            WHERE u.id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getAllUsers: async () => {
        const query = 'SELECT id, full_name, phone, email, user_type AS role, status, created_at FROM users ORDER BY created_at DESC';
        const result = await pool.query(query);
        return result.rows;
    },

    getUserById: async (userId) => {
        const query = 'SELECT id, full_name, phone, email, user_type AS role, status, created_at FROM users WHERE id = $1';
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    saveEmailOtp: async (userId, email, otpCode, minutesValid = 5) => {
        const { v7: uuidv7 } = require('uuid');
        const userRes = await pool.query('SELECT phone FROM users WHERE id = $1', [userId]);
        const phone = userRes.rows[0].phone;
        const newId = uuidv7();
        const query = `
            INSERT INTO otp_tracking (id, phone, email, otp_hash, failed_attempts, expired_at, created_at)
            VALUES ($1, $2, $3, $4, 0, NOW() + INTERVAL '${minutesValid} minutes', NOW())
        `;
        await pool.query(query, [newId, phone, email, otpCode]);
    },

    checkEmailOtp: async (userId, email) => {
        const userRes = await pool.query('SELECT phone FROM users WHERE id = $1', [userId]);
        const phone = userRes.rows[0].phone;
        const query = `SELECT otp_hash as email_otp, expired_at as email_otp_expired_at FROM otp_tracking WHERE phone = $1 AND email = $2 ORDER BY created_at DESC LIMIT 1`;
        const result = await pool.query(query, [phone, email]);
        return result.rows[0];
    },

    clearEmailOtp: async (userId, email) => {
        const userRes = await pool.query('SELECT phone FROM users WHERE id = $1', [userId]);
        const phone = userRes.rows[0].phone;
        const query = `DELETE FROM otp_tracking WHERE phone = $1 AND email = $2`;
        await pool.query(query, [phone, email]);
    },

    updateUserEmail: async (userId, email) => {
        const query = `UPDATE users SET email = $1 WHERE id = $2`;
        await pool.query(query, [email, userId]);
    }
};

module.exports = userRepository;