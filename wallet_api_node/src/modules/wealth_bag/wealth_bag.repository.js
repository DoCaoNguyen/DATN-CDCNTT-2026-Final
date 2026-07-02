const pool = require('../../config/db');

const wealthBagRepository = {
    getWealthBagStatus: async (userId) => {
        const query = 'SELECT * FROM user_wealth_bags WHERE user_id = $1';
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    activateWealthBag: async (userId) => {
        const query = `
            INSERT INTO user_wealth_bags (user_id, balance, total_profit, is_active)
            VALUES ($1, 0, 0, true)
            ON CONFLICT (user_id) 
            DO UPDATE SET is_active = true, updated_at = CURRENT_TIMESTAMP
            RETURNING *;
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },
};

module.exports = wealthBagRepository;
