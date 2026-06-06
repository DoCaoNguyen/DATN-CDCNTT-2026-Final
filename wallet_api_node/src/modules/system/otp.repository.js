
const pool = require('../../config/db');

const otpRepository = {
    
    findByPhone: async (phone) => {
        const result = await pool.query('SELECT * FROM otp_tracking WHERE phone = $1', [phone]);
        return result.rows[0]; 
    },

    
    upsertOtp: async (phone, email, otpCode) => {
        const query = `
            INSERT INTO otp_tracking (phone, email, otp_code, failed_attempts, locked_until, expired_at, created_at)
            VALUES ($1, $2, $3, 0, NULL, NOW() + INTERVAL '5 minutes', NOW())
            ON CONFLICT (phone) DO UPDATE SET
                email = EXCLUDED.email,
                otp_code = EXCLUDED.otp_code,
                failed_attempts = 0,
                locked_until = NULL,
                expired_at = EXCLUDED.expired_at,
                created_at = EXCLUDED.created_at;
        `;
        await pool.query(query, [phone, email, otpCode]);
    },

    
    updateAttempts: async (phone, attempts) => {
        const query = "UPDATE otp_tracking SET failed_attempts = $1 WHERE phone = $2";
        await pool.query(query, [attempts, phone]);
    },

    
    lockAccount: async (phone, attempts, lockMinutes) => {
        const query = `UPDATE otp_tracking SET failed_attempts = $1, locked_until = NOW() + INTERVAL '${lockMinutes} minutes' WHERE phone = $2`;
        await pool.query(query, [attempts, phone]);
    },

    
    deleteByPhone: async (phone) => {
        await pool.query('DELETE FROM otp_tracking WHERE phone = $1', [phone]);
    }
};

module.exports = otpRepository;