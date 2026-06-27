const express = require('express');
const router = express.Router();
const { authenticateJwt, requireAdmin, requirePermission } = require('../../middlewares/auth.middleware');
const adminController = require('./admin.controller');
const notImplemented = require('../../utils/notImplemented');

/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: Admin quan tri user, wallet, merchant, payment, transaction, refund, webhook, dashboard, report, setting va audit
 */

router.use(authenticateJwt, requireAdmin);

router.use('/', require('./users/users.routes'));

router.use('/permissions', require('./roles/permissions.routes'));
router.use('/roles', require('./roles/roles.routes'));

router.use('/wallets', require('./wallets/wallets.routes'));

router.use('/transactions', require('./transactions/transactions.routes'));
// Reconcile API vẫn để stub vì nó là hành động (POST)
router.post('/transactions/reconcile', notImplemented('POST /admin/transactions/reconcile'));

router.use('/merchants', require('./merchants/merchants.routes'));

/**
 * @swagger
 * /api/v1/admin/payment-orders:
 *   get:
 *     summary: Admin xem danh sach payment orders
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     responses: { 200: { description: OK } }
 */
router.get('/payment-orders', notImplemented('GET /admin/payment-orders'));
router.get('/payment-orders/:id', notImplemented('GET /admin/payment-orders/{id}'));
router.get('/payment-orders/:id/timeline', notImplemented('GET /admin/payment-orders/{id}/timeline'));
router.get('/payment-orders/:id/ledger', notImplemented('GET /admin/payment-orders/{id}/ledger'));
router.get('/payment-orders/:id/callbacks', notImplemented('GET /admin/payment-orders/{id}/callbacks'));

/**
 * @swagger
 * /api/v1/admin/qr-payments:
 *   get:
 *     summary: Admin xem danh sach QR payments
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     responses: { 200: { description: OK } }
 */
router.get('/qr-payments', notImplemented('GET /admin/qr-payments'));
router.get('/qr-payments/:id', notImplemented('GET /admin/qr-payments/{id}'));
router.post('/qr-payments/jobs/expire', notImplemented('POST /admin/qr-payments/jobs/expire'));

/**
 * @swagger
 * /api/v1/admin/refunds:
 *   get:
 *     summary: Admin xem danh sach refunds
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     responses: { 200: { description: OK } }
 */
router.get('/refunds', notImplemented('GET /admin/refunds'));
router.get('/refunds/:id', notImplemented('GET /admin/refunds/{id}'));
router.post('/refunds', notImplemented('POST /admin/refunds'));

/**
 * @swagger
 * /api/v1/admin/webhooks:
 *   get:
 *     summary: Admin xem toan bo callback/webhook
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     responses: { 200: { description: OK } }
 * /api/v1/admin/webhooks/{id}:
 *   get:
 *     summary: Admin xem chi tiet callback/webhook
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses: { 200: { description: OK } }
 * /api/v1/admin/webhooks/{id}/actions/retry:
 *   post:
 *     summary: Admin retry callback
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses: { 200: { description: OK } }
 * /api/v1/admin/webhooks/jobs/retry-due:
 *   post:
 *     summary: Admin chay job retry due demo
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     responses: { 200: { description: OK } }
 */
router.get('/webhooks', notImplemented('GET /admin/webhooks'));
router.get('/webhooks/:id', notImplemented('GET /admin/webhooks/{id}'));
router.post('/webhooks/:id/actions/retry', notImplemented('POST /admin/webhooks/{id}/actions/retry'));
router.post('/webhooks/jobs/retry-due', notImplemented('POST /admin/webhooks/jobs/retry-due'));

// Module Dashboard
router.use('/dashboard', require('./dashboard/dashboard.routes'));

// Module Reports
router.use('/reports', require('./reports/reports.routes'));

/**
 * @swagger
 * /api/v1/admin/settings:
 *   get:
 *     summary: Admin xem settings
 *     tags: [Admin]
 *     security: [{ bearerAuth: [] }]
 *     responses: { 200: { description: OK } }
 */
router.get('/settings', notImplemented('GET /admin/settings'));
router.patch('/settings/:key', notImplemented('PATCH /admin/settings/{key}'));
router.get('/settings/history', notImplemented('GET /admin/settings/history'));

// Module Logging & Audit
router.use('/logs', require('./logs/logs.routes'));

module.exports = router;
