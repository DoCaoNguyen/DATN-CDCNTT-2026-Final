const fs = require('fs');
const pool = require('../src/config/db');

async function runMigration() {
    try {
        const sql = fs.readFileSync('./migrations/webhook_setup.sql', 'utf8');
        await pool.query(sql);
        console.log('Migration executed successfully.');
    } catch (err) {
        console.error('Migration failed:', err);
    } finally {
        pool.end();
    }
}

runMigration();
