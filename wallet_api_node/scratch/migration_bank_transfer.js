const pool = require('../src/config/db');

async function migrate() {
    try {
        console.log('Running bank transfer migration...');
        
        await pool.query(`
            ALTER TABLE withdrawal_transactions 
            ADD COLUMN IF NOT EXISTS bank_code VARCHAR(50) DEFAULT NULL;
        `);
        console.log('Added bank_code column.');

        await pool.query(`
            ALTER TABLE withdrawal_transactions 
            ADD COLUMN IF NOT EXISTS account_number VARCHAR(100) DEFAULT NULL;
        `);
        console.log('Added account_number column.');

        console.log('Bank transfer migration completed successfully!');
    } catch (e) {
        console.error('Migration failed:', e);
    } finally {
        await pool.end();
    }
}

migrate();
