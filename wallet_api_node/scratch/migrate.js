require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function migrate() {
    try {
        // 1. Add merchant_order_id column to payment_orders
        console.log('Adding merchant_order_id column to payment_orders...');
        await pool.query(`
            ALTER TABLE payment_orders 
            ADD COLUMN IF NOT EXISTS merchant_order_id VARCHAR(255) DEFAULT NULL;
        `);
        console.log('✅ merchant_order_id column added');

        // 2. Create index for merchant query by order_code
        console.log('Creating indexes for merchant queries...');
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_payment_orders_order_code 
            ON payment_orders (order_code);
        `);
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_payment_orders_merchant_order_id 
            ON payment_orders (merchant_order_id);
        `);
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_payment_orders_merchant_id_status 
            ON payment_orders (merchant_id, status);
        `);
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id 
            ON payment_transactions (payment_order_id);
        `);
        console.log('✅ Indexes created');

        // Verify
        const cols = await pool.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'payment_orders' AND table_schema = 'public'
            ORDER BY ordinal_position;
        `);
        console.log('\n=== PAYMENT_ORDERS COLUMNS (after migration) ===');
        cols.rows.forEach(r => console.log(`  - ${r.column_name} (${r.data_type})`));

        console.log('\n✅ Migration complete!');
    } catch (err) {
        console.error('Migration error:', err.message);
    } finally {
        await pool.end();
    }
}

migrate();
