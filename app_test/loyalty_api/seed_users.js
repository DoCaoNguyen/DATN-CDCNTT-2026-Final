const pool = require('./db');
const bcrypt = require('bcryptjs');

async function seedUsers() {
    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('123456', salt);

        const users = [
            {
                phone_number: '0999999999',
                password: hashedPassword,
                full_name: 'Admin Loyalty',
                role: 'ADMIN'
            },
            {
                phone_number: '0888888888',
                password: hashedPassword,
                full_name: 'Staff Cashier',
                role: 'STAFF'
            },
            {
                phone_number: '0777777777',
                password: hashedPassword,
                full_name: 'Nguyen Van Khach Hang',
                role: 'MEMBER'
            }
        ];

        for (const user of users) {
            // Check if user exists
            const existing = await pool.query('SELECT * FROM users WHERE phone_number = $1', [user.phone_number]);
            if (existing.rows.length === 0) {
                await pool.query(
                    'INSERT INTO users (phone_number, password, full_name, role) VALUES ($1, $2, $3, $4)',
                    [user.phone_number, user.password, user.full_name, user.role]
                );
                console.log(`Created user: ${user.full_name} (${user.role}) with phone: ${user.phone_number}`);
            } else {
                console.log(`User ${user.phone_number} already exists.`);
            }
        }
        
        console.log('Seeding users completed.');
    } catch (error) {
        console.error('Error seeding users:', error);
    } finally {
        // End the pool to exit script
        await pool.end();
    }
}

seedUsers();
