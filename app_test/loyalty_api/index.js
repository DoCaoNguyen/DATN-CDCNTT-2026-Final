const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { verifyToken, verifyRole } = require('./middlewares/authMiddleware');

const authController = require('./controllers/authController');
const staffController = require('./controllers/staffController');
const memberController = require('./controllers/memberController');
const webhookController = require('./controllers/webhookController');

const app = express();
app.use(cors());
app.use(express.json());

// Auth routes
app.post('/api/v1/auth/login', authController.login);
app.post('/api/v1/auth/register', authController.register); // For testing setup

// Webhook from Wallet
app.post('/api/v1/webhook/wallet/sync-points', webhookController.syncPoints);

// Staff routes
app.post('/api/v1/staff/order/create', verifyToken, verifyRole(['STAFF', 'ADMIN']), staffController.createOrder);
app.get('/api/v1/staff/history', verifyToken, verifyRole(['STAFF', 'ADMIN']), staffController.getHistory);

// Member routes
app.get('/api/v1/member/profile', verifyToken, verifyRole(['MEMBER']), memberController.getProfile);
app.get('/api/v1/member/history', verifyToken, verifyRole(['MEMBER']), memberController.getHistory);
app.get('/api/v1/member/rewards', verifyToken, verifyRole(['MEMBER']), memberController.getRewards);

// Admin config (Simplification for now)
app.get('/api/v1/admin/rules', verifyToken, verifyRole(['ADMIN']), async (req, res) => {
    const pool = require('./db');
    const rules = await pool.query('SELECT * FROM point_rules');
    res.json({ data: rules.rows });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Loyalty API is running on port ${PORT}`);
});
