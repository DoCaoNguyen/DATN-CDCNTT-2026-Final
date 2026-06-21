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
        console.log('Đang thực thi lệnh Alter Database...');
        
        // Add user_id column
        await pool.query(`
            ALTER TABLE merchants 
            ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;
        `);
        
        console.log('Thêm cột user_id vào merchants thành công.');
    } catch (e) {
        console.error('Lỗi:', e);
    } finally {
        await pool.end();
    }
}

run();
