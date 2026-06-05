const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const transactionRoutes = require('./transaction.routes');
const paymentRoutes = require('./payment.routes'); 
const kycRoutes = require('./kyc.routes');
const apiLogger = require('../middlewares/logger.middleware');
const walletRoutes = require('./wallet.routes');
const userRoutes = require('./user.routes');


router.use(apiLogger);
router.use('/auth', authRoutes);
router.use('/transaction', transactionRoutes);
router.use('/payment', paymentRoutes); 
router.use('/kyc', kycRoutes);
router.use('/wallet', walletRoutes);
router.use('/users', userRoutes);


module.exports = router;