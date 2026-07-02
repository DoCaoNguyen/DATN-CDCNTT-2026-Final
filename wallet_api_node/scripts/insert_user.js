const pool = require('../src/config/db');
const { v7: uuidv7 } = require('uuid');
const bcrypt = require('bcrypt');

async function insertUser() {
    const userId = uuidv7();
    const walletId = uuidv7();
    
    console.log("Generating hashes for 000000...");
    const passwordHash = await bcrypt.hash('000000', 10);
    const pinHash = await bcrypt.hash('000000', 10);
    
    try {
        await pool.query('BEGIN');
        
        console.log("Inserting into users...");
        await pool.query(`
            INSERT INTO users (id, user_type, full_name, phone, password_hash, pin_hash, is_kyc_verified, status)
            VALUES ($1, 'USER', 'Đỗ Cao Nguyên', '0346761632', $2, $3, true, 'ACTIVE')
        `, [userId, passwordHash, pinHash]);
        
        console.log("Assigning role...");
        await pool.query(`
            INSERT INTO user_roles (user_id, role_id)
            SELECT $1, id FROM roles WHERE code = 'USER' AND is_active = true
            ON CONFLICT DO NOTHING
        `, [userId]);
        
        console.log("Creating wallet...");
        const walletNo = `WAL${Date.now()}${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`;
        await pool.query(`
            INSERT INTO wallets (id, user_id, wallet_no, wallet_type, currency, status)
            VALUES ($1, $2, $3, 'PERSONAL', 'VND', 'ACTIVE')
        `, [walletId, userId, walletNo]);
        
        console.log("Creating wallet balances...");
        await pool.query(`
            INSERT INTO wallet_balances (wallet_id, available_balance, locked_balance)
            VALUES ($1, 0, 0)
        `, [walletId]);
        
        await pool.query('COMMIT');
        console.log("User Đỗ Cao Nguyên (0346761632) inserted successfully.");
    } catch (err) {
        await pool.query('ROLLBACK');
        console.error("Error inserting user:", err);
    } finally {
        pool.end();
    }
}

insertUser();
