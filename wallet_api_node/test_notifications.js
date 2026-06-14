require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function checkNotifications() {
  const q = await pool.query("SELECT id, status, user_id FROM notifications LIMIT 5");
  console.log("Notifications DB:", q.rows);
  process.exit(0);
}
checkNotifications();
