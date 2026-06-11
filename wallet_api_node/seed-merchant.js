const pool = require('./src/config/db');
const { v7: uuidv7 } = require('uuid');

async function seedMerchant() {
    console.log('--- Đang tạo dữ liệu mẫu Merchant và API Key ---');
    const client = await pool.connect();
    
    try {
        await client.query('BEGIN');
        
        // 1. Tạo Merchant mẫu
        const merchantId = uuidv7();
        const merchantName = 'Cửa hàng nước giải khát Test';
        const email = 'merchant.test@vipayment.com';
        const callbackUrl = 'https://webhook.site/test';
        
        console.log(`Đang tạo Merchant: "${merchantName}"...`);
        await client.query(
            `INSERT INTO merchants (id, merchant_name, email, callback_url, status)
             VALUES ($1, $2, $3, $4, 'ACTIVE')
             ON CONFLICT DO NOTHING`,
            [merchantId, merchantName, email, callbackUrl]
        );

        // 2. Tạo API Key cho Merchant này
        const apiKeyId = uuidv7();
        const testApiKey = 'vipayment_key_test_123456';
        const testApiSecret = 'vipayment_secret_test_abcdef';
        
        console.log(`Đang tạo API Key mẫu: "${testApiKey}"...`);
        await client.query(
            `INSERT INTO merchant_api_keys (id, merchant_id, api_key, api_secret, expired_at)
             VALUES ($1, $2, $3, $4, NULL)
             ON CONFLICT DO NOTHING`,
            [apiKeyId, merchantId, testApiKey, testApiSecret]
        );

        await client.query('COMMIT');
        console.log('--------------------------------------------');
        console.log('TẠO THÀNH CÔNG!');
        console.log('Sử dụng Header sau trong Postman để gọi API tạo thanh toán:');
        console.log(`x-api-key: ${testApiKey}`);
        console.log('--------------------------------------------');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Lỗi khi chèn dữ liệu:', error);
    } finally {
        client.release();
        process.exit();
    }
}

seedMerchant();
