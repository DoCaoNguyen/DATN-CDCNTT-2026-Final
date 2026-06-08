const pool = require('./src/config/db');
const notificationService = require('./src/modules/notification/notification.service');
const notificationRepository = require('./src/modules/notification/notification.repository');

async function runTest() {
    console.log('--- BẮT ĐẦU KIỂM TRA FCM PUSH NOTIFICATION SYSTEM ---');
    
    let testUserId = null;
    let dummyToken = 'd-u-m-m-y-t-o-k-e-n-' + Date.now();

    try {
        // 1. Tìm hoặc tạo một User ngẫu nhiên trong database để test
        const userResult = await pool.query('SELECT id FROM users LIMIT 1');
        if (userResult.rows.length === 0) {
            console.log('Database chưa có user nào. Tiến hành tạo user ảo để test...');
            const insertUserResult = await pool.query(`
                INSERT INTO users (id, password_hash, full_name, email, phone) 
                VALUES (gen_random_uuid(), 'hash', 'Test FCM User', 'testfcm@example.com', '0987654321')
                RETURNING id
            `);
            testUserId = insertUserResult.rows[0].id;
        } else {
            testUserId = userResult.rows[0].id;
            console.log(`Sử dụng User ID sẵn có để test: ${testUserId}`);
        }

        // 2. Đăng ký dummy device token vào bảng 'user_devices'
        console.log(`Đăng ký thiết bị test với Token: ${dummyToken}`);
        await notificationRepository.upsertDeviceToken(
            testUserId,
            dummyToken,
            'Test Device Emulator',
            'ANDROID'
        );

        // 3. Thực hiện gửi thông báo biến động số dư giả định
        console.log('Gửi thông báo biến động số dư...');
        const result = await notificationService.sendBalanceChangeNotification(
            testUserId,
            150000, // 150.000 VND
            'DEPOSIT'
        );

        console.log('Kết quả gửi thông báo:', result);

        // 4. Kiểm tra xem thông báo đã lưu vào lịch sử DB hay chưa
        const notificationCheck = await pool.query(
            'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
            [testUserId]
        );

        if (notificationCheck.rows.length > 0) {
            const savedNotif = notificationCheck.rows[0];
            console.log('Thông báo đã được ghi nhận vào bảng notifications thành công:');
            console.log(`- Title: ${savedNotif.title}`);
            console.log(`- Content: ${savedNotif.content}`);
            console.log(`- Status: ${savedNotif.status}`);
        } else {
            console.error('LỖI: Không tìm thấy bản ghi thông báo trong bảng notifications.');
        }

    } catch (error) {
        console.error('Gặp lỗi khi chạy test script:', error);
    } finally {
        // Dọn dẹp dữ liệu test
        if (testUserId) {
            console.log('Đang dọn dẹp dữ liệu test...');
            await pool.query('DELETE FROM user_devices WHERE fcm_token = $1', [dummyToken]);
        }
        await pool.end();
        console.log('--- KẾT THÚC KIỂM TRA ---');
    }
}

runTest();
