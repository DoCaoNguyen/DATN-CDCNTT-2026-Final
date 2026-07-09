const usersRepository = require('./src/modules/admin/users/users.repository');
const pool = require('./src/config/db');

async function testList() {
    try {
        const result = await usersRepository.listUsers({
            page: 1,
            limit: 10,
            q: '',
            status: '',
            userType: 'USER'
        });
        console.log("Success:", result);
    } catch(err) {
        console.log("Error:", err);
    } finally {
        pool.end();
    }
}
testList();
