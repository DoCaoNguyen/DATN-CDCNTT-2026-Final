const pool = require('../config/db');

const userRepository = {
    checkExists: async (email, phone) => {
        const query = 'SELECT id FROM users WHERE email = $1 OR phone = $2';
        const result = await pool.query(query, [email, phone]);
        return result.rows.length > 0;
    },

    create: async (client, email, phone, passwordHash) => {
        const query = `
            INSERT INTO users (email, phone, password_hash) 
            VALUES ($1, $2, $3) RETURNING id
        `;
        const result = await client.query(query, [email, phone, passwordHash]);
        return result.rows[0].id;
    },

    // Lấy thêm trường failed_login_attempts và locked_until
    findByEmailOrPhone: async (identifier) => {
        const query = `
            SELECT id, email, phone, password_hash, role, status, failed_login_attempts, locked_until, is_kyc_verified 
            FROM users 
            WHERE email = $1 OR phone = $1
        `;
        const result = await pool.query(query, [identifier]);
        return result.rows[0]; 
    },

    // --- MỚI THÊM: Cập nhật số lần đăng nhập sai và thời gian khóa ---
    updateFailedLogin: async (userId, attempts, lockMinutes = 0) => {
        let query;
        if (lockMinutes > 0) {
            query = `UPDATE users SET failed_login_attempts = $1, locked_until = NOW() + INTERVAL '${lockMinutes} minutes' WHERE id = $2`;
        } else {
            query = `UPDATE users SET failed_login_attempts = $1 WHERE id = $2`;
        }
        await pool.query(query, [attempts, userId]);
    },

    // --- MỚI THÊM: Xóa lịch sử đăng nhập sai nếu người dùng nhập đúng ---
    resetFailedLogin: async (userId) => {
        const query = `UPDATE users SET failed_login_attempts = 0, locked_until = NULL WHERE id = $1`;
        await pool.query(query, [userId]);
    },

    searchUsers: async (searchQuery, currentUserId) => {
        const query = `
            SELECT u.id, u.full_name, u.phone, u.email
            FROM users u
            JOIN wallets w ON u.id = w.user_id
            WHERE u.id != $1 
              AND (u.phone ILIKE $2 OR u.full_name ILIKE $2 OR u.email ILIKE $2)
            LIMIT 20
        `;
        // ILIKE giúp tìm kiếm không phân biệt chữ hoa/thường (chuẩn PostgreSQL)
        const result = await pool.query(query, [currentUserId, `%${searchQuery}%`]);
        return result.rows;
    }
};

module.exports = userRepository;