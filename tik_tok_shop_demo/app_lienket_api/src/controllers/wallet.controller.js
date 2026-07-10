const pool = require('../config/db');

exports.getLinkedWallets = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            "SELECT wallet_name, wallet_account, masked_account, status, linked_at FROM user_linked_wallets WHERE user_id = $1 AND status = 'ACTIVE' ORDER BY linked_at DESC",
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

exports.handleUnlinkWebhook = async (req, res) => {
    try {
        const { event, wallet_account, service_name, timestamp } = req.body;
        
        if (event === 'USER_UNLINKED' && wallet_account) {
            const accountStr = String(wallet_account);
            const isToken = accountStr.startsWith('tok_mio_');
            
            // Tìm record theo wallet_account (token) hoặc masked_account (số điện thoại)
            const whereCol = isToken ? 'wallet_account = $1' : "masked_account LIKE '%' || $1";
            const param = isToken ? accountStr : (accountStr.length >= 4 ? accountStr.slice(-4) : accountStr);

            // FIX RACE CONDITION: Chỉ set UNLINKED nếu linked_at < timestamp webhook
            // Nếu user đã liên kết lại (linked_at mới hơn) → bỏ qua webhook cũ
            const timestampCondition = timestamp 
                ? ` AND linked_at < to_timestamp($2 / 1000.0)` 
                : '';
            const params = timestamp ? [param, timestamp] : [param];
            
            const query = `UPDATE user_linked_wallets SET status = 'UNLINKED' 
                           WHERE ${whereCol}${timestampCondition} RETURNING *`;
            
            const result = await pool.query(query, params);
            
            if (result.rows.length > 0) {
                console.log(`[WEBHOOK] Hủy liên kết thành công cho: ...${accountStr.slice(-20)}`);
            } else {
                console.log(`[WEBHOOK] Bỏ qua webhook cũ (user đã liên kết lại hoặc không khớp): ...${accountStr.slice(-20)}`);
            }
        }
        
        res.status(200).json({ success: true, message: 'Webhook received' });
    } catch (error) {
        console.error('Error in handleUnlinkWebhook:', error);
        res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
};
