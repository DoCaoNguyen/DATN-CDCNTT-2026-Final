const express = require('express');
const router = express.Router();
const { authenticateJwt, requireAdmin, requirePermission } = require('../../middlewares/auth.middleware');
const adminController = require('./admin.controller');
const notImplemented = require('../../utils/notImplemented');

router.use(authenticateJwt, requireAdmin);

router.get('/users', requirePermission('admin.users.manage'), adminController.listUsers);
router.post('/users', requirePermission('admin.users.manage'), adminController.createUser);
router.get('/users/:id', requirePermission('admin.users.manage'), adminController.getUserDetail);
router.patch('/users/:id', requirePermission('admin.users.manage'), adminController.updateUser);
router.get('/users/:id/wallet', requirePermission('admin.users.manage', 'wallets.read'), adminController.getUserWallet);
router.post('/users/:id/actions/lock', requirePermission('admin.users.manage'), adminController.lockUser);
router.post('/users/:id/actions/unlock', requirePermission('admin.users.manage'), adminController.unlockUser);
router.post('/users/:id/actions/reset-password', requirePermission('admin.users.manage'), adminController.resetUserPassword);
router.get('/users/:id/audit-logs', requirePermission('audit_logs.read'), adminController.getUserAuditLogs);

router.get('/roles', notImplemented('GET /admin/roles'));
router.post('/roles', notImplemented('POST /admin/roles'));
router.get('/roles/:id', notImplemented('GET /admin/roles/{id}'));
router.patch('/roles/:id', notImplemented('PATCH /admin/roles/{id}'));
router.get('/permissions', notImplemented('GET /admin/permissions'));

router.get('/wallets', requirePermission('wallets.read'), adminController.listWallets);
router.get('/wallets/:wallet_id', requirePermission('wallets.read'), adminController.getWalletDetail);
router.get('/wallets/:wallet_id/summary', requirePermission('wallets.read'), adminController.getWalletSummary);
router.get('/wallets/:wallet_id/ledger', requirePermission('wallets.read'), adminController.getWalletLedger);
router.post('/wallets/:wallet_id/actions/lock', requirePermission('wallets.lock'), adminController.lockWallet);
router.post('/wallets/:wallet_id/actions/unlock', requirePermission('wallets.lock'), adminController.unlockWallet);

router.get('/topups', notImplemented('GET /admin/topups'));
router.get('/topups/:id', notImplemented('GET /admin/topups/{id}'));
router.get('/transfers', notImplemented('GET /admin/transfers'));
router.get('/transfers/:id', notImplemented('GET /admin/transfers/{id}'));

router.get('/transactions', notImplemented('GET /admin/transactions'));
router.get('/transactions/:id', notImplemented('GET /admin/transactions/{id}'));
router.get('/ledger-entries', notImplemented('GET /admin/ledger-entries'));
router.post('/transactions/reconcile', notImplemented('POST /admin/transactions/reconcile'));

router.get('/merchants', notImplemented('GET /admin/merchants'));
router.get('/merchants/:id', notImplemented('GET /admin/merchants/{id}'));
router.post('/merchants/:id/actions/approve', notImplemented('POST /admin/merchants/{id}/actions/approve'));
router.post('/merchants/:id/actions/reject', notImplemented('POST /admin/merchants/{id}/actions/reject'));
router.post('/merchants/:id/actions/suspend', notImplemented('POST /admin/merchants/{id}/actions/suspend'));
router.post('/merchants/:id/actions/activate', notImplemented('POST /admin/merchants/{id}/actions/activate'));
router.get('/merchants/:id/api-keys', notImplemented('GET /admin/merchants/{id}/api-keys'));

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
