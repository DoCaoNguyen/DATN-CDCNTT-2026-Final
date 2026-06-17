const pool = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const authController = {
    login: async (req, res) => {
        const { phone_number, password } = req.body;
        if (!phone_number || !password) {
            return res.status(400).json({ error: 'Missing phone_number or password' });
        }

        try {
            const userRes = await pool.query('SELECT * FROM users WHERE phone_number = $1', [phone_number]);
            if (userRes.rows.length === 0) {
                return res.status(404).json({ error: 'User not found' });
            }

            const user = userRes.rows[0];
            const isMatch = await bcrypt.compare(password, user.password);
            if (!isMatch) {
                return res.status(401).json({ error: 'Invalid password' });
            }

            const token = jwt.sign(
                { userId: user.id, role: user.role, phone: user.phone_number },
                process.env.JWT_SECRET,
                { expiresIn: '30d' }
            );

            res.status(200).json({
                message: 'Login successful',
                token,
                user: {
                    id: user.id,
                    phone_number: user.phone_number,
                    full_name: user.full_name,
                    role: user.role,
                    tier: user.tier,
                    total_points: user.total_points
                }
            });
        } catch (error) {
            console.error('Login error:', error);
            res.status(500).json({ error: 'Server error' });
        }
    },
    
    // For testing/seeding purposes
    register: async (req, res) => {
        const { phone_number, password, full_name, role } = req.body;
        try {
            const salt = await bcrypt.genSalt(10);
            const hashed = await bcrypt.hash(password, salt);
            const userRes = await pool.query(
                'INSERT INTO users (phone_number, password, full_name, role) VALUES ($1, $2, $3, $4) RETURNING id, phone_number, full_name, role',
                [phone_number, hashed, full_name, role || 'MEMBER']
            );
            res.status(201).json({ message: 'User created', user: userRes.rows[0] });
        } catch (err) {
            console.error('Register error:', err);
            res.status(500).json({ error: 'Server error' });
        }
    }
};

module.exports = authController;
