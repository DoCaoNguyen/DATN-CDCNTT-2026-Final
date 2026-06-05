const express = require('express');
const router = express.Router();
const walletController = require('../controllers/wallet.controller');
const verifyToken = require('../middlewares/auth.middleware');

// Phải có Token mới được xem số dư
router.use(verifyToken);

// API: GET /api/wallet/balance
router.get('/balance', walletController.getBalance);

module.exports = router;