const pool = require('./src/config/db'); 

async function test() {
    try {
        // Link wallet
        console.log("Linking wallet...");
        const result = await pool.query(
            `INSERT INTO user_linked_wallets (user_id, wallet_name, wallet_account, masked_account, status) 
             VALUES ($1, $2, $3, $4, 'ACTIVE') 
             ON CONFLICT (user_id, wallet_name) 
             DO UPDATE SET wallet_account = EXCLUDED.wallet_account, masked_account = EXCLUDED.masked_account, status = 'ACTIVE', linked_at = CURRENT_TIMESTAMP
             RETURNING *`,
            [1, 'Mio', 'tok_abc', '1234']
        );
        console.log("Result 1:", result.rows);
        
        // Unlink wallet
        console.log("Unlinking wallet...");
        const res2 = await pool.query("UPDATE user_linked_wallets SET status = 'UNLINKED' WHERE user_id = $1 AND wallet_name = $2 RETURNING *", [1, 'Mio']);
        console.log("Result 2:", res2.rows);

        // Relink wallet
        console.log("Relinking wallet...");
        const res3 = await pool.query(
            `INSERT INTO user_linked_wallets (user_id, wallet_name, wallet_account, masked_account, status) 
             VALUES ($1, $2, $3, $4, 'ACTIVE') 
             ON CONFLICT (user_id, wallet_name) 
             DO UPDATE SET wallet_account = EXCLUDED.wallet_account, masked_account = EXCLUDED.masked_account, status = 'ACTIVE', linked_at = CURRENT_TIMESTAMP
             RETURNING *`,
            [1, 'Mio', 'tok_abc2', '1234']
        );
        console.log("Result 3:", res3.rows);

    } catch (e) {
        console.error(e);
    } finally {
        process.exit(0);
    }
}
test();
