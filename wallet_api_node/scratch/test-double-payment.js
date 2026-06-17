const axios = require('axios');
const pool = require('../src/config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const API_URL = 'http://localhost:8000/api/v1';

async function setupTest() {
    console.log('--- Setting up Double Payment Test ---');
    
    // 1. Setup Test Users
    const resUsers = await pool.query('SELECT id, phone, token_version FROM users LIMIT 2');
    if (resUsers.rows.length < 2) {
        console.error('Not enough users in DB to run test');
        process.exit(1);
    }
    
    const sender = resUsers.rows[0];
    const receiver = resUsers.rows[1];
    
    // Set Sender PIN to 123456
    const pinHash = await bcrypt.hash('123456', 10);
    await pool.query('UPDATE users SET pin_hash = $1 WHERE id = $2', [pinHash, sender.id]);
    
    // Make sure Sender has a wallet
    const senderWalletRes = await pool.query('SELECT id FROM wallets WHERE user_id = $1', [sender.id]);
    let senderWalletId = senderWalletRes.rows.length > 0 ? senderWalletRes.rows[0].id : null;
    
    if (!senderWalletId) {
        console.log('Sender has no wallet, creating...');
        // Skipping creation logic for simplicity if they already have wallets
    }
    
    // Reset Sender Balance to exactly 10,000 VND
    await pool.query('UPDATE wallet_balances SET available_balance = 10000 WHERE wallet_id = $1', [senderWalletId]);
    console.log(`Sender (${sender.phone}) balance set to 10000 VND`);

    // Generate JWT for Sender
    const token = jwt.sign(
        { userId: sender.id, phone: sender.phone, role: 'USER', tokenVersion: sender.token_version },
        process.env.JWT_SECRET || 'your_super_secret_jwt_key_here',
        { expiresIn: '1h' }
    );

    return { token, senderPhone: sender.phone, receiverPhone: receiver.phone };
}

async function runTest(token, receiverPhone) {
    console.log('\n--- Running Concurrent Requests ---');
    
    // We will attempt to transfer 10,000 VND TWO times concurrently.
    // If the system has a race condition, both might succeed and overdraw the balance.
    
    const requestData1 = {
        receiver_identifier: receiverPhone,
        amount: "10000",
        pin: "123456",
        note: "Double payment test 1"
    };

    const requestData2 = {
        receiver_identifier: receiverPhone,
        amount: "10000",
        pin: "123456",
        note: "Double payment test 2"
    };

    // Use different idempotency keys so the middleware doesn't block it. We want to test DB locking.
    const headers1 = {
        'Authorization': `Bearer ${token}`,
        'Idempotency-Key': 'key-1-' + Date.now()
    };
    
    const headers2 = {
        'Authorization': `Bearer ${token}`,
        'Idempotency-Key': 'key-2-' + Date.now()
    };

    try {
        const req1 = axios.post(`${API_URL}/transaction/transfer`, requestData1, { headers: headers1 });
        const req2 = axios.post(`${API_URL}/transaction/transfer`, requestData2, { headers: headers2 });

        console.log('Sending both requests simultaneously...');
        const results = await Promise.allSettled([req1, req2]);

        console.log('\n--- Results ---');
        let successCount = 0;
        let failCount = 0;

        results.forEach((res, index) => {
            if (res.status === 'fulfilled') {
                console.log(`Request ${index + 1}: SUCCESS - ${res.value.data.message}`);
                successCount++;
            } else {
                console.log(`Request ${index + 1}: FAILED - ${res.reason.response?.data?.error || res.reason.message}`);
                failCount++;
            }
        });
        
        console.log(`\nSummary: ${successCount} Succeeded, ${failCount} Failed.`);
        if (successCount > 1) {
            console.error('🚨 VULNERABILITY DETECTED: Double Payment occurred! Both transfers succeeded.');
        } else {
            console.log('✅ TEST PASSED: Race condition prevented. Only one transfer succeeded.');
        }
        
    } catch (e) {
        console.error('Unexpected test failure:', e.message);
    } finally {
        pool.end();
    }
}

setupTest().then(({ token, receiverPhone }) => runTest(token, receiverPhone));
