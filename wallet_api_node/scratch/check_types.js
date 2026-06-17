const pool = require('../src/config/db');

pool.query(`SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_name IN ('merchants', 'payment_transactions', 'payment_orders') AND column_name = 'id'`, (err, res) => {
    if (err) console.error(err);
    else console.log(res.rows);
    pool.end();
});
