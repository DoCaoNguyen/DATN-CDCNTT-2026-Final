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

    // --- MỚI THÊM CHO API LOGIN ---
    findByEmailOrPhone: async (identifier) => {
        const query = `
            SELECT id, email, phone, password_hash, role, status 
            FROM users 
            WHERE email = $1 OR phone = $1
        `;
        const result = await pool.query(query, [identifier]);
        return result.rows[0]; // Trả về thông tin user hoặc undefined nếu không tìm thấy
    }
};

module.exports = userRepository;