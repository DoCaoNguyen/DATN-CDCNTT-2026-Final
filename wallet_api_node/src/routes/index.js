const express = require('express');
const router = express.Router();

const authRoutes = require('../modules/auth/auth.routes');
const transactionRoutes = require('../modules/transaction/transaction.routes');
const paymentRoutes = require('../modules/payment/payment.routes'); 
const kycRoutes = require('../modules/kyc/kyc.routes');
const apiLogger = require('../middlewares/logger.middleware');
const walletRoutes = require('../modules/wallet/wallet.routes');
const userRoutes = require('../modules/user/user.routes');


router.use(apiLogger);
router.use('/auth', authRoutes);
router.use('/transaction', transactionRoutes);
router.use('/payment', paymentRoutes); 
router.use('/kyc', kycRoutes);
router.use('/wallet', walletRoutes);
router.use('/users', userRoutes);


module.exports = router;