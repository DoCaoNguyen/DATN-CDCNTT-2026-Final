const axios = require('axios');

async function testWebhook() {
    const start = Date.now();
    try {
        console.log('Sending webhook...');
        const res = await axios.post('https://nonoily-overinfluential-deegan.ngrok-free.dev/api/webhook/mio', {}, {
            headers: {
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true'
            },
            timeout: 15000
        });
        console.log(`Success! Status: ${res.status}. Time: ${Date.now() - start}ms`);
        console.log('Response:', res.data);
    } catch (error) {
        console.error(`Failed! Time: ${Date.now() - start}ms`);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        } else {
            console.error('Error message:', error.message);
        }
    }
}

testWebhook();
