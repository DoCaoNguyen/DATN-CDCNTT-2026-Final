const express = require('express');
const pool = require('../src/config/db');
const webhookPublisher = require('../src/modules/webhook/webhook.publisher');
const webhookService = require('../src/modules/webhook/webhook.service');
const crypto = require('crypto');
const { v7: uuidv7 } = require('uuid');

const app = express();
app.use(express.json());

// 1. Tạo một server giả (Mock Merchant Server) để nhận Webhook
app.post('/merchant-webhook', (req, res) => {
    console.log('\n--- 📩 [MERCHANT SERVER] NHẬN ĐƯỢC WEBHOOK ---');
    console.log('Headers:', req.headers);
    console.log('Body:', req.body);

    // Xác thực chữ ký số (Verify HMAC Signature)
    const secretKey = 'test_secret_key_123';
    const expectedSignature = crypto
        .createHmac('sha256', secretKey)
        .update(JSON.stringify(req.body))
        .digest('hex');

    const receivedSignature = req.headers['x-webhook-signature'];

    if (expectedSignature === receivedSignature) {
        console.log('✅ Chữ ký hợp lệ! Đây đúng là Webhook từ hệ thống.');
        // Giả lập trả về 200 OK
        return res.status(200).json({ message: 'Success' });
        
        // MẸO: Bạn có thể đổi dòng trên thành res.status(500) để test cơ chế tự động gọi lại (Retry)
        // return res.status(500).json({ message: 'Internal Server Error' });
    } else {
        console.log('❌ Chữ ký KHÔNG hợp lệ!');
        return res.status(403).json({ message: 'Invalid Signature' });
    }
});

const PORT = 3001;
app.listen(PORT, async () => {
    console.log(`\n🚀 [MERCHANT SERVER] Đang chạy tại http://localhost:${PORT}/merchant-webhook`);

    try {
        // 2. Tạo một Merchant giả định trong DB để test
        const merchantId = uuidv7();
        const txId = uuidv7();

        console.log('⏳ Đang tạo Merchant giả định và Transaction trong Database...');
        await pool.query(`
            INSERT INTO merchants (id, merchant_name, callback_url, secret_key) 
            VALUES ($1, 'Test Merchant', 'http://localhost:${PORT}/merchant-webhook', 'test_secret_key_123')
        `, [merchantId]);

        await pool.query(`
            INSERT INTO payment_transactions (id, amount, status) 
            VALUES ($1, 50000, 'SUCCESS')
        `, [txId]);

        // 3. Tạo một bản ghi log pending
        const webhookPayload = {
            order_id: 'ORDER_TEST_01',
            status: 'success',
            amount: '50000',
            wallet_transaction_id: txId
        };
        const idempotencyKey = `wh_test_${Date.now()}`;

        const logId = await webhookService.createLog(pool, merchantId, txId, idempotencyKey, webhookPayload);

        console.log(`✅ Đã tạo Log Webhook với ID: ${logId}. Bắt đầu đẩy vào Message Queue...`);

        // 4. Bắn thử Webhook qua Queue
        await webhookPublisher.publish({
            logId: logId,
            merchantId: merchantId,
            payload: webhookPayload
        });

        console.log('🎯 Đã đẩy vào Queue. Vui lòng mở Terminal chạy "node server" để xem Worker xử lý và Terminal này để xem Merchant nhận dữ liệu!');
        
    } catch (err) {
        console.error('Lỗi khi set up test data:', err);
    }
});
