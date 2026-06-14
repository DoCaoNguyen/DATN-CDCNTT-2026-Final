require('dotenv').config();
const LoyaltyIntegrationService = require('./src/modules/payment/LoyaltyIntegrationService');
const { v7: uuidv7 } = require('uuid');

async function testSync() {
    try {
        console.log('Testing LoyaltyIntegrationService...');
        await LoyaltyIntegrationService.syncPointsAfterPayment(
            'f0361838-ad7e-46ea-9bac-7e546622aa87', // A valid user id from previous test
            uuidv7(), // Dummy paymentTxId
            50000
        );
        console.log('Sync executed!');
        
        // Wait a bit to let async finish
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        // Check DB
        const pool = require('./src/config/db');
        const res = await pool.query('SELECT * FROM loyalty_sync_logs');
        console.log('Logs in DB:', res.rows);
        process.exit(0);
    } catch (e) {
        console.error('Test failed:', e);
        process.exit(1);
    }
}

testSync();
