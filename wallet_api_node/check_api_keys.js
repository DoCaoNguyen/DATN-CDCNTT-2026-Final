const pool = require('./src/config/db');
async function run() {
    const res = await pool.query("SELECT * FROM merchant_api_keys WHERE api_key = 'pk_test_8d6be57030dcd85c496bd7b8'");
    console.log(res.rows);
    process.exit(0);
}
run();
