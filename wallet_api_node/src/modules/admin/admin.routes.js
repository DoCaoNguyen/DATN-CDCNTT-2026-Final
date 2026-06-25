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

router.get('/topups', notImplemented('GET /admin/topups'));
router.get('/topups/:id', notImplemented('GET /admin/topups/{id}'));
router.get('/transfers', notImplemented('GET /admin/transfers'));
router.get('/transfers/:id', notImplemented('GET /admin/transfers/{id}'));

router.get('/transactions', notImplemented('GET /admin/transactions'));
router.get('/transactions/:id', notImplemented('GET /admin/transactions/{id}'));
router.get('/ledger-entries', notImplemented('GET /admin/ledger-entries'));
router.post('/transactions/reconcile', notImplemented('POST /admin/transactions/reconcile'));

router.use('/merchants', require('./merchants/merchants.routes'));

router.get('/payment-orders', notImplemented('GET /admin/payment-orders'));
router.get('/payment-orders/:id', notImplemented('GET /admin/payment-orders/{id}'));
router.get('/payment-orders/:id/timeline', notImplemented('GET /admin/payment-orders/{id}/timeline'));
router.get('/payment-orders/:id/ledger', notImplemented('GET /admin/payment-orders/{id}/ledger'));
router.get('/payment-orders/:id/callbacks', notImplemented('GET /admin/payment-orders/{id}/callbacks'));

router.get('/qr-payments', notImplemented('GET /admin/qr-payments'));
router.get('/qr-payments/:id', notImplemented('GET /admin/qr-payments/{id}'));
router.post('/qr-payments/jobs/expire', notImplemented('POST /admin/qr-payments/jobs/expire'));

router.get('/refunds', notImplemented('GET /admin/refunds'));
router.get('/refunds/:id', notImplemented('GET /admin/refunds/{id}'));
router.post('/refunds', notImplemented('POST /admin/refunds'));

router.get('/webhooks', notImplemented('GET /admin/webhooks'));
router.get('/webhooks/:id', notImplemented('GET /admin/webhooks/{id}'));
router.post('/webhooks/:id/actions/retry', notImplemented('POST /admin/webhooks/{id}/actions/retry'));
router.post('/webhooks/jobs/retry-due', notImplemented('POST /admin/webhooks/jobs/retry-due'));

router.get('/dashboard/kpis', adminController.getDashboardKPIs);
router.get('/dashboard/transactions-chart', notImplemented('GET /admin/dashboard/transactions-chart'));
router.get('/dashboard/success-rate', notImplemented('GET /admin/dashboard/success-rate'));
router.get('/dashboard/top-merchants', notImplemented('GET /admin/dashboard/top-merchants'));
router.get('/dashboard/recent-activities', notImplemented('GET /admin/dashboard/recent-activities'));
router.get('/dashboard/alerts', notImplemented('GET /admin/dashboard/alerts'));

router.get('/reports/topups', notImplemented('GET /admin/reports/topups'));
router.get('/reports/transfers', notImplemented('GET /admin/reports/transfers'));
router.get('/reports/payments', notImplemented('GET /admin/reports/payments'));
router.get('/reports/refunds', notImplemented('GET /admin/reports/refunds'));
router.get('/reports/merchants', notImplemented('GET /admin/reports/merchants'));
router.get('/reports/webhooks', notImplemented('GET /admin/reports/webhooks'));
router.get('/reports/ledger', notImplemented('GET /admin/reports/ledger'));
router.get('/reports/export', notImplemented('GET /admin/reports/export'));

router.get('/settings', notImplemented('GET /admin/settings'));
router.patch('/settings/:key', notImplemented('PATCH /admin/settings/{key}'));
router.get('/settings/history', notImplemented('GET /admin/settings/history'));

router.get('/audit-logs', notImplemented('GET /admin/audit-logs'));
router.get('/audit-logs/:id', notImplemented('GET /admin/audit-logs/{id}'));
router.get('/system-logs', notImplemented('GET /admin/system-logs'));
router.get('/payment-traces/:payment_order_id', notImplemented('GET /admin/payment-traces/{payment_order_id}'));

module.exports = router;
