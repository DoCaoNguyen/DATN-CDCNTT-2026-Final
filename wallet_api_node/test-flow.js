const pool = require('./src/config/db');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const express = require('express');
require('dotenv').config();

const WEBHOOK_PORT = 9000;
const API_BASE_URL = 'http://localhost:8000/api/v1';

async function runTest() {
    console.log('====================================================');
    console.log('   BẮT ĐẦU CHẠY THỬ LUỒNG MERCHANT & WEBHOOK');
    console.log('====================================================');

    // 1. Khởi động một web server tạm thời để nhận Webhook Callback
    const app = express();
    app.use(express.json());

    let webhookReceivedPromise = new Promise((resolve) => {
        app.post('/webhook', (req, res) => {
            console.log('\n[TEST_RESULT] -> ĐÃ NHẬN ĐƯỢC WEBHOOK CALLBACK TỪ BACKEND!');
            console.log('Dữ liệu Webhook nhận được:', JSON.stringify(req.body, null, 2));
            res.status(200).send('OK');
            resolve(req.body);
        });
    });

    const server = app.listen(WEBHOOK_PORT, () => {
        console.log(`[TEST_SETUP] Đã khởi tạo server webhook ảo tại: http://localhost:${WEBHOOK_PORT}/webhook`);
    });

    try {
        // 2. Tìm người dùng mẫu và ví của họ từ Database
        const userResult = await pool.query(`
            SELECT u.id, u.token_version, u.role, w.id as wallet_id, wb.available_balance as balance 
            FROM users u 
            JOIN wallets w ON u.id = w.user_id 
            JOIN wallet_balances wb ON w.id = wb.wallet_id
            WHERE u.status = 'ACTIVE' 
            LIMIT 1
        `);

        if (userResult.rows.length === 0) {
            throw new Error('Không tìm thấy người dùng ACTIVE nào trong DB để test.');
        }

        const testUser = userResult.rows[0];
        console.log(`[TEST_SETUP] Tìm thấy User test ID: ${testUser.id}`);
        console.log(`            - Số dư ví hiện tại: ${testUser.balance} VND`);

        // Đảm bảo số dư ví đủ để test (nạp thêm tiền nếu số dư < 50k)
        if (parseInt(testUser.balance) < 50000) {
            console.log(`[TEST_SETUP] Số dư hiện tại dưới 50k. Đang tự động cộng 100k vào ví...`);
            await pool.query('UPDATE wallet_balances SET available_balance = available_balance + 100000 WHERE wallet_id = $1', [testUser.wallet_id]);
        }

        // 3. Ký mã JWT Access Token giả lập người dùng đăng nhập
        const jwtSecret = process.env.JWT_SECRET;
        const accessToken = jwt.sign(
            { userId: testUser.id, role: testUser.role, tokenVersion: testUser.token_version },
            jwtSecret,
            { expiresIn: '1h' }
        );
        console.log('[TEST_SETUP] Đã sinh mã JWT Access Token thành công.');

        // 4. Gọi API /payment/create để sinh hóa đơn & mã QR
        console.log('\n[TEST_STEP 1] Đang gọi API tạo hóa đơn (/payment/create)...');
        const createResponse = await axios.post(`${API_BASE_URL}/payment/create`, {
            amount: 50000,
            callback_url: `http://localhost:${WEBHOOK_PORT}/webhook`,
            description: "Thử nghiệm cổng thanh toán tự động"
        }, {
            headers: {
                'x-api-key': 'vipayment_key_test_123456',
                'Content-Type': 'application/json'
            }
        });

        const orderData = createResponse.data.data;
        console.log('Hóa đơn được tạo thành công:');
        console.log(`- Mã hóa đơn: ${orderData.order_code}`);
        console.log(`- QR Token: ${orderData.qr_token}`);

        // 5. Gọi API /payment/process để giả lập điện thoại quét QR & thanh toán
        console.log('\n[TEST_STEP 2] Đang gọi API thanh toán hóa đơn (/payment/process)...');
        const processResponse = await axios.post(`${API_BASE_URL}/payment/process`, {
            qr_token: orderData.qr_token
        }, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            }
        });

        console.log('Thanh toán thành công!');
        console.log('Chi tiết giao dịch trả về:', JSON.stringify(processResponse.data, null, 2));

        // 6. Đợi nhận webhook callback
        console.log('\n[TEST_STEP 3] Đang đợi Webhook được kích hoạt...');
        const webhookPayload = await Promise.race([
            webhookReceivedPromise,
            new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout: Quá 10s chưa nhận được Webhook.')), 10000))
        ]);

        console.log('\n====================================================');
        console.log('       KẾT QUẢ KIỂM THỬ: THÀNH CÔNG RỰC RỠ!');
        console.log('====================================================');
        console.log(`Trạng thái Webhook: ${webhookPayload.status}`);
        console.log(`Mã đơn hàng: ${webhookPayload.order_id}`);
        console.log(`Số tiền thanh toán: ${webhookPayload.amount} VND`);
    } catch (error) {
        console.log('\n====================================================');
        console.log('       KẾT QUẢ KIỂM THỬ: THẤT BẠI!');
        console.log('====================================================');
        if (error.response) {
            console.error('Lỗi API trả về:', error.response.status, error.response.data);
        } else {
            console.error('Lỗi kiểm thử:', error.message);
        }
    } finally {
        // Đóng server webhook và kết nối DB
        server.close();
        await pool.end();
        console.log('\nĐã dọn dẹp tài nguyên test.');
    }
}

runTest();
