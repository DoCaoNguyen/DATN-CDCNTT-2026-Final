const axios = require('axios');
require('dotenv').config();

const speedSmsToken = process.env.SPEEDSMS_TOKEN;

async function checkUserInfo() {
    try {
        console.log('Checking user info with token:', speedSmsToken);
        const response = await axios.get('https://api.speedsms.vn/index.php/user/info', {
            auth: {
                username: speedSmsToken,
                password: 'x'
            }
        });
        console.log('User Info Response:', response.data);
    } catch (e) {
        console.error('Error:', e.response ? e.response.data : e.message);
    }
}

checkUserInfo();
