const pool = require('./src/config/db');

async function runCleanup() {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        console.log('Starting cleanup process...');

        const merchantsRes = await client.query('SELECT id, merchant_name FROM merchants');
        const merchants = merchantsRes.rows;

        let totalRevoked = 0;

        for (const merchant of merchants) {
            // Fetch all ACTIVE keys ordered by created_at DESC (newest first)
            const keysRes = await client.query(`
                SELECT * FROM merchant_api_keys 
                WHERE merchant_id = $1 AND status = 'ACTIVE' 
                ORDER BY created_at DESC
            `, [merchant.id]);
            const activeKeys = keysRes.rows;

            const seenEnv = new Set();

            for (const key of activeKeys) {
                if (!seenEnv.has(key.environment)) {
                    // Keep the newest ACTIVE key for this environment
                    seenEnv.add(key.environment);
                    console.log(`- Keeping newest ACTIVE ${key.environment} key: ${key.id} for merchant ${merchant.merchant_name}`);
                } else {
                    // Revoke older ACTIVE keys for this environment
                    console.log(`- Revoking duplicate older ACTIVE ${key.environment} key: ${key.id} for merchant ${merchant.merchant_name}`);
                    await client.query(`UPDATE merchant_api_keys SET status = 'REVOKED', revoked_at = NOW() WHERE id = $1`, [key.id]);
                    totalRevoked++;
                }
            }
        }

        console.log(`Cleanup complete. Revoked ${totalRevoked} duplicate ACTIVE keys.`);

        // Add the unique partial index
        console.log('Adding unique partial index uq_merchant_api_keys_active_env...');
        await client.query(`
            CREATE UNIQUE INDEX IF NOT EXISTS uq_merchant_api_keys_active_env 
            ON merchant_api_keys (merchant_id, environment) 
            WHERE status = 'ACTIVE'
        `);
        console.log('Index created successfully.');

        await client.query('COMMIT');
        console.log('All changes committed successfully.');
    } catch (e) {
        await client.query('ROLLBACK');
        console.error('Error during cleanup:', e);
    } finally {
        client.release();
        pool.end();
    }
}

runCleanup();
