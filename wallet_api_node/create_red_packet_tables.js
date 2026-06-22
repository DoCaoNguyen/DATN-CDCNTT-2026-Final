const pool = require('./src/config/db');

const createTables = async () => {
    try {
        await pool.query('BEGIN');

        // Create red_packets table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS red_packets (
                id UUID PRIMARY KEY,
                creator_wallet_id UUID NOT NULL REFERENCES wallets(id),
                total_amount BIGINT NOT NULL,
                remaining_amount BIGINT NOT NULL,
                total_count INT NOT NULL,
                remaining_count INT NOT NULL,
                type VARCHAR(20) NOT NULL, -- 'RANDOM', 'EQUAL'
                status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'EXHAUSTED', 'REFUNDED'
                message TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP
            );
        `);

        // Create red_packet_receivers table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS red_packet_receivers (
                id UUID PRIMARY KEY,
                red_packet_id UUID NOT NULL REFERENCES red_packets(id),
                receiver_wallet_id UUID NOT NULL REFERENCES wallets(id),
                amount BIGINT NOT NULL,
                received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE (red_packet_id, receiver_wallet_id)
            );
        `);

        await pool.query('COMMIT');
        console.log("Tables created successfully.");
    } catch (error) {
        await pool.query('ROLLBACK');
        console.error("Error creating tables:", error);
    } finally {
        process.exit(0);
    }
};

createTables();
