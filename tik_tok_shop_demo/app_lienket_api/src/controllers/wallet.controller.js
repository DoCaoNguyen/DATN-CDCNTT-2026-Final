const pool = require('../config/db');

exports.getLinkedWallets = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            'SELECT wallet_name, wallet_account, masked_account, status, linked_at FROM user_linked_wallets WHERE user_id = $1 ORDER BY linked_at DESC',
            [userId]
        );
        res.status(200).json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Error in getLinkedWallets:', error);
        res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
};

exports.linkWallet = async (req, res) => {
    try {
        const { user_id, wallet_name, wallet_account, masked_account } = req.body;
        
        if (!user_id || !wallet_name || !wallet_account) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        // Insert or update if exists
        const result = await pool.query(
            `INSERT INTO user_linked_wallets (user_id, wallet_name, wallet_account, masked_account, status) 
             VALUES ($1, $2, $3, $4, 'ACTIVE') 
             ON CONFLICT (user_id, wallet_name) 
             DO UPDATE SET wallet_account = EXCLUDED.wallet_account, masked_account = EXCLUDED.masked_account, status = 'ACTIVE', linked_at = CURRENT_TIMESTAMP
             RETURNING *`,
            [user_id, wallet_name, wallet_account, masked_account || wallet_account]
        );

        res.status(200).json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('Error in linkWallet:', error);
        res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
};
