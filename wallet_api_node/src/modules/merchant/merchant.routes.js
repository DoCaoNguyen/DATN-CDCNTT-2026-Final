const express = require('express');
const router = express.Router();
const { authenticateJwt, requireMerchantOwner } = require('../../middlewares/auth.middleware');
const verifyApiKey = require('../../middlewares/merchant.middleware');
const notImplemented = require('../../utils/notImplemented');

/**
 * @swagger
 * tags:
 *   name: Merchant
 *   description: Dang ky merchant, profile, API keys, callback config va Merchant Open API
 */

/**
 * @swagger
 * /api/v1/merchants/register:
 *   post:
 *     summary: Merchant tu dang ky va cho admin duyet
 *     tags: [Merchant]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [merchant_name, representative_name, phone, email, owner_username, owner_password]
 *             properties:
 *               merchant_name:
 *                 type: string
 *               business_type:
 *                 type: string
 *                 enum: [ONLINE, OFFLINE, BOTH]
 *               tax_code:
 *                 type: string
 *               representative_name:
 *                 type: string
 *               phone:
 *                 type: string
 *               email:
 *                 type: string
 *               address:
 *                 type: string
 *               owner_username:
 *                 type: string
 *               owner_password:
 *                 type: string
 *     responses:
 *       201:
 *         description: Merchant registered PENDING_REVIEW
 */
router.post('/merchants/register', notImplemented('POST /merchants/register'));

/**
 * @swagger
 * /api/v1/merchant/profile:
 *   get:
 *     summary: Merchant xem profile cua minh
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant profile
 *   patch:
 *     summary: Merchant Owner cap nhat profile
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile updated
 */
router.get('/merchant/profile', authenticateJwt, notImplemented('GET /merchant/profile'));
router.patch('/merchant/profile', authenticateJwt, requireMerchantOwner, notImplemented('PATCH /merchant/profile'));

/**
 * @swagger
 * /api/v1/merchant/api-keys:
 *   get:
 *     summary: Merchant Owner xem danh sach API key
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sach API key
 *   post:
 *     summary: Merchant Owner tao API key/secret
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [key_name, environment]
 *             properties:
 *               key_name:
 *                 type: string
 *               environment:
 *                 type: string
 *                 enum: [SANDBOX, LIVE]
 *     responses:
 *       201:
 *         description: API key created, secret chi hien thi mot lan
 */
router.get('/merchant/api-keys', authenticateJwt, requireMerchantOwner, notImplemented('GET /merchant/api-keys'));
router.post('/merchant/api-keys', authenticateJwt, requireMerchantOwner, notImplemented('POST /merchant/api-keys'));

/**
 * @swagger
 * /api/v1/merchant/api-keys/{id}/actions/rotate:
 *   post:
 *     summary: Rotate API secret cua merchant API key
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Secret rotated
 */
router.post('/merchant/api-keys/:id/actions/rotate', authenticateJwt, requireMerchantOwner, notImplemented('POST /merchant/api-keys/{id}/actions/rotate'));

/**
 * @swagger
 * /api/v1/merchant/api-keys/{id}/actions/revoke:
 *   post:
 *     summary: Revoke API key cua merchant
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: API key revoked
 */
router.post('/merchant/api-keys/:id/actions/revoke', authenticateJwt, requireMerchantOwner, notImplemented('POST /merchant/api-keys/{id}/actions/revoke'));

/**
 * @swagger
 * /api/v1/merchant/callback-config:
 *   get:
 *     summary: Merchant Owner xem cau hinh callback/redirect
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Callback config
 *   patch:
 *     summary: Merchant Owner cap nhat cau hinh callback/redirect
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               default_callback_url:
 *                 type: string
 *               default_redirect_url:
 *                 type: string
 *               retry_enabled:
 *                 type: boolean
 *               callback_status:
 *                 type: string
 *                 enum: [ACTIVE, DISABLED]
 *     responses:
 *       200:
 *         description: Callback config updated
 */
router.get('/merchant/callback-config', authenticateJwt, requireMerchantOwner, notImplemented('GET /merchant/callback-config'));
router.patch('/merchant/callback-config', authenticateJwt, requireMerchantOwner, notImplemented('PATCH /merchant/callback-config'));

/**
 * @swagger
 * /api/v1/merchant/payments:
 *   post:
 *     summary: Merchant Open API tao payment order
 *     tags: [Merchant]
 *     security:
 *       - ApiKeyAuth: []
 *     parameters:
 *       - in: header
 *         name: X-Timestamp
 *         required: true
 *         schema:
 *           type: string
 *       - in: header
 *         name: X-Signature
 *         required: true
 *         schema:
 *           type: string
 *       - in: header
 *         name: Idempotency-Key
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       201:
 *         description: Payment created
 *   get:
 *     summary: Merchant Portal xem danh sach payment orders
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant payment orders
 */
router.post('/merchant/payments', verifyApiKey, notImplemented('POST /merchant/payments'));
router.get('/merchant/payments', authenticateJwt, notImplemented('GET /merchant/payments'));

/**
 * @swagger
 * /api/v1/merchant/payments/{id}:
 *   get:
 *     summary: Merchant xem chi tiet payment theo ID
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Payment detail
 */
router.get('/merchant/payments/:id', authenticateJwt, notImplemented('GET /merchant/payments/{id}'));

/**
 * @swagger
 * /api/v1/merchant/payments/by-order/{merchant_order_id}:
 *   get:
 *     summary: Merchant Open API query payment theo ma don merchant
 *     tags: [Merchant]
 *     security:
 *       - ApiKeyAuth: []
 *     parameters:
 *       - in: header
 *         name: X-Timestamp
 *         required: true
 *         schema:
 *           type: string
 *       - in: header
 *         name: X-Signature
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: merchant_order_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Payment detail by merchant order id
 */
router.get('/merchant/payments/by-order/:merchant_order_id', verifyApiKey, notImplemented('GET /merchant/payments/by-order/{merchant_order_id}'));

/**
 * @swagger
 * /api/v1/merchant/payments/{id}/actions/cancel:
 *   post:
 *     summary: Merchant Open API huy payment order dang PENDING
 *     tags: [Merchant]
 *     security:
 *       - ApiKeyAuth: []
 *     parameters:
 *       - in: header
 *         name: X-Timestamp
 *         required: true
 *         schema:
 *           type: string
 *       - in: header
 *         name: X-Signature
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Payment canceled
 */
router.post('/merchant/payments/:id/actions/cancel', verifyApiKey, notImplemented('POST /merchant/payments/{id}/actions/cancel'));

/**
 * @swagger
 * /api/v1/merchant/payment-orders:
 *   get:
 *     summary: Merchant Portal xem danh sach payment orders
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant payment orders
 */
router.get('/merchant/payment-orders', authenticateJwt, notImplemented('GET /merchant/payment-orders'));

/**
 * @swagger
 * /api/v1/merchant/payment-orders/{id}:
 *   get:
 *     summary: Merchant Portal xem chi tiet payment order
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Merchant payment order detail
 */
router.get('/merchant/payment-orders/:id', authenticateJwt, notImplemented('GET /merchant/payment-orders/{id}'));

/**
 * @swagger
 * /api/v1/merchant/webhooks:
 *   get:
 *     summary: Merchant xem webhook/callback logs cua minh
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant webhooks
 * /api/v1/merchant/webhooks/{id}:
 *   get:
 *     summary: Merchant xem chi tiet webhook
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Webhook detail
 * /api/v1/merchant/webhooks/{id}/actions/retry:
 *   post:
 *     summary: Merchant Owner retry webhook cua minh
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Webhook retry queued
 */
router.get('/merchant/webhooks', authenticateJwt, notImplemented('GET /merchant/webhooks'));
router.get('/merchant/webhooks/:id', authenticateJwt, notImplemented('GET /merchant/webhooks/{id}'));
router.post('/merchant/webhooks/:id/actions/retry', authenticateJwt, requireMerchantOwner, notImplemented('POST /merchant/webhooks/{id}/actions/retry'));

/**
 * @swagger
 * /api/v1/merchant/dashboard/kpis:
 *   get:
 *     summary: Merchant Dashboard KPIs
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant dashboard KPIs
 * /api/v1/merchant/dashboard/chart:
 *   get:
 *     summary: Merchant Dashboard chart
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant dashboard chart
 * /api/v1/merchant/dashboard/recent-activities:
 *   get:
 *     summary: Merchant recent activities
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant recent activities
 */
router.get('/merchant/dashboard/kpis', authenticateJwt, notImplemented('GET /merchant/dashboard/kpis'));
router.get('/merchant/dashboard/chart', authenticateJwt, notImplemented('GET /merchant/dashboard/chart'));
router.get('/merchant/dashboard/recent-activities', authenticateJwt, notImplemented('GET /merchant/dashboard/recent-activities'));

/**
 * @swagger
 * /api/v1/merchant/reports/payments:
 *   get:
 *     summary: Merchant bao cao payments
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant payment report
 * /api/v1/merchant/reports/refunds:
 *   get:
 *     summary: Merchant bao cao refunds
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant refund report
 * /api/v1/merchant/reports/webhooks:
 *   get:
 *     summary: Merchant bao cao webhooks
 *     tags: [Merchant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant webhook report
 */
router.get('/merchant/reports/payments', authenticateJwt, notImplemented('GET /merchant/reports/payments'));
router.get('/merchant/reports/refunds', authenticateJwt, notImplemented('GET /merchant/reports/refunds'));
router.get('/merchant/reports/webhooks', authenticateJwt, notImplemented('GET /merchant/reports/webhooks'));

module.exports = router;
