const pool = require('../src/config/db');

async function createTable() {
    const query = `
        CREATE TABLE IF NOT EXISTS wealth_bag_transactions (
            id UUID PRIMARY KEY,
            user_id UUID REFERENCES users(id),
            transaction_type VARCHAR(50),
            amount NUMERIC(20,2),
            balance_after NUMERIC(20,2),
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `;
    try {
        await pool.query(query);
        console.log("Table wealth_bag_transactions created successfully.");
    } catch (err) {
        console.error("Error creating table:", err);
    } finally {
        pool.end();
    }
}

createTable();
