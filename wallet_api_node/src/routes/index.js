const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const transactionRoutes = require('./transaction.routes');
const paymentRoutes = require('./payment.routes'); // MỚI THÊM

router.use('/auth', authRoutes);
router.use('/transaction', transactionRoutes);
router.use('/payment', paymentRoutes); // MỚI THÊM

module.exports = router;