const { Pool } = require('pg');
require('dotenv').config();
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

pool.query(`
SELECT column_name, data_type, character_maximum_length 
FROM information_schema.columns 
WHERE table_name = 'notifications';
`)
.then(res => {
  console.log("Columns:", res.rows);
  pool.end();
})
.catch(err => {
  console.error("Error:", err);
  pool.end();
});
