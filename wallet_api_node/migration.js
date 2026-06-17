const pool = require('./src/config/db');

async function migrate() {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Drop foreign keys
        await client.query(`
            ALTER TABLE split_bill_members DROP CONSTRAINT IF EXISTS split_bill_members_split_bill_id_fkey;
        `);

        // Alter columns to string/text first to preserve data
        // Then to UUID using cast
        await client.query(`
            ALTER TABLE split_bills ALTER COLUMN id DROP DEFAULT;
            ALTER TABLE split_bills ALTER COLUMN id TYPE UUID USING (
                '00000000-0000-0000-0000-' || LPAD(id::text, 12, '0')
            )::uuid;
        `);

        await client.query(`
            ALTER TABLE split_bill_members ALTER COLUMN id DROP DEFAULT;
            ALTER TABLE split_bill_members ALTER COLUMN id TYPE UUID USING (
                '00000000-0000-0000-0000-' || LPAD(id::text, 12, '0')
            )::uuid;
        `);

        await client.query(`
            ALTER TABLE split_bill_members ALTER COLUMN split_bill_id TYPE UUID USING (
                '00000000-0000-0000-0000-' || LPAD(split_bill_id::text, 12, '0')
            )::uuid;
        `);

        // Add back foreign key
        await client.query(`
            ALTER TABLE split_bill_members ADD CONSTRAINT split_bill_members_split_bill_id_fkey
            FOREIGN KEY (split_bill_id) REFERENCES split_bills(id) ON DELETE CASCADE;
        `);

        await client.query('COMMIT');
        console.log('Migration to UUID successful');
    } catch (e) {
        await client.query('ROLLBACK');
        console.error('Migration failed:', e);
    } finally {
        client.release();
        process.exit();
    }
}

migrate();
