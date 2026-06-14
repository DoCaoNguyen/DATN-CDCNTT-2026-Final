require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function checkLogs() {
  try {
    const result = await pool.query('SELECT * FROM loyalty_sync_logs ORDER BY created_at DESC LIMIT 5;');
    console.log('Loyalty Sync Logs:');
    console.table(result.rows);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await pool.end();
  }
}

checkLogs();
