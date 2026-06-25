const express = require('express');
const router = express.Router();
const { authenticateJwt, requireAdmin, requirePermission } = require('../../middlewares/auth.middleware');
const adminController = require('./admin.controller');
const notImplemented = require('../../utils/notImplemented');

// 1. GẮN MIDDLEWARE BẢO MẬT CHUNG CHO TOÀN BỘ ADMIN
router.use(authenticateJwt, requireAdmin);


// =================================================================
// PHẦN 1: CÁC MODULE ĐÃ TÁCH THÀNH THƯ MỤC RIÊNG
// =================================================================
// Thay vì gọi controller dài dòng, ta trỏ thẳng vào thư mục con.

// Module Logging & Audit (Chọc vào MongoDB bạn vừa làm)
// Đường dẫn thực tế sẽ là: /api/v1/admin/logs/...
router.use('/logs', require('./logs/logs.routes'));

/* * 🚀 KẾ HOẠCH TƯƠNG LAI: 
 * Khi nào bạn tạo xong file .routes.js trong các thư mục tương ứng, 
 * hãy mở comment các dòng dưới đây và XÓA các API lẻ tẻ ở Phần 2 đi nhé.
 */
// router.use('/dashboard', require('./dashboard/dashboard.routes'));
// router.use('/users', require('./users/users.routes'));
// router.use('/wallets', require('./wallets/wallets.routes'));
// router.use('/merchants', require('./merchants/merchants.routes'));
// router.use('/transactions', require('./transactions/transactions.routes'));
// router.use('/payments', require('./payments/payments.routes'));
// router.use('/webhooks', require('./webhooks/webhooks.routes'));
// router.use('/reports', require('./reports/reports.routes'));
// router.use('/settings', require('./settings/settings.routes'));


// =================================================================
// PHẦN 2: CÁC MODULE CHƯA TÁCH (Tạm thời giữ nguyên để App không sập)
// =================================================================

// --- Nhóm Quản lý Người dùng & Phân quyền ---
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

// --- Nhóm Quản lý Ví ---
router.get('/wallets', requirePermission('wallets.read'), adminController.listWallets);
router.get('/wallets/:wallet_id', requirePermission('wallets.read'), adminController.getWalletDetail);
router.get('/wallets/:wallet_id/summary', requirePermission('wallets.read'), adminController.getWalletSummary);
router.get('/wallets/:wallet_id/ledger', requirePermission('wallets.read'), adminController.getWalletLedger);
router.post('/wallets/:wallet_id/actions/lock', requirePermission('wallets.lock'), adminController.lockWallet);
router.post('/wallets/:wallet_id/actions/unlock', requirePermission('wallets.lock'), adminController.unlockWallet);

// --- Nhóm Đối tác (Merchants) ---
router.get('/merchants', notImplemented('GET /admin/merchants'));
router.get('/merchants/:id', notImplemented('GET /admin/merchants/{id}'));
router.post('/merchants/:id/actions/approve', notImplemented('POST /admin/merchants/{id}/actions/approve'));
router.post('/merchants/:id/actions/reject', notImplemented('POST /admin/merchants/{id}/actions/reject'));
router.post('/merchants/:id/actions/suspend', notImplemented('POST /admin/merchants/{id}/actions/suspend'));
router.post('/merchants/:id/actions/activate', notImplemented('POST /admin/merchants/{id}/actions/activate'));
router.get('/merchants/:id/api-keys', notImplemented('GET /admin/merchants/{id}/api-keys'));

// --- Nhóm Thanh toán (Payment Orders & QR) ---
router.get('/payment-orders', notImplemented('GET /admin/payment-orders'));
router.get('/payment-orders/:id', notImplemented('GET /admin/payment-orders/{id}'));
router.get('/payment-orders/:id/timeline', notImplemented('GET /admin/payment-orders/{id}/timeline'));
router.get('/payment-orders/:id/ledger', notImplemented('GET /admin/payment-orders/{id}/ledger'));
router.get('/payment-orders/:id/callbacks', notImplemented('GET /admin/payment-orders/{id}/callbacks'));

router.get('/qr-payments', notImplemented('GET /admin/qr-payments'));
router.get('/qr-payments/:id', notImplemented('GET /admin/qr-payments/{id}'));
router.post('/qr-payments/jobs/expire', notImplemented('POST /admin/qr-payments/jobs/expire'));

// --- Nhóm Giao dịch lõi (Transactions, Topup, Transfer, Refund) ---
router.get('/topups', notImplemented('GET /admin/topups'));
router.get('/topups/:id', notImplemented('GET /admin/topups/{id}'));
router.get('/transfers', notImplemented('GET /admin/transfers'));
router.get('/transfers/:id', notImplemented('GET /admin/transfers/{id}'));

router.get('/transactions', notImplemented('GET /admin/transactions'));
router.get('/transactions/:id', notImplemented('GET /admin/transactions/{id}'));
router.get('/ledger-entries', notImplemented('GET /admin/ledger-entries'));
router.post('/transactions/reconcile', notImplemented('POST /admin/transactions/reconcile'));

router.get('/refunds', notImplemented('GET /admin/refunds'));
router.get('/refunds/:id', notImplemented('GET /admin/refunds/{id}'));
router.post('/refunds', notImplemented('POST /admin/refunds'));

// --- Nhóm Webhooks ---
router.get('/webhooks', notImplemented('GET /admin/webhooks'));
router.get('/webhooks/:id', notImplemented('GET /admin/webhooks/{id}'));
router.post('/webhooks/:id/actions/retry', notImplemented('POST /admin/webhooks/{id}/actions/retry'));
router.post('/webhooks/jobs/retry-due', notImplemented('POST /admin/webhooks/jobs/retry-due'));

// --- Nhóm Dashboard ---
router.get('/dashboard/kpis', adminController.getDashboardKPIs);
router.get('/dashboard/transactions-chart', notImplemented('GET /admin/dashboard/transactions-chart'));
router.get('/dashboard/success-rate', notImplemented('GET /admin/dashboard/success-rate'));
router.get('/dashboard/top-merchants', notImplemented('GET /admin/dashboard/top-merchants'));
router.get('/dashboard/recent-activities', notImplemented('GET /admin/dashboard/recent-activities'));
router.get('/dashboard/alerts', notImplemented('GET /admin/dashboard/alerts'));

// --- Nhóm Báo cáo (Reports) ---
router.get('/reports/topups', notImplemented('GET /admin/reports/topups'));
router.get('/reports/transfers', notImplemented('GET /admin/reports/transfers'));
router.get('/reports/payments', notImplemented('GET /admin/reports/payments'));
router.get('/reports/refunds', notImplemented('GET /admin/reports/refunds'));
router.get('/reports/merchants', notImplemented('GET /admin/reports/merchants'));
router.get('/reports/webhooks', notImplemented('GET /admin/reports/webhooks'));
router.get('/reports/ledger', notImplemented('GET /admin/reports/ledger'));
router.get('/reports/export', notImplemented('GET /admin/reports/export'));

// --- Nhóm Cấu hình (Settings) ---
router.get('/settings', notImplemented('GET /admin/settings'));
router.patch('/settings/:key', notImplemented('PATCH /admin/settings/{key}'));
router.get('/settings/history', notImplemented('GET /admin/settings/history'));

// Đã XÓA 4 dòng liên quan đến /audit-logs và /system-logs vì đã được điều hướng về router.use('/logs') ở Phần 1.

module.exports = router;