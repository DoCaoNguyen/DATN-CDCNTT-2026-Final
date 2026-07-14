const pool = require('../src/config/db');

async function createTable() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS admin_notifications (
                id UUID PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                type VARCHAR(50) NOT NULL DEFAULT 'INFO',
                is_read BOOLEAN NOT NULL DEFAULT FALSE,
                link VARCHAR(255),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
            
            -- Create an index for faster querying by is_read and created_at
            CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read_created_at ON admin_notifications (is_read, created_at DESC);
        `);
        console.log("Table admin_notifications created successfully!");
    } catch (err) {
        console.error("Error creating table:", err);
    } finally {
        pool.end();
    }
}

createTable();
