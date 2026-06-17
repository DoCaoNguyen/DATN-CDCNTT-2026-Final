const pool = require('../src/config/db');

pool.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'merchants'`, (err, res) => {
    if (err) console.error(err);
    else console.log(res.rows.map(r => r.column_name));
    pool.end();
});
