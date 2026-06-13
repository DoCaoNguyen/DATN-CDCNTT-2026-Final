const pool = require('./src/config/db');

async function checkDb() {
    try {
        console.log('--- KIỂM TRA DỮ LIỆU ĐĂNG KÝ THIẾT BỊ ---');
        const devices = await pool.query('SELECT * FROM user_devices');
        console.log(`Số thiết bị đã đăng ký: ${devices.rows.length}`);
        console.log(devices.rows);

        console.log('\n--- KIỂM TRA LỊCH SỬ THÔNG BÁO ---');
        const notifications = await pool.query('SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5');
        console.log(`Số thông báo trong lịch sử: ${notifications.rows.length}`);
        console.log(notifications.rows);
    } catch (e) {
        console.error('Lỗi truy vấn DB:', e);
    } finally {
        await pool.end();
    }
}

checkDb();
