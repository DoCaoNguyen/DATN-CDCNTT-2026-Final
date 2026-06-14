require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function checkUnread() {
  const q = await pool.query("SELECT * FROM notifications WHERE status = 'UNREAD'");
  console.log("Unread count DB:", q.rowCount);
  process.exit(0);
}
checkUnread();
