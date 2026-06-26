require('dotenv').config({ path: '.env.local' });
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:123@localhost:5432/test',
});

const initDB = async () => {
  const dropTableQuery = `DROP TABLE IF EXISTS store_orders;`;
  const createTableQuery = `
    CREATE TABLE IF NOT EXISTS store_orders (
        id SERIAL PRIMARY KEY,
        product_name VARCHAR(255) NOT NULL,
        amount INT NOT NULL,
        status VARCHAR(50) DEFAULT 'PENDING',
        qr_token VARCHAR(255),
        merchant_order_id VARCHAR(255) UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;
  try {
    await pool.query(dropTableQuery);
    await pool.query(createTableQuery);
    console.log('Database initialized successfully.');
  } catch (err) {
    console.error('Failed to initialize database', err);
  } finally {
    pool.end();
  }
};

initDB();
