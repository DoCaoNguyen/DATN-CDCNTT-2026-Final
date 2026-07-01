const pool = require('./src/config/db');
const crypto = require('crypto');

async function updateDb() {
    try {
        const merchantRes = await pool.query("SELECT id FROM merchants WHERE merchant_name ILIKE '%TikTok%'");
        if (merchantRes.rows.length > 0) {
            const mId = merchantRes.rows[0].id;
            const newId = crypto.randomUUID();
            await pool.query(`
                INSERT INTO merchant_callback_configs (id, merchant_id, default_callback_url, webhook_secret_hash) 
                VALUES ($1, $2, 'http://localhost:4000/api/v1/wallets/webhook/unlink', 'dummy_hash')
                ON CONFLICT (merchant_id) 
                DO UPDATE SET default_callback_url = EXCLUDED.default_callback_url
            `, [newId, mId]);
            console.log('Updated TikTok webhook URL');
        }
    } catch (e) {
        console.error(e);
    } finally {
        process.exit(0);
    }
}
updateDb();
