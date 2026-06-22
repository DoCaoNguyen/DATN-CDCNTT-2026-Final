require('dotenv').config();
const fs = require('fs');
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
});

async function dumpSchema() {
  try {
    const query = `
      SELECT table_name, column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      ORDER BY table_name, ordinal_position;
    `;
    const res = await pool.query(query);
    const schema = {};
    res.rows.forEach(row => {
      if (!schema[row.table_name]) schema[row.table_name] = [];
      schema[row.table_name].push(`${row.column_name} (${row.data_type})`);
    });
    
    let out = '';
    for (const [table, columns] of Object.entries(schema)) {
      out += `TABLE: ${table}\n`;
      columns.forEach(col => out += `  - ${col}\n`);
      out += '\n';
    }
    fs.writeFileSync('schema_dump.txt', out);
    console.log('Schema written to schema_dump.txt');
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}

dumpSchema();
