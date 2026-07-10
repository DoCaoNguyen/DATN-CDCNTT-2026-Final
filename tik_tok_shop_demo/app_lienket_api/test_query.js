const pool = require('./src/config/db');
require('dotenv').config();

async function test() {
    try {
        const user_id = 1;
        const linkedWallet = await pool.query(
            `SELECT wallet_account FROM user_linked_wallets 
             WHERE user_id = $1 AND wallet_name = 'Mio' AND status = 'ACTIVE' LIMIT 1`, 
            [user_id]
        );
        console.log("linkedWallet rows:", linkedWallet.rows);
    } catch (e) {
        console.error(e);
    }
    process.exit(0);
}
test();
