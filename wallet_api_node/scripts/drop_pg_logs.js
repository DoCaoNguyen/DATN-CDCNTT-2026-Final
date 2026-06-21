require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function dropLogTables() {
    try {
        console.log('Đang xóa các bảng log cũ trong PostgreSQL...');
        await pool.query('DROP TABLE IF EXISTS system_logs CASCADE;');
        console.log('Xóa thành công: system_logs');
        
        await pool.query('DROP TABLE IF EXISTS audit_logs CASCADE;');
        console.log('Xóa thành công: audit_logs');
        
        await pool.query('DROP TABLE IF EXISTS webhook_logs CASCADE;');
        console.log('Xóa thành công: webhook_logs');
        
        console.log('Hoàn tất việc xóa bảng.');
    } catch (e) {
        console.error('Lỗi khi xóa bảng:', e);
    } finally {
        await pool.end();
    }
}

dropLogTables();
