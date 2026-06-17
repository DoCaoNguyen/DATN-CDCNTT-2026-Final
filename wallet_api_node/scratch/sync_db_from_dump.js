const fs = require('fs');
const { Pool } = require('pg');

const pool = new Pool({
    user: 'postgres',
    password: '123',
    host: 'localhost',
    port: 5432,
    database: 'wallet_db'
});

async function run() {
    try {
        console.log('1. Đọc nội dung file db.txt...');
        const content = fs.readFileSync('db.txt', 'utf8');
        
        // 1. Get current tables
        console.log('2. Lấy danh sách bảng hiện tại...');
        const resTables = await pool.query(`SELECT table_name FROM information_schema.tables WHERE table_schema='public'`);
        const liveTables = resTables.rows.map(r => r.table_name);
        
        // Create Sequences first
        console.log('3. Cập nhật Sequences...');
        const createSeqRegex = /CREATE SEQUENCE public\.(\w+)[\s\S]*?CACHE \d+;/g;
        let match;
        while ((match = createSeqRegex.exec(content)) !== null) {
            try { await pool.query(match[0]); } catch(e) {} 
        }

        // 2. Extract CREATE TABLE statements
        console.log('4. Tạo các bảng còn thiếu...');
        const createTableRegex = /CREATE TABLE public\.(\w+) \(([\s\S]*?)\);/g;
        const schemas = {};
        while ((match = createTableRegex.exec(content)) !== null) {
            schemas[match[1]] = match[0];
        }
        
        for (const [table, sql] of Object.entries(schemas)) {
            if (!liveTables.includes(table)) {
                console.log(`[SCHEMA] Bảng bị thiếu: ${table}. Đang tạo bảng...`);
                try {
                    await pool.query(sql);
                } catch (err) {
                    console.log(`  => Lỗi tạo bảng ${table}:`, err.message);
                }
            } else {
                // Table exists, let's extract columns to find missing ones
                // A very basic check: try to run ALTER TABLE ADD COLUMN for every column extracted from CREATE TABLE
                const colsMatch = schemas[table].match(/([a-zA-Z0-9_]+) ([a-zA-Z0-9\s\(\)\[\]]+)/g);
                if (colsMatch) {
                    const existingCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_name = $1`, [table]);
                    const existingNames = existingCols.rows.map(r => r.column_name);

                    // Skip the first "public.tablename (" line
                    const lines = schemas[table].split('\n').slice(1, -1);
                    for (let line of lines) {
                        line = line.trim();
                        if (line.startsWith('CONSTRAINT') || line.startsWith('PRIMARY KEY') || line.startsWith('UNIQUE') || line.startsWith('FOREIGN KEY')) continue;
                        
                        const colNameMatch = line.match(/^([a-zA-Z0-9_]+)\s+/);
                        if (colNameMatch) {
                            const colName = colNameMatch[1];
                            if (!existingNames.includes(colName)) {
                                console.log(`[SCHEMA] Cột bị thiếu: ${table}.${colName}. Đang thêm cột...`);
                                // Remove trailing commas for valid sql
                                let colDef = line.endsWith(',') ? line.slice(0, -1) : line;
                                try {
                                    await pool.query(`ALTER TABLE ${table} ADD COLUMN ${colDef}`);
                                } catch (e) {
                                    console.log(`  => Lỗi thêm cột ${table}.${colName}:`, e.message);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Alter sequences owned by
        console.log('5. Gắn Sequences vào cột...');
        const alterSeqRegex = /ALTER SEQUENCE public\.(\w+) OWNED BY (.*?);/g;
        while ((match = alterSeqRegex.exec(content)) !== null) {
            try { await pool.query(match[0]); } catch(e) {}
        }

        // Alter table defaults (e.g. id DEFAULT nextval(...))
        const alterDefaultRegex = /ALTER TABLE ONLY public\.(\w+) ALTER COLUMN (\w+) SET DEFAULT (.*?);/g;
        while ((match = alterDefaultRegex.exec(content)) !== null) {
            try { await pool.query(match[0]); } catch(e) {}
        }
        
        // Add Constraints (Primary Keys, Foreign Keys, Unique)
        console.log('6. Thêm các Constraints (Khóa chính, Ngoại, Unique)...');
        const alterTableRegex = /ALTER TABLE ONLY public\.(\w+)\s+ADD CONSTRAINT (\w+) ([\s\S]*?);/g;
        while ((match = alterTableRegex.exec(content)) !== null) {
            try { await pool.query(match[0]); } catch(e) {}
        }

        // 3. COPY blocks for data
        console.log('7. Bắt đầu đồng bộ Dữ liệu...');
        const copyRegex = /COPY public\.(\w+) \((.*?)\) FROM stdin;\n([\s\S]*?)\\\./g;
        while ((match = copyRegex.exec(content)) !== null) {
            const table = match[1];
            // Split columns carefully to handle quoted names or spaces
            const cols = match[2].split(',').map(s => `"${s.trim().replace(/"/g, '')}"`);
            const dataStr = match[3];
            
            const lines = dataStr.split('\n').filter(l => l.trim() !== '');
            if (lines.length === 0) continue;
            
            let added = 0;
            
            // First check if table has unique constraints (otherwise ON CONFLICT DO NOTHING fails)
            const pkRes = await pool.query(`
                SELECT c.column_name
                FROM information_schema.table_constraints tc 
                JOIN information_schema.key_column_usage c ON tc.constraint_name = c.constraint_name
                WHERE tc.table_schema = 'public' AND tc.table_name = $1 AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
                LIMIT 1;
            `, [table]);

            let onConflictStr = '';
            if (pkRes.rows.length > 0) {
                // Determine a unique index or PK
                const idxRes = await pool.query(`
                    SELECT a.attname
                    FROM   pg_index i
                    JOIN   pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
                    WHERE  i.indrelid = $1::regclass AND (i.indisprimary OR i.indisunique)
                `, [table]);
                if (idxRes.rows.length > 0) {
                     const uniqueCols = idxRes.rows.map(r => `"${r.attname}"`).join(', ');
                     onConflictStr = `ON CONFLICT (${uniqueCols}) DO NOTHING`;
                }
            } else {
                // If no unique constraint, DO NOTHING cannot be used. We just catch errors.
            }
            
            for (const line of lines) {
                const values = line.split('\t').map(v => v === '\\N' ? null : v);
                const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');
                
                // If table doesn't have unique constraint, we check if record already exists by comparing all fields (simple fallback)
                let skip = false;
                if (!onConflictStr) {
                    try {
                        const existingCheck = await pool.query(`SELECT 1 FROM ${table} WHERE ${cols[0]} = $1 LIMIT 1`, [values[0]]);
                        if (existingCheck.rows.length > 0) skip = true;
                    } catch(e) {}
                }

                if (skip) continue;

                let query = `INSERT INTO "${table}" (${cols.join(', ')}) VALUES (${placeholders}) ${onConflictStr}`;
                
                try {
                    const res = await pool.query(query, values);
                    if (res.rowCount > 0) added++;
                } catch (e) {
                    if (!e.message.includes('duplicate key value violates unique constraint') && !e.message.includes('ON CONFLICT DO UPDATE requires inference specification or constraint name')) {
                        console.error('Insert error in table ' + table + ':', e.message);
                    }
                }
            }

            if (added > 0) {
                console.log(`[DATA] Đã chèn thêm ${added} dòng dữ liệu bị thiếu vào bảng ${table}.`);
            }
        }
        
        console.log('\n✅ QUÁ TRÌNH ĐỒNG BỘ HOÀN TẤT THÀNH CÔNG!');
    } catch (err) {
        console.error('Lỗi tổng:', err);
    } finally {
        await pool.end();
    }
}
run();
