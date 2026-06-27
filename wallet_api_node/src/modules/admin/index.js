/**
 * Admin Module - Root Router
 * 
 * Gom tất cả admin sub-routes vào 1 entry point.
 * File routes/index.js chỉ cần: router.use('/admin', require('../modules/admin/index'))
 * 
 * Cấu trúc:
 *   admin/
 *   ├── _shared/          → Code dùng chung (helpers, validators, pagination)
 *   ├── users/            → Quản lý users
 *   ├── roles/            → Quản lý roles/permissions
 *   ├── wallets/          → Quản lý ví
 *   ├── merchants/        → Quản lý merchant + API keys
 *   ├── transactions/     → Topups, transfers, refunds, ledger, reconcile
 *   ├── payments/         → Payment orders + QR payments
 *   ├── webhooks/         → Callback/webhook management
 *   ├── dashboard/        → KPIs, charts, alerts
 *   ├── reports/          → Báo cáo + export
 *   ├── settings/         → Cấu hình hệ thống
 *   ├── logs/             → Audit logs + system logs
 *   └── index.js          → File này (router gốc)
 */
const express = require('express');
const router = express.Router();
const { authenticateJwt, requireAdmin } = require('../../middlewares/auth.middleware');

// ═══════════════════════════════════════════
// Áp dụng auth middleware cho TẤT CẢ admin routes
// ═══════════════════════════════════════════
router.use(authenticateJwt, requireAdmin);

// ═══════════════════════════════════════════
// Gom tất cả sub-routes
// ═══════════════════════════════════════════
router.use('/',            require('./users/users.routes'));          // /admin/users, /admin/customers, /admin/staffs
router.use('/roles',       require('./roles/roles.routes'));          // /admin/roles
router.use('/permissions', require('./roles/permissions.routes'));    // /admin/permissions
router.use('/',            require('./wallets/wallets.routes'));      // /admin/wallets
router.use('/',            require('./merchants/merchants.routes'));  // /admin/merchants
router.use('/',            require('./transactions/transactions.routes')); // /admin/topups, /admin/transfers, /admin/ledger
router.use('/',            require('./payments/payments.routes'));    // /admin/payment-orders, /admin/qr-payments
router.use('/',            require('./webhooks/webhooks.routes'));    // /admin/webhooks
router.use('/dashboard',   require('./dashboard/dashboard.routes'));  // /admin/dashboard/*
router.use('/reports',     require('./reports/reports.routes'));      // /admin/reports/*
router.use('/',            require('./settings/settings.routes'));    // /admin/settings
router.use('/',            require('./logs/logs.routes'));            // /admin/audit-logs, /admin/system-logs

module.exports = router;
