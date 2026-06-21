require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function checkDB() {
    try {
        // 1. List all tables
        console.log('=== ALL TABLES ===');
        const tables = await pool.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        `);
        tables.rows.forEach(r => console.log('  -', r.table_name));

        // 2. Check merchants table columns
        console.log('\n=== MERCHANTS TABLE COLUMNS ===');
        const merchantCols = await pool.query(`
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'merchants' AND table_schema = 'public'
            ORDER BY ordinal_position;
        `);
        merchantCols.rows.forEach(r => console.log(`  - ${r.column_name} (${r.data_type}, nullable=${r.is_nullable})`));

        // 3. Check if webhook_logs table exists  
        console.log('\n=== WEBHOOK_LOGS TABLE CHECK ===');
        const webhookTable = await pool.query(`
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'webhook_logs' AND table_schema = 'public'
            ORDER BY ordinal_position;
        `);
        if (webhookTable.rows.length === 0) {
            console.log('  ❌ webhook_logs TABLE DOES NOT EXIST');
        } else {
            webhookTable.rows.forEach(r => console.log(`  - ${r.column_name} (${r.data_type}, nullable=${r.is_nullable})`));
        }

        // 4. Check payment_orders columns
        console.log('\n=== PAYMENT_ORDERS TABLE COLUMNS ===');
        const paymentCols = await pool.query(`
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'payment_orders' AND table_schema = 'public'
            ORDER BY ordinal_position;
        `);
        paymentCols.rows.forEach(r => console.log(`  - ${r.column_name} (${r.data_type}, nullable=${r.is_nullable})`));

        // 5. Check split_bill tables
        console.log('\n=== SPLIT_BILL TABLES CHECK ===');
        const splitTables = await pool.query(`
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name LIKE 'split%'
            ORDER BY table_name;
        `);
        if (splitTables.rows.length === 0) {
            console.log('  ❌ No split_bill tables found');
        } else {
            for (const t of splitTables.rows) {
                console.log(`\n  Table: ${t.table_name}`);
                const cols = await pool.query(`
                    SELECT column_name, data_type 
                    FROM information_schema.columns 
                    WHERE table_name = $1 AND table_schema = 'public'
                    ORDER BY ordinal_position;
                `, [t.table_name]);
                cols.rows.forEach(r => console.log(`    - ${r.column_name} (${r.data_type})`));
            }
        }

        // 6. Check merchant_api_keys columns  
        console.log('\n=== MERCHANT_API_KEYS TABLE COLUMNS ===');
        const makCols = await pool.query(`
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'merchant_api_keys' AND table_schema = 'public'
            ORDER BY ordinal_position;
        `);
        makCols.rows.forEach(r => console.log(`  - ${r.column_name} (${r.data_type}, nullable=${r.is_nullable})`));

        // 7. Check existing data in merchants
        console.log('\n=== MERCHANT DATA ===');
        const merchantData = await pool.query('SELECT * FROM merchants LIMIT 5');
        console.log('  Columns:', Object.keys(merchantData.rows[0] || {}));
        merchantData.rows.forEach(r => console.log('  Row:', JSON.stringify(r)));

    } catch (err) {
        console.error('Error:', err.message);
    } finally {
        await pool.end();
    }
}

checkDB();
