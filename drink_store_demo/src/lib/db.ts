import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:02122003@localhost:5432/ewallet_core_db',
});

export const query = (text: string, params?: any[]) => pool.query(text, params);

export const initDB = async () => {
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
    await pool.query(createTableQuery);
    console.log('Database initialized successfully.');
  } catch (err) {
    console.error('Failed to initialize database', err);
  }
};
