require('dotenv').config(); 
const {Pool} = require('pg'); 
const pool = new Pool({
    user: process.env.DB_USER, 
    host: process.env.DB_HOST, 
    database: process.env.DB_NAME, 
    password: process.env.DB_PASSWORD, 
    port: process.env.DB_PORT
}); 

pool.query("SELECT COUNT(*) FROM ledger_entries WHERE system_account_code = 'SYS_FEE_MDR'", (err, res) => {
    console.log(err ? err : res.rows); 
    pool.end();
});
