const axios = require('axios');
require('dotenv').config();

const speedSmsToken = process.env.SPEEDSMS_TOKEN;

async function runTest(label, payload) {
    try {
        console.log(`\n--- Test: ${label} ---`);
        const response = await axios.post('https://api.speedsms.vn/index.php/sms/send', payload, {
            auth: {
                username: speedSmsToken,
                password: 'x'
            }
        });
        console.log('Response:', response.data);
    } catch (e) {
        console.error('Error:', e.response ? e.response.data : e.message);
    }
}

async function testAll() {
    const to = ['0912345678'];
    const content = 'Ma OTP test: 1234';

    // 1. sms_type: 2, sender: 'SPEEDSMS'
    await runTest('sms_type 2 with sender "SPEEDSMS"', { to, content, sms_type: 2, sender: 'SPEEDSMS' });

    // 2. sms_type: 2, sender: ''
    await runTest('sms_type 2 with empty sender', { to, content, sms_type: 2, sender: '' });

    // 3. sms_type: 4 (Brandname mặc định), sender: 'Verify'
    await runTest('sms_type 4 with sender "Verify"', { to, content, sms_type: 4, sender: 'Verify' });

    // 4. sms_type: 4 (Brandname mặc định), sender: 'Notify'
    await runTest('sms_type 4 with sender "Notify"', { to, content, sms_type: 4, sender: 'Notify' });

    // 5. sms_type: 3 (Brandname riêng), sender: 'SPEEDSMS'
    await runTest('sms_type 3 with sender "SPEEDSMS"', { to, content, sms_type: 3, sender: 'SPEEDSMS' });
}

testAll();
