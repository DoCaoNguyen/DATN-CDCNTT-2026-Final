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
    const userId = '019f3ba9-af5f-7212-9061-919936f1d1ea';
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        
        await client.query('DELETE FROM user_kyc WHERE user_id = $1', [userId]);
        await client.query('UPDATE users SET is_kyc_verified = false WHERE id = $1', [userId]);
        
        await client.query('COMMIT');
        console.log('Deleted KYC for user successfully!');
    } catch (e) {
        await client.query('ROLLBACK');
        console.error('Error:', e);
    } finally {
        client.release();
        pool.end();
    }
}
main();
