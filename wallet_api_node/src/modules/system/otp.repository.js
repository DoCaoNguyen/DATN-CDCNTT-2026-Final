
const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const otpRepository = {
    
    findByPhone: async (phone) => {
        const result = await pool.query('SELECT * FROM otp_tracking WHERE phone = $1 ORDER BY created_at DESC LIMIT 1', [phone]);
        return result.rows[0]; 
    },

    
    upsertOtp: async (phone, email, otpCode) => {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            await client.query('DELETE FROM otp_tracking WHERE phone = $1', [phone]);
            const query = `
                INSERT INTO otp_tracking (id, phone, email, otp_hash, failed_attempts, locked_until, expired_at, created_at)
                VALUES ($1, $2, $3, $4, 0, NULL, NOW() + INTERVAL '5 minutes', NOW())
            `;
            await client.query(query, [uuidv7(), phone, email, otpCode]);
            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
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