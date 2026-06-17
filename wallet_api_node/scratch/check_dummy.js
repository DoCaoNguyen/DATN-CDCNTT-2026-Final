const { Pool } = require('pg');
const pool = new Pool({ user: 'postgres', password: '123', database: 'wallet_dummy' });
pool.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public'").then(r => console.log('Tables:', r.rows)).catch(e=>console.log(e.message)).finally(() => pool.end());
