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
    }
};

module.exports = userRepository;