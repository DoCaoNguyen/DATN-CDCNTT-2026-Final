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

    depositToWealthBag: async (userId, amount, source) => {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            if (source === 'wallet') {
                const walletQuery = 'SELECT id FROM wallets WHERE user_id = $1';
                const walletRes = await client.query(walletQuery, [userId]);
                if (walletRes.rows.length === 0) {
                    throw new Error('Wallet_Not_Found');
                }
                const walletId = walletRes.rows[0].id;

                const balanceQuery = 'SELECT available_balance FROM wallet_balances WHERE wallet_id = $1 FOR UPDATE';
                const balanceRes = await client.query(balanceQuery, [walletId]);
                
                if (balanceRes.rows.length === 0 || parseFloat(balanceRes.rows[0].available_balance) < parseFloat(amount)) {
                    throw new Error('Insufficient_Balance');
                }

                await client.query(
                    'UPDATE wallet_balances SET available_balance = available_balance - $1 WHERE wallet_id = $2',
                    [amount, walletId]
                );
            }

            const updateBagQuery = `
                UPDATE user_wealth_bags 
                SET balance = balance + $1, updated_at = CURRENT_TIMESTAMP
                WHERE user_id = $2 
                RETURNING *
            `;
            const bagRes = await client.query(updateBagQuery, [amount, userId]);
            
            if (bagRes.rows.length === 0) {
                throw new Error('Wealth_Bag_Not_Active');
            }

            await client.query('COMMIT');
            return bagRes.rows[0];
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },
};

module.exports = wealthBagRepository;
