require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});
pool.query("SELECT user_id, COUNT(*) as count FROM notifications WHERE status='UNREAD' GROUP BY user_id").then(res => {
  console.log("UNREAD:", res.rows);
  return pool.query("SELECT user_id, COUNT(*) as count FROM notifications GROUP BY user_id");
}).then(res => {
  console.log("ALL:", res.rows);
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});
