const express = require('express');
const router = express.Router();
const merchantController = require('./merchant.controller');
const { requireMerchantUser, requireActiveMerchant, verifyApiKey, verifyApiKeyWithSignature } = require('../../middlewares/merchant.middleware');

const { verifyToken } = require('../../middlewares/auth.middleware');
const withIdempotency = require('../../middlewares/idempotency.middleware');

router.post('/register', verifyToken, merchantController.register);
router.get('/me', verifyToken, merchantController.getMe);

router.get('/profile', requireMerchantUser, merchantController.getProfile);
router.patch('/profile/callback', requireMerchantUser, requireActiveMerchant, merchantController.updateCallback);
router.get('/api-keys', requireMerchantUser, merchantController.getApiKeys);
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
router.post('/auth-code/generate', verifyToken, merchantController.generateAuthCode);
router.post('/auth-code/verify', merchantController.verifyAuthCode);
router.post('/charge', verifyApiKey, merchantController.charge);

module.exports = router;
