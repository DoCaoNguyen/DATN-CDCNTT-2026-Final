const pool = require('../../config/db');

const otpRepository = {
    
    findOtp: async ({ phone, email, purpose }) => {
        if (!phone && !email) {
            return undefined;
        }

        let query = 'SELECT * FROM otp_tracking WHERE used_at IS NULL';
        const params = [];

        if (phone) { params.push(phone); query += ` AND phone = $${params.length}`; }
        if (email) { params.push(email); query += ` AND email = $${params.length}`; }
        if (purpose) { params.push(purpose); query += ` AND purpose = $${params.length}`; }
        
        const result = await pool.query(query, params);
        return result.rows[0]; 
    },

    
    upsertOtp: async (phone, email, otpHash, purpose = 'REGISTER') => {
        const { v7: uuidv7 } = require('uuid');
        const searchCol = phone ? 'phone' : 'email';
        const searchVal = phone || email;
        
        const existing = await pool.query(`SELECT id FROM otp_tracking WHERE ${searchCol} = $1`, [searchVal]);
        
        if (existing.rows.length > 0) {
            const query = `
                UPDATE otp_tracking 
                SET phone = $1, email = $2, otp_hash = $3, purpose = $4, failed_attempts = 0, locked_until = NULL, expired_at = NOW() + INTERVAL '5 minutes', created_at = NOW(), used_at = NULL
                WHERE ${searchCol} = $5
            `;
            await pool.query(query, [phone, email, otpHash, purpose, searchVal]);
        } else {
            const id = uuidv7();
            const query = `
                INSERT INTO otp_tracking (id, phone, email, otp_hash, purpose, failed_attempts, locked_until, expired_at, created_at)
                VALUES ($1, $2, $3, $4, $5, 0, NULL, NOW() + INTERVAL '5 minutes', NOW())
            `;
            await pool.query(query, [id, phone, email, otpHash, purpose]);
        }
    },

    updateAttempts: async (identifier, attempts) => {
        const searchCol = identifier.includes('@') ? 'email' : 'phone';
        const query = `UPDATE otp_tracking SET failed_attempts = $1 WHERE ${searchCol} = $2`;
        await pool.query(query, [attempts, identifier]);
    },

    lockAccount: async (identifier, attempts, lockMinutes) => {
        const searchCol = identifier.includes('@') ? 'email' : 'phone';
        const query = `
            UPDATE otp_tracking
            SET failed_attempts = $1,
                locked_until = NOW() + ($3::text || ' minutes')::interval
            WHERE ${searchCol} = $2
        `;
        await pool.query(query, [attempts, identifier, Number(lockMinutes)]);
    },

    deleteOtp: async (identifier) => {
        const searchCol = identifier.includes('@') ? 'email' : 'phone';
        await pool.query(`UPDATE otp_tracking SET used_at = NOW() WHERE ${searchCol} = $1`, [identifier]);
    }
};

module.exports = otpRepository;
