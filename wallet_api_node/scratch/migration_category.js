const pool = require('../src/config/db');

async function migrate() {
    try {
        console.log('Running migration...');
        
        // Add category_name
        await pool.query(`
            ALTER TABLE ledger_transactions 
            ADD COLUMN IF NOT EXISTS category_name VARCHAR(255) DEFAULT NULL;
        `);
        console.log('Added category_name column.');

        // Add is_expense_counted
        await pool.query(`
            ALTER TABLE ledger_transactions 
            ADD COLUMN IF NOT EXISTS is_expense_counted BOOLEAN DEFAULT TRUE;
        `);
        console.log('Added is_expense_counted column.');

        console.log('Migration completed successfully!');
    } catch (e) {
        console.error('Migration failed:', e);
    } finally {
        await pool.end();
    }
}

migrate();
