const pool = require('./src/config/db');
pool.query("SELECT code FROM permissions").then(res => { 
  console.log('All permissions:', res.rows.map(r => r.code)); 
  process.exit(0); 
}).catch(console.error);
