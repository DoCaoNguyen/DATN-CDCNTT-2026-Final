const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const client = new Client({
    user: 'postgres',
    host: 'localhost',
    database: 'test',
    password: '123',
    port: 5432,
});

async function runSeed() {
    try {
        await client.connect();
        console.log("Connected to PostgreSQL DB.");

        const sql = fs.readFileSync(path.join(__dirname, 'db_init.sql')).toString();
        
        await client.query(sql);
        console.log("Database initialized successfully!");
    } catch (err) {
        console.error("Error initializing database:", err);
    } finally {
        await client.end();
    }
}

runSeed();
