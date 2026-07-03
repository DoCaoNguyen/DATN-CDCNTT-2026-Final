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
        const { event, wallet_account, service_name } = req.body;
        
        if (event === 'USER_UNLINKED' && wallet_account) {
            // Ép kiểu sang chuỗi để tránh lỗi .startsWith nếu webhook gửi dạng số
            const accountStr = String(wallet_account);
            
            // wallet_account từ webhook có thể là token chuẩn (tok_mio_...) hoặc số điện thoại (tương thích ngược)
            const isToken = accountStr.startsWith('tok_mio_');
            const query = isToken 
                ? "UPDATE user_linked_wallets SET status = 'UNLINKED' WHERE wallet_account = $1 RETURNING *"
                : "UPDATE user_linked_wallets SET status = 'UNLINKED' WHERE masked_account LIKE '%' || $1 RETURNING *";
            const param = isToken ? accountStr : (accountStr.length >= 4 ? accountStr.slice(-4) : accountStr);
            
            // Cập nhật trạng thái ví thành UNLINKED
            const result = await pool.query(query, [param]);
            
            if (result.rows.length > 0) {
                console.log(`[WEBHOOK] Đã hủy liên kết ví cho tài khoản: ${wallet_account}`);
            } else {
                console.log(`[WEBHOOK] Nhận yêu cầu hủy liên kết nhưng không tìm thấy tài khoản ví với đuôi/token: ${param}`);
            }
        }
        
        res.status(200).json({ success: true, message: 'Webhook received' });
    } catch (error) {
        console.error('Error in handleUnlinkWebhook:', error);
        res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
};
