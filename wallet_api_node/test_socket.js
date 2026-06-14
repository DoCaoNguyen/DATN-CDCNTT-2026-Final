const io = require('socket.io-client');
const jwt = require('jsonwebtoken');
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
  // Lấy 2 user bất kỳ
  const res = await pool.query("SELECT id, phone FROM users LIMIT 2");
  if (res.rows.length < 2) return console.log("Not enough users");
  const userA = res.rows[0];
  const userB = res.rows[1];

  const token = jwt.sign(
      { userId: userA.id, role: 'USER' },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
  );

  const socket = io('http://localhost:8000', {
      transports: ['websocket'],
      auth: { token }
  });

  socket.on('connect', () => {
      console.log('Connected! ID:', socket.id);
      socket.emit('send_message', {
          receiverPhone: userB.phone,
          content: 'Hello this is a test message'
      });
  });

  socket.on('receive_message', (data) => {
      console.log('Received Message:', data);
      socket.disconnect();
      pool.end();
  });

  socket.on('error', (err) => {
      console.error('Socket Error:', err);
      socket.disconnect();
      pool.end();
  });

  socket.on('connect_error', (err) => {
      console.error('Connect Error:', err);
      pool.end();
  });
}

runTest();
