const pool = require('./src/config/db');
pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'refresh_tokens'")
  .then(res => { console.log(JSON.stringify(res.rows, null, 2)); pool.end(); })
  .catch(err => { console.error(err); pool.end(); });
