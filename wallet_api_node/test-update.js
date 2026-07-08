const pool = require('./src/config/db');
const jwt = require('jsonwebtoken');

async function testUpdate() {
    const userId = '01000000-0000-0000-0000-000000000002'; // Assuming admin.ops id?
    const { rows } = await pool.query("SELECT * FROM users WHERE username = 'admin.ops'");
    const admin = rows[0];

    const context = {
        roles: [{ code: 'ADMIN' }],
        permissions: ['admin.roles.update', 'admin.roles.read']
    };

    const token = jwt.sign({
        sub: admin.id,
        userId: admin.id,
        user_type: admin.user_type,
        roles: context.roles.map(role => role.code),
        permissions: context.permissions,
        token_type: 'ACCESS',
        tokenVersion: Number(admin.token_version)
    }, process.env.JWT_SECRET || 'secret', { expiresIn: 3600 });

    const axios = require('axios');
    try {
        const res = await axios.patch('http://localhost:8000/api/v1/admin/roles/01000000-0000-0000-0000-000000000004', 
            { name: 'Support Staff Updated', permissions: ['admin.users.read'] }, 
            { headers: { Authorization: 'Bearer ' + token } }
        );
        console.log('OK', res.data);
    } catch(err) {
        console.log('ERROR', err.response?.data || err.message);
    }
    process.exit(0);
}
testUpdate();
