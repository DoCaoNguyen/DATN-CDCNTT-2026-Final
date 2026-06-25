const pool = require('./src/config/db');
pool.query("SELECT column_name, is_nullable, data_type FROM information_schema.columns WHERE table_name = 'idempotency_keys'").then(res => {
    console.log(res.rows);
    pool.end();
});
