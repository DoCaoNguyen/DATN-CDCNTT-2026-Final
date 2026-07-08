const pool = require('../config/db');
const axios = require('axios');

// Thông tin API Key của Merchant TikTok Shop (Vừa tạo ở bước trước)
const MIO_API_URL = process.env.MIO_API_URL || 'http://localhost:3000/api/v1/merchant/charge';

const OrderController = {
    checkout: async (req, res) => {
        try {
            const { user_id, amount, order_id, api_key } = req.body;
            
            // 1. Lấy thông tin ví đã liên kết của User trên TikTok Shop
            const linkedWallet = await pool.query(
                `SELECT wallet_account FROM user_linked_wallets 
                 WHERE user_id = $1 AND wallet_name = 'Mio' AND status = 'ACTIVE' LIMIT 1`, 
                [user_id]
            );

            if (linkedWallet.rows.length === 0) {
                return res.status(400).json({ success: false, message: 'Bạn chưa liên kết ví thanh toán' });
            }

            const walletAccount = linkedWallet.rows[0].wallet_account;

            // 2. Ra lệnh trừ tiền qua API của Ví Mio (Server-to-Server)
            try {
                const response = await axios.post(MIO_API_URL, {
                    api_key: api_key || process.env.MERCHANT_API_KEY,
                    merchant_code: 'MC_TIKTOK',
                    wallet_token: walletAccount, // walletAccount ở đây đang chứa token JWT
                    amount: amount,
                    order_id: order_id || 'TTS_' + Date.now()
                });

                if (response.data.success) {
                    return res.status(200).json({ 
                        success: true, 
                        message: 'Thanh toán thành công',
                        data: response.data.data
                    });
                }
            } catch (mioError) {
                console.error('Lỗi khi gọi API Ví Mio:', mioError.response?.data || mioError.message);
                const errorMsg = mioError.response?.data?.error || 'Thanh toán thất bại từ cổng thanh toán';
                
                // Nếu lỗi là 403, chứng tỏ ví đã bị hủy liên kết, tự động đồng bộ trạng thái nội bộ
                if (mioError.response?.status === 403) {
                    await pool.query(
                        "UPDATE user_linked_wallets SET status = 'UNLINKED' WHERE user_id = $1 AND wallet_name = 'Mio'", 
                        [user_id]
                    );
                }
                
                return res.status(400).json({ success: false, message: errorMsg });
            }
        } catch (error) {
            console.error('Lỗi Checkout:', error);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    }
};

module.exports = OrderController;
