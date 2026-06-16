const express = require('express');
const router = express.Router();

const authRoutes = require('../modules/auth/auth.routes');
const transactionRoutes = require('../modules/transaction/transaction.routes');
const transactionQueryRoutes = require('../modules/transaction/transaction.query.routes');
const paymentRoutes = require('../modules/payment/payment.routes'); 
const kycRoutes = require('../modules/kyc/kyc.routes');
const apiLogger = require('../middlewares/logger.middleware');
const auditLogger = require('../middlewares/audit.middleware');
const walletRoutes = require('../modules/wallet/wallet.routes');
const topupRoutes = require('../modules/topup/topup.routes');
const transferRoutes = require('../modules/transfer/transfer.routes');
const merchantRoutes = require('../modules/merchant/merchant.routes');
const qrPaymentRoutes = require('../modules/qr_payment/qr_payment.routes');
const refundRoutes = require('../modules/refund/refund.routes');
const adminRoutes = require('../modules/admin/admin.routes');
const userRoutes = require('../modules/user/user.routes');
const notificationRoutes = require('../modules/notification/notification.routes');


router.use(apiLogger);
router.use(auditLogger);
router.use('/auth', authRoutes);
router.use('/transaction', transactionRoutes);
router.use('/transactions', transactionQueryRoutes);
router.use('/payment', paymentRoutes); 
router.use('/kyc', kycRoutes);
router.use('/wallets', walletRoutes);
router.use('/wallet', walletRoutes);
router.use('/topups', topupRoutes);
router.use('/transfers', transferRoutes);
router.use('/qr-payments', qrPaymentRoutes);
router.use('/', merchantRoutes);
router.use('/', refundRoutes);
router.use('/admin', adminRoutes);
router.use('/users', userRoutes);
router.use('/notifications', notificationRoutes);


module.exports = router;
