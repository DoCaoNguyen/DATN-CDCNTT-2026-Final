const pool = require('../db');

const webhookController = {
    syncPoints: async (req, res) => {
        const { wallet_transaction_id, amount, phone_number } = req.body;

        if (!wallet_transaction_id || !amount || !phone_number) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // 1. Get user by phone number
            const userRes = await client.query('SELECT * FROM users WHERE phone_number = $1 FOR UPDATE', [phone_number]);
            if (userRes.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(404).json({ error: 'User not found in Loyalty system' });
            }
            const user = userRes.rows[0];

            // 2. Get active point rule
            const ruleRes = await client.query('SELECT * FROM point_rules WHERE active = true LIMIT 1');
            if (ruleRes.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(500).json({ error: 'No active point rule found' });
            }
            const rule = ruleRes.rows[0];

            // 3. Calculate points
            const earnedPoints = Math.floor(amount / rule.amount_per_point) * rule.points_earned;
            
            if (earnedPoints > 0) {
                // 4. Update user points
                const newTotalPoints = user.total_points + earnedPoints;
                
                // Calculate tier
                let newTier = 'SILVER';
                if (newTotalPoints >= 10000) newTier = 'VIP';
                else if (newTotalPoints >= 2000) newTier = 'GOLD';

                await client.query(
                    'UPDATE users SET total_points = $1, tier = $2 WHERE id = $3',
                    [newTotalPoints, newTier, user.id]
                );

                // 5. Write history
                await client.query(
                    'INSERT INTO loyalty_history (user_id, amount, points_earned, type, description) VALUES ($1, $2, $3, $4, $5)',
                    [user.id, amount, earnedPoints, 'EARN', `Earned from wallet tx: ${wallet_transaction_id}`]
                );
            }

            await client.query('COMMIT');

            res.status(200).json({
                message: 'Points synced successfully',
                earned_points: earnedPoints
            });
        } catch (error) {
            await client.query('ROLLBACK');
            console.error('Webhook sync error:', error);
            res.status(500).json({ error: 'Server error during point sync' });
        } finally {
            client.release();
        }
    }
};

module.exports = webhookController;
