const pool = require('./src/config/db');
pool.query("SELECT * FROM chat_messages")
  .then(res => { console.log("Chat Messages:", res.rows); pool.end(); })
  .catch(err => { console.error("Error:", err); pool.end(); });
