require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function testMarkAsRead() {
  const userId = '4c04088f-2f20-4a9d-bbba-2a26a94254f1';
  const notificationIds = ['fa369381-c870-44a4-8f6c-cfcdc9f6f734'];
  const query = `
      UPDATE notifications
      SET status = 'READ', updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $1 AND id = ANY($2::uuid[])
  `;
  const result = await pool.query(query, [userId, notificationIds]);
  console.log("Updated rows:", result.rowCount);
  process.exit(0);
}
testMarkAsRead();
