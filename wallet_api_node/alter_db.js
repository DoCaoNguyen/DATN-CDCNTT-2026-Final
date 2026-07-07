require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'mio_wallet',
    password: process.env.DB_PASSWORD || '123456',
    port: process.env.DB_PORT || 5432,
});

async function main() {
    try {
        await pool.query(`
            ALTER TABLE merchant_balances 
            ADD COLUMN IF NOT EXISTS daily_withdraw_usage NUMERIC DEFAULT 0,
            ADD COLUMN IF NOT EXISTS last_withdraw_date DATE;
        `);
        console.log("Thêm cột thành công!");
    } catch (e) {
        console.error("Lỗi:", e);
    } finally {
        pool.end();
    }
}
main();
