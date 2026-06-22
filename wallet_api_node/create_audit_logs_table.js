require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
});

async function createTable() {
  const query = `
    CREATE TABLE IF NOT EXISTS audit_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      trace_id VARCHAR(100),
      actor_type VARCHAR(50),
      actor_id UUID,
      action VARCHAR(100) NOT NULL,
      entity_type VARCHAR(100),
      entity_id UUID,
      old_data JSONB,
      new_data JSONB,
      metadata JSONB,
      reason TEXT,
      ip_address VARCHAR(50),
      user_agent VARCHAR(255),
      created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  `;
  try {
    await pool.query(query);
    console.log("Table audit_logs created successfully!");
  } catch (err) {
    console.error("Error creating table:", err);
  } finally {
    pool.end();
  }
}

createTable();
