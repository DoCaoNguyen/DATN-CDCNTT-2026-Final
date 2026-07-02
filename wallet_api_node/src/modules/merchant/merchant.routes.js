const express = require('express');
const router = express.Router();
const merchantController = require('./merchant.controller');
const { requireMerchantUser, requireActiveMerchant } = require('../../middlewares/merchant.middleware');

const { verifyToken } = require('../../middlewares/auth.middleware');

router.get('/profile', requireMerchantUser, merchantController.getProfile);
router.patch('/profile/callback', requireMerchantUser, requireActiveMerchant, merchantController.updateCallback);
router.get('/api-keys', requireMerchantUser, merchantController.getApiKeys); // Cho phép xem nhưng ko cho tạo
router.post('/api-keys', requireMerchantUser, requireActiveMerchant, merchantController.createApiKey);
router.post('/api-keys/:keyId/actions/rotate-secret', requireMerchantUser, requireActiveMerchant, merchantController.rotateApiKey);
router.post('/api-keys/:keyId/actions/revoke', requireMerchantUser, merchantController.revokeApiKey);
router.get('/payment-orders', requireMerchantUser, merchantController.getPaymentOrders);
router.get('/payment-orders/:id', requireMerchantUser, merchantController.getPaymentOrderById);
router.get('/transactions', requireMerchantUser, merchantController.getTransactions);
router.get('/transactions/:id', requireMerchantUser, merchantController.getTransactionById);
router.get('/webhooks', requireMerchantUser, merchantController.getWebhooks);
router.get('/webhooks/:id', requireMerchantUser, merchantController.getWebhookById);
router.post('/webhooks/:id/retry', requireMerchantUser, requireActiveMerchant, merchantController.retryWebhook);
router.get('/balance', requireMerchantUser, merchantController.getBalance);
router.get('/balance/statement', requireMerchantUser, merchantController.getStatement);

// [Thêm mới] API cấp và xác thực Auth_Code
router.post('/auth-code/generate', verifyToken, merchantController.generateAuthCode);
router.post('/auth-code/verify', merchantController.verifyAuthCode);

// [Thêm mới] API Ra lệnh trừ tiền tự động (Dùng API Key thay vì token)
router.post('/charge', merchantController.charge);

module.exports = router;
