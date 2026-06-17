const pool = require('../db');
const axios = require('axios');

const staffController = {
    createOrder: async (req, res) => {
        const staffId = req.user.userId;
        const { amount, description } = req.body;

        if (!amount || amount <= 0) {
            return res.status(400).json({ error: 'Invalid amount' });
        }

        try {
            // Gọi sang Server Ví điện tử để tạo đơn và lấy mã QR chuẩn (vipayment://pay...)
            const walletRes = await axios.post('https://orectic-noctilucent-ronan.ngrok-free.dev/api/v1/payment/create', {
                amount: amount,
                description: description || 'Thanh toán Loyalty',
                callback_url: 'http://127.0.0.1:3001/api/v1/webhook/wallet/sync-points'
            }, {
                headers: {
                    'x-api-key': 'vipayment_key_test_123456'
                }
            });

            const qrPayloadStr = walletRes.data.data.qr_content; // QR Code thật của ví

            const txRes = await pool.query(
                'INSERT INTO transactions (staff_id, amount, description, qr_payload) VALUES ($1, $2, $3, $4) RETURNING *',
                [staffId, amount, description, qrPayloadStr]
            );

            res.status(201).json({
                message: 'Order created',
                data: txRes.rows[0]
            });
        } catch (error) {
            console.error('Create order error:', error);
            res.status(500).json({ error: 'Server error' });
        }
    },

    getHistory: async (req, res) => {
        const staffId = req.user.userId;
        try {
            const txRes = await pool.query(
                'SELECT * FROM transactions WHERE staff_id = $1 ORDER BY created_at DESC',
                [staffId]
            );
            res.status(200).json({ data: txRes.rows });
        } catch (error) {
            console.error('Get staff history error:', error);
            res.status(500).json({ error: 'Server error' });
        }
    }
};

module.exports = staffController;
