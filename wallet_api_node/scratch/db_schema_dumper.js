const pool = require('../src/config/db');
const fs = require('fs');
const path = require('path');

async function dumpSchema() {
    try {
        console.log('Querying database tables...');
        // Query public tables
        const tablesRes = await pool.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        `);
        
        let ddl = `-- Database Schema Backup\n-- Generated on ${new Date().toISOString()}\n\n`;
        
        for (let row of tablesRes.rows) {
            const tableName = row.table_name;
            ddl += `CREATE TABLE "${tableName}" (\n`;
            
            // Query columns
            const colsRes = await pool.query(`
                SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = $1
                ORDER BY ordinal_position;
            `, [tableName]);
            
            const colDefs = [];
            for (let col of colsRes.rows) {
                let def = `    "${col.column_name}" ${col.data_type.toUpperCase()}`;
                if (col.character_maximum_length) {
                    def += `(${col.character_maximum_length})`;
                }
                if (col.is_nullable === 'NO') {
                    def += ' NOT NULL';
                }
                if (col.column_default) {
                    def += ` DEFAULT ${col.column_default}`;
                }
                colDefs.push(def);
            }
            
            // Query constraints (e.g. primary key, foreign key, unique)
            // For a simpler backup, we can also query primary keys
            const pkRes = await pool.query(`
                SELECT c.column_name
                FROM information_schema.table_constraints tc 
                JOIN information_schema.key_column_usage c 
                  ON tc.constraint_name = c.constraint_name
                WHERE tc.table_schema = 'public' 
                  AND tc.table_name = $1 
                  AND tc.constraint_type = 'PRIMARY KEY';
            `, [tableName]);
            
            if (pkRes.rows.length > 0) {
                const pks = pkRes.rows.map(r => `"${r.column_name}"`).join(', ');
                colDefs.push(`    PRIMARY KEY (${pks})`);
            }
            
            ddl += colDefs.join(',\n') + '\n);\n\n';
        }
        
        // Query indexes
        const idxRes = await pool.query(`
            SELECT indexdef 
            FROM pg_indexes 
            WHERE schemaname = 'public'
              AND indexdef NOT LIKE '%_pkey%';
        `);
        
        if (idxRes.rows.length > 0) {
            ddl += `-- Indexes\n`;
            for (let idx of idxRes.rows) {
                ddl += `${idx.indexdef};\n`;
            }
        }

        const targetPath = 'd:/Do_An/wallet_app/lib/db_backup.sql';
        fs.writeFileSync(targetPath, ddl);
        console.log(`Schema successfully written to ${targetPath}`);
    } catch (e) {
        console.error('Failed to dump schema:', e);
    } finally {
        await pool.end();
    }
}

dumpSchema();
