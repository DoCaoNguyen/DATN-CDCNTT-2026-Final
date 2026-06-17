require('dotenv').config();
const { v7: uuidv7 } = require('uuid');
const bcrypt = require('bcrypt');
const pool = require('./src/config/db');

async function seed() {
    const usersToSeed = [
        { phone: '0907522647', email: 'docaonguyen@gmail.com', name: 'Đỗ Cao Nguyên' },
        { phone: '0346761632', email: 'nguyenduyphuong@gmail.com', name: 'Nguyễn Duy Phương' }
    ];

    const passwordStr = '000000';
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(passwordStr, saltRounds);
    const pinHash = await bcrypt.hash(passwordStr, saltRounds); // Assume PIN is also hashed similarly

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        for (const u of usersToSeed) {
            const existingRes = await client.query('SELECT id FROM users WHERE phone = $1', [u.phone]);
            let userId;
            if (existingRes.rows.length > 0) {
                userId = existingRes.rows[0].id;
                await client.query(`UPDATE users SET password_hash = $1, pin_hash = $2, is_kyc_verified = true, status = 'ACTIVE', full_name = $4, email = $5 WHERE id = $3`, [passwordHash, pinHash, userId, u.name, u.email]);
                console.log('Updated existing user: ' + u.phone);
            } else {
                userId = uuidv7();
                await client.query(`
                    INSERT INTO users (id, email, phone, password_hash, pin_hash, full_name, is_kyc_verified, status)
                    VALUES ($1, $2, $3, $4, $5, $6, true, 'ACTIVE')
                `, [userId, u.email, u.phone, passwordHash, pinHash, u.name]);
                console.log('Created new user: ' + u.phone);
            }

            const walletRes = await client.query('SELECT id FROM wallets WHERE user_id = $1', [userId]);
            let walletId;
            if (walletRes.rows.length > 0) {
                walletId = walletRes.rows[0].id;
            } else {
                walletId = uuidv7();
                await client.query('INSERT INTO wallets (id, user_id, wallet_no) VALUES ($1, $2, $3)', [walletId, userId, u.phone]);
            }

            const balanceRes = await client.query('SELECT wallet_id FROM wallet_balances WHERE wallet_id = $1', [walletId]);
            if (balanceRes.rows.length > 0) {
                await client.query('UPDATE wallet_balances SET available_balance = 10000000 WHERE wallet_id = $1', [walletId]);
            } else {
                await client.query('INSERT INTO wallet_balances (wallet_id, available_balance) VALUES ($1, 10000000)', [walletId]);
            }
            console.log('Funded wallet for ' + u.phone + ' with 10,000,000');
        }

        await client.query('COMMIT');
        console.log('Seeding completed successfully!');
    } catch (e) {
        await client.query('ROLLBACK');
        console.error('Error seeding:', e);
    } finally {
        client.release();
        pool.end();
    }
}

seed();
