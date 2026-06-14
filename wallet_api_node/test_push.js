require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function runTest() {
  const notificationService = require('./src/modules/notification/notification.service');
  
  // Lấy 2 user bất kỳ
  const res = await pool.query("SELECT id, phone, full_name FROM users LIMIT 2");
  if (res.rows.length < 2) return console.log("Not enough users");
  const userA = res.rows[0];
  const userB = res.rows[1];

  try {
      const result = await notificationService.sendChatMessageNotification(
          userB.id,
          userA.full_name || 'Test User A',
          'Hello, this is a push notification test from Backend!'
      );
      console.log('Result:', result);
  } catch (err) {
      console.error('Error:', err);
  } finally {
      pool.end();
  }
}

runTest();
