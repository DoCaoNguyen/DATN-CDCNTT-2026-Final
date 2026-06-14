require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function checkUserUnread() {
  const q = await pool.query("SELECT user_id, COUNT(*) as count FROM notifications WHERE status = 'UNREAD' GROUP BY user_id");
  console.log("Unread by user:");
  console.table(q.rows);
  process.exit(0);
}
checkUserUnread();
