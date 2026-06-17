const pool = require('../db');

const memberController = {
    getProfile: async (req, res) => {
        const userId = req.user.userId;
        try {
            const userRes = await pool.query(
                'SELECT id, phone_number, full_name, role, tier, total_points, created_at FROM users WHERE id = $1',
                [userId]
            );
            if (userRes.rows.length === 0) return res.status(404).json({ error: 'User not found' });
            res.status(200).json({ data: userRes.rows[0] });
        } catch (error) {
            res.status(500).json({ error: 'Server error' });
        }
    },

    getHistory: async (req, res) => {
        const userId = req.user.userId;
        try {
            const historyRes = await pool.query(
                'SELECT * FROM loyalty_history WHERE user_id = $1 ORDER BY created_at DESC',
                [userId]
            );
            res.status(200).json({ data: historyRes.rows });
        } catch (error) {
            res.status(500).json({ error: 'Server error' });
        }
    },

    getRewards: async (req, res) => {
        try {
            const rewardsRes = await pool.query('SELECT * FROM rewards ORDER BY points_required ASC');
            res.status(200).json({ data: rewardsRes.rows });
        } catch (error) {
            res.status(500).json({ error: 'Server error' });
        }
    }
};

module.exports = memberController;
