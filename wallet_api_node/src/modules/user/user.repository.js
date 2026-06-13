const pool = require('../../config/db'); 

const userRepository = {
    searchUsers: async (searchQuery, currentUserId) => {
        const query = `
            SELECT u.id, u.full_name, u.phone, u.email
            FROM users u
            JOIN wallets w ON u.id = w.user_id
            WHERE u.id != $1 
              AND (u.phone ILIKE $2 OR u.full_name ILIKE $2 OR u.email ILIKE $2)
            LIMIT 20
        `;
        
        const result = await pool.query(query, [currentUserId, `%${searchQuery}%`]);
        return result.rows;
    },

    getUserProfile: async (userId) => {
        const query = `
            SELECT u.full_name, u.phone, k.id_number
            FROM users u
            LEFT JOIN user_kyc k ON u.id = k.user_id
            WHERE u.id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getAllUsers: async () => {
        const query = 'SELECT id, full_name, phone, email, role, status, created_at FROM users ORDER BY created_at DESC';
        const result = await pool.query(query);
        return result.rows;
    },

    getUserById: async (userId) => {
        const query = 'SELECT id, full_name, phone, email, role, status, created_at FROM users WHERE id = $1';
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    }

    
};

module.exports = userRepository;