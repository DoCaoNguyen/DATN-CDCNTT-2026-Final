const pool = require('./src/config/db');
async function run() {
    const res = await pool.query('SELECT qr_token, status, used_at FROM payment_qr_codes LIMIT 5');
    console.log(res.rows);
    process.exit(0);
}
run();
