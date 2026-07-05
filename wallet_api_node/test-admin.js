require('dotenv').config();
const usersService = require('./src/modules/admin/users/users.service');
const walletsService = require('./src/modules/admin/wallets/wallets.service');

async function test() {
    try {
        console.log('Testing listUsers...');
        const users = await usersService.listUsers(1, 5, '', 'USER', 'ACTIVE');
        console.log('Users result:', users);

        console.log('\nTesting listWallets...');
        const wallets = await walletsService.listWallets(1, 5, '', 'ACTIVE', '');
        console.log('Wallets result:', wallets);
    } catch (e) {
        console.error('Error:', e);
    }
    process.exit(0);
}

test();
