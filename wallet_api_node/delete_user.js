require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'db',
    password: process.env.DB_PASSWORD || '123',
    port: process.env.DB_PORT || 5432,
});

async function main() {
    const phone = '0855313437';
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        
        const res = await client.query('SELECT id FROM users WHERE phone = $1', [phone]);
        if (res.rows.length === 0) {
            console.log('User not found');
            return;
        }
        const userId = res.rows[0].id;
        console.log('Found user:', userId);

        // Merchant related
        const resMerchant = await client.query('SELECT id FROM merchants WHERE phone = $1', [phone]);
        const merchantIds = resMerchant.rows.map(r => r.id);
        
        for (const mid of merchantIds) {
            console.log('Deleting merchant:', mid);
            await client.query('DELETE FROM payment_orders WHERE merchant_id = $1', [mid]);
            await client.query('DELETE FROM merchant_api_keys WHERE merchant_id = $1', [mid]);
            await client.query('DELETE FROM merchant_callback_configs WHERE merchant_id = $1', [mid]);
            await client.query('DELETE FROM payment_qr_codes WHERE merchant_id = $1', [mid]);
            await client.query('DELETE FROM merchant_balances WHERE merchant_id = $1', [mid]);
            await client.query('DELETE FROM merchant_users WHERE merchant_id = $1', [mid]);
            await client.query('DELETE FROM webhook_delivery_logs WHERE merchant_id = $1', [mid]);
            await client.query('DELETE FROM merchants WHERE id = $1', [mid]);
        }
        
        // Find wallet
        const resWallet = await client.query('SELECT id FROM wallets WHERE user_id = $1', [userId]);
        const walletIds = resWallet.rows.map(r => r.id);
        
        for (const wid of walletIds) {
            console.log('Deleting wallet:', wid);
            await client.query('DELETE FROM deposit_transactions WHERE wallet_id = $1', [wid]);
            await client.query('DELETE FROM payment_transactions WHERE payer_wallet_id = $1', [wid]);
            await client.query('DELETE FROM wallet_transfers WHERE sender_wallet_id = $1 OR receiver_wallet_id = $1', [wid]);
            await client.query('DELETE FROM withdrawal_transactions WHERE wallet_id = $1', [wid]);
            await client.query('DELETE FROM wallet_linked_banks WHERE wallet_id = $1', [wid]);
            await client.query('DELETE FROM wallet_limits WHERE wallet_id = $1', [wid]);
            await client.query('DELETE FROM loyalty_point_batches WHERE wallet_id = $1', [wid]);
            await client.query('DELETE FROM ledger_entries WHERE wallet_id = $1', [wid]);
            await client.query('DELETE FROM wallet_balances WHERE wallet_id = $1', [wid]);
            await client.query('DELETE FROM wallets WHERE id = $1', [wid]);
        }

        console.log('Deleting user...');
        await client.query('DELETE FROM user_devices WHERE user_id = $1', [userId]);
        await client.query('DELETE FROM refresh_tokens WHERE user_id = $1', [userId]);
        await client.query('DELETE FROM merchant_users WHERE user_id = $1', [userId]);
        await client.query('DELETE FROM notifications WHERE user_id = $1', [userId]);
        
        // Loyalty related
        await client.query('DELETE FROM wealth_bag_transactions WHERE user_id = $1', [userId]);
        await client.query('DELETE FROM user_wealth_bags WHERE user_id = $1', [userId]);
        await client.query('DELETE FROM user_linked_services WHERE user_id = $1', [userId]);

        await client.query('DELETE FROM user_roles WHERE user_id = $1', [userId]);
        await client.query('DELETE FROM users WHERE id = $1', [userId]);
        
        await client.query('COMMIT');
        console.log('Deleted user successfully!');
    } catch (e) {
        await client.query('ROLLBACK');
        console.error('Error:', e);
    } finally {
        client.release();
        pool.end();
    }
}
main();
