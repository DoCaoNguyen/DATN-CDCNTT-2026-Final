const pool = require('./src/config/db');
pool.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'merchant_api_keys'").then(res => {
    console.log(res.rows.map(r => r.column_name));
    pool.end();
});
