// File: src/repositories/otp.repository.js
const pool = require('../config/db');

const otpRepository = {
    // 1. Tìm thông tin OTP theo số điện thoại
    findByPhone: async (phone) => {
        const result = await pool.query('SELECT * FROM otp_tracking WHERE phone = $1', [phone]);
        return result.rows[0]; // Trả về undefined nếu không có
    },

    // 2. Thêm mới hoặc Cập nhật OTP (Upsert)
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

    // 3. Cập nhật số lần nhập sai
    updateAttempts: async (phone, attempts) => {
        const query = "UPDATE otp_tracking SET failed_attempts = $1 WHERE phone = $2";
        await pool.query(query, [attempts, phone]);
    },

    // 4. Khóa tài khoản trong X phút
    lockAccount: async (phone, attempts, lockMinutes) => {
        const query = `UPDATE otp_tracking SET failed_attempts = $1, locked_until = NOW() + INTERVAL '${lockMinutes} minutes' WHERE phone = $2`;
        await pool.query(query, [attempts, phone]);
    },

    // 5. Xóa lịch sử OTP sau khi xác thực thành công
    deleteByPhone: async (phone) => {
        await pool.query('DELETE FROM otp_tracking WHERE phone = $1', [phone]);
    }
};

module.exports = otpRepository;