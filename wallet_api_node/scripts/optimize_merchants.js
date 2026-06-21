require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function run() {
    try {
        console.log('Đang thực thi lệnh tối ưu Database...');
        
        // 1. Drop api_secret
        await pool.query(`
            ALTER TABLE merchant_api_keys 
            DROP COLUMN IF EXISTS api_secret;
        `);
        console.log('Xóa cột api_secret thành công.');

        // 2. Add Unique constraint cho user_id (Bỏ qua nếu đã tồn tại)
        try {
            await pool.query(`
                ALTER TABLE merchants 
                ADD CONSTRAINT merchants_user_id_key UNIQUE (user_id);
            `);
            console.log('Thêm ràng buộc UNIQUE(user_id) thành công.');
        } catch (e) {
            if (e.code === '42710') {
                console.log('Ràng buộc UNIQUE(user_id) đã tồn tại.');
            } else {
                throw e;
            }
        }

        // 3. Add Unique constraint cho api_key (Bỏ qua nếu đã tồn tại)
        try {
            await pool.query(`
                ALTER TABLE merchant_api_keys 
                ADD CONSTRAINT merchant_api_keys_api_key_key UNIQUE (api_key);
            `);
            console.log('Thêm ràng buộc UNIQUE(api_key) thành công.');
        } catch (e) {
            if (e.code === '42710') {
                console.log('Ràng buộc UNIQUE(api_key) đã tồn tại.');
            } else {
                throw e;
            }
        }

    } catch (e) {
        console.error('Lỗi:', e);
    } finally {
        await pool.end();
    }
}

run();
