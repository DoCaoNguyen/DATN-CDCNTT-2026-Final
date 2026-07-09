const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres:123456@localhost:5432/postgres',
});

async function createDb() {
  try {
    await client.connect();
    console.log('Connected to postgres database.');
    
    // Check if db exists
    const res = await client.query(`SELECT datname FROM pg_database WHERE datname = 'drink_store_db'`);
    if (res.rowCount === 0) {
      console.log('Creating database drink_store_db...');
      await client.query('CREATE DATABASE drink_store_db');
      console.log('Database drink_store_db created successfully.');
    } else {
      console.log('Database drink_store_db already exists.');
    }
  } catch (error) {
    console.error('Error creating database:', error);
  } finally {
    await client.end();
  }
}

createDb();
