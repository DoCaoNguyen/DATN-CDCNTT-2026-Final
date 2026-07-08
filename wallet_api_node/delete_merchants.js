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
    const keepId = '019ef462-29f7-76c5-ad7d-ff8fab40b0f3';
    try {
        await pool.query('BEGIN');
        
        await pool.query('DELETE FROM payment_transactions WHERE payment_order_id IN (SELECT id FROM payment_orders WHERE merchant_id != $1)', [keepId]);
        await pool.query('DELETE FROM payment_qr_codes WHERE payment_order_id IN (SELECT id FROM payment_orders WHERE merchant_id != $1)', [keepId]);
        await pool.query('DELETE FROM payment_orders WHERE merchant_id != $1', [keepId]);
        await pool.query('DELETE FROM merchant_api_keys WHERE merchant_id != $1', [keepId]);
        await pool.query('DELETE FROM merchant_users WHERE merchant_id != $1', [keepId]);
        await pool.query('DELETE FROM merchant_balances WHERE merchant_id != $1', [keepId]);
        await pool.query('DELETE FROM merchant_callback_configs WHERE merchant_id != $1', [keepId]);
        
        const res = await pool.query('DELETE FROM merchants WHERE id != $1 RETURNING id', [keepId]);
        
        await pool.query('COMMIT');
        console.log(`Đã xóa ${res.rowCount} merchants.`);
    } catch (e) {
        await pool.query('ROLLBACK');
        console.error("Lỗi xóa:", e);
    } finally {
        pool.end();
    }
}
main();
