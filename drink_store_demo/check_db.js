const { Pool } = require('pg');
const pool = new Pool({ connectionString: 'postgresql://postgres:123456@localhost:5432/drink_store_db' });
pool.query("SELECT * FROM store_orders ORDER BY id DESC LIMIT 1").then(res => {
  console.log(res.rows);
  pool.end();
}).catch(err => {
  console.log(err);
  pool.end();
});
