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

/**
 * @swagger
 * /api/v1/admin/users:
 *   get:
 *     summary: Admin xem danh sach user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [ACTIVE, PENDING_VERIFY, LOCKED, BLOCKED, INACTIVE]
 *       - in: query
 *         name: user_type
 *         schema:
 *           type: string
 *           enum: [USER, MERCHANT_USER, ADMIN, SUPER_ADMIN, SUPPORT_STAFF]
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Danh sach user
 *   post:
 *     summary: Admin tao user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [full_name, password]
 *             properties:
 *               full_name:
 *                 type: string
 *               username:
 *                 type: string
 *               email:
 *                 type: string
 *               phone:
 *                 type: string
 *               password:
 *                 type: string
 *                 example: Password@123
 *     responses:
 *       201:
 *         description: User created
 * /api/v1/admin/users/{id}:
 *   get:
 *     summary: Admin xem chi tiet user
 *     tags: [Admin]
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
 *         description: User detail
 *   patch:
 *     summary: Admin cap nhat user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               full_name:
 *                 type: string
 *               username:
 *                 type: string
 *               email:
 *                 type: string
 *               phone:
 *                 type: string
 *               is_kyc_verified:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: User updated
 * /api/v1/admin/users/{id}/wallet:
 *   get:
 *     summary: Admin xem vi cua user
 *     tags: [Admin]
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
 *         description: User wallet
 * /api/v1/admin/users/{id}/actions/lock:
 *   post:
 *     summary: Admin khoa user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: User locked
 * /api/v1/admin/users/{id}/actions/unlock:
 *   post:
 *     summary: Admin mo khoa user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: User unlocked
 * /api/v1/admin/users/{id}/actions/reset-password:
 *   post:
 *     summary: Admin reset password cho user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Password reset
 */
router.get('/users', requirePermission('admin.users.manage'), adminController.listUsers);
router.post('/users', requirePermission('admin.users.manage'), adminController.createUser);
router.get('/users/:id', requirePermission('admin.users.manage'), adminController.getUserDetail);
router.patch('/users/:id', requirePermission('admin.users.manage'), adminController.updateUser);
router.get('/users/:id/wallet', requirePermission('admin.users.manage', 'wallets.read'), adminController.getUserWallet);
router.post('/users/:id/actions/lock', requirePermission('admin.users.manage'), adminController.lockUser);
router.post('/users/:id/actions/unlock', requirePermission('admin.users.manage'), adminController.unlockUser);
router.post('/users/:id/actions/reset-password', notImplemented('POST /admin/users/{id}/actions/reset-password'));

/**
 * @swagger
 * /api/v1/admin/roles:
 *   get:
 *     summary: Admin xem danh sach role
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Roles
 *   post:
 *     summary: Super Admin tao role
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       201:
 *         description: Role created
 * /api/v1/admin/roles/{id}:
 *   get:
 *     summary: Admin xem chi tiet role
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Role detail
 *   patch:
 *     summary: Super Admin cap nhat role
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Role updated
 * /api/v1/admin/permissions:
 *   get:
 *     summary: Admin xem danh sach permission
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Permissions
 */
router.get('/roles', notImplemented('GET /admin/roles'));
router.post('/roles', notImplemented('POST /admin/roles'));
router.get('/roles/:id', notImplemented('GET /admin/roles/{id}'));
router.patch('/roles/:id', notImplemented('PATCH /admin/roles/{id}'));
router.get('/permissions', notImplemented('GET /admin/permissions'));

/**
 * @swagger
 * /api/v1/admin/wallets:
 *   get:
 *     summary: Admin xem danh sach vi
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [ACTIVE, LOCKED, CLOSED]
 *       - in: query
 *         name: user_id
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Wallets
 * /api/v1/admin/wallets/{wallet_id}:
 *   get:
 *     summary: Admin xem chi tiet vi
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: wallet_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Wallet detail
 * /api/v1/admin/wallets/{wallet_id}/summary:
 *   get:
 *     summary: Admin xem tong quan vi
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: wallet_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Wallet summary
 * /api/v1/admin/wallets/{wallet_id}/ledger:
 *   get:
 *     summary: Admin xem ledger cua vi
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: wallet_id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Wallet ledger
 * /api/v1/admin/wallets/{wallet_id}/actions/lock:
 *   post:
 *     summary: Admin khoa vi
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: wallet_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Wallet locked
 * /api/v1/admin/wallets/{wallet_id}/actions/unlock:
 *   post:
 *     summary: Admin mo khoa vi
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: wallet_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Wallet unlocked
 */
router.get('/wallets', requirePermission('wallets.read'), adminController.listWallets);
router.get('/wallets/:wallet_id', requirePermission('wallets.read'), adminController.getWalletDetail);
router.get('/wallets/:wallet_id/summary', requirePermission('wallets.read'), adminController.getWalletSummary);
router.get('/wallets/:wallet_id/ledger', requirePermission('wallets.read'), adminController.getWalletLedger);
router.post('/wallets/:wallet_id/actions/lock', notImplemented('POST /admin/wallets/{wallet_id}/actions/lock'));
router.post('/wallets/:wallet_id/actions/unlock', notImplemented('POST /admin/wallets/{wallet_id}/actions/unlock'));

/**
 * @swagger
 * /api/v1/admin/topups:
 *   get:
 *     summary: Admin xem toan bo topup
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Topups
 * /api/v1/admin/topups/{id}:
 *   get:
 *     summary: Admin xem chi tiet topup
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Topup detail
 * /api/v1/admin/transfers:
 *   get:
 *     summary: Admin xem toan bo transfer
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Transfers
 * /api/v1/admin/transfers/{id}:
 *   get:
 *     summary: Admin xem chi tiet transfer
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Transfer detail
 */
router.get('/topups', notImplemented('GET /admin/topups'));
router.get('/topups/:id', notImplemented('GET /admin/topups/{id}'));
router.get('/transfers', notImplemented('GET /admin/transfers'));
router.get('/transfers/:id', notImplemented('GET /admin/transfers/{id}'));

/**
 * @swagger
 * /api/v1/admin/transactions:
 *   get:
 *     summary: Admin xem toan bo giao dich
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Transactions
 * /api/v1/admin/transactions/{id}:
 *   get:
 *     summary: Admin xem chi tiet giao dich
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Transaction detail
 * /api/v1/admin/ledger-entries:
 *   get:
 *     summary: Admin tra cuu ledger entries
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Ledger entries
 * /api/v1/admin/transactions/reconcile:
 *   post:
 *     summary: Admin chay doi soat ledger
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Reconcile result
 */
router.get('/transactions', notImplemented('GET /admin/transactions'));
router.get('/transactions/:id', notImplemented('GET /admin/transactions/{id}'));
router.get('/ledger-entries', notImplemented('GET /admin/ledger-entries'));
router.post('/transactions/reconcile', notImplemented('POST /admin/transactions/reconcile'));

/**
 * @swagger
 * /api/v1/admin/merchants:
 *   get:
 *     summary: Admin xem danh sach merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchants
 * /api/v1/admin/merchants/{id}:
 *   get:
 *     summary: Admin xem chi tiet merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant detail
 * /api/v1/admin/merchants/{id}/actions/approve:
 *   post:
 *     summary: Admin duyet merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant approved
 * /api/v1/admin/merchants/{id}/actions/reject:
 *   post:
 *     summary: Admin tu choi merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant rejected
 * /api/v1/admin/merchants/{id}/actions/suspend:
 *   post:
 *     summary: Admin tam ngung merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant suspended
 * /api/v1/admin/merchants/{id}/actions/activate:
 *   post:
 *     summary: Admin kich hoat lai merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant activated
 * /api/v1/admin/merchants/{id}/api-keys:
 *   get:
 *     summary: Admin xem API keys cua merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant API keys
 */
router.get('/merchants', notImplemented('GET /admin/merchants'));
router.get('/merchants/:id', notImplemented('GET /admin/merchants/{id}'));
router.post('/merchants/:id/actions/approve', notImplemented('POST /admin/merchants/{id}/actions/approve'));
router.post('/merchants/:id/actions/reject', notImplemented('POST /admin/merchants/{id}/actions/reject'));
router.post('/merchants/:id/actions/suspend', notImplemented('POST /admin/merchants/{id}/actions/suspend'));
router.post('/merchants/:id/actions/activate', notImplemented('POST /admin/merchants/{id}/actions/activate'));
router.get('/merchants/:id/api-keys', notImplemented('GET /admin/merchants/{id}/api-keys'));

/**
 * @swagger
 * /api/v1/admin/payment-orders:
 *   get:
 *     summary: Admin xem danh sach payment orders
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment orders
 * /api/v1/admin/payment-orders/{id}:
 *   get:
 *     summary: Admin xem chi tiet payment order
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment order detail
 * /api/v1/admin/payment-orders/{id}/timeline:
 *   get:
 *     summary: Admin xem timeline payment flow
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment timeline
 * /api/v1/admin/payment-orders/{id}/ledger:
 *   get:
 *     summary: Admin xem ledger cua payment
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment ledger
 * /api/v1/admin/payment-orders/{id}/callbacks:
 *   get:
 *     summary: Admin xem callback cua payment
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment callbacks
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
 *     summary: Admin tra cuu QR payments
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: QR payments
 * /api/v1/admin/qr-payments/{id}:
 *   get:
 *     summary: Admin xem chi tiet QR/payment flow
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: QR payment detail
 * /api/v1/admin/qr-payments/jobs/expire:
 *   post:
 *     summary: Admin chay job expire QR demo
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Expire job result
 */
router.get('/qr-payments', notImplemented('GET /admin/qr-payments'));
router.get('/qr-payments/:id', notImplemented('GET /admin/qr-payments/{id}'));
router.post('/qr-payments/jobs/expire', notImplemented('POST /admin/qr-payments/jobs/expire'));

/**
 * @swagger
 * /api/v1/admin/refunds:
 *   get:
 *     summary: Admin xem toan bo refund
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Refunds
 *   post:
 *     summary: Admin tao refund
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: header
 *         name: Idempotency-Key
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       201:
 *         description: Refund created
 * /api/v1/admin/refunds/{id}:
 *   get:
 *     summary: Admin xem chi tiet refund
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Refund detail
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
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Webhooks
 * /api/v1/admin/webhooks/{id}:
 *   get:
 *     summary: Admin xem chi tiet callback/webhook
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Webhook detail
 * /api/v1/admin/webhooks/{id}/actions/retry:
 *   post:
 *     summary: Admin retry callback
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Retry queued
 * /api/v1/admin/webhooks/jobs/retry-due:
 *   post:
 *     summary: Admin chay job retry due demo
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Retry due job result
 */
router.get('/webhooks', notImplemented('GET /admin/webhooks'));
router.get('/webhooks/:id', notImplemented('GET /admin/webhooks/{id}'));
router.post('/webhooks/:id/actions/retry', notImplemented('POST /admin/webhooks/{id}/actions/retry'));
router.post('/webhooks/jobs/retry-due', notImplemented('POST /admin/webhooks/jobs/retry-due'));

/**
 * @swagger
 * /api/v1/admin/dashboard/kpis:
 *   get:
 *     summary: Admin dashboard KPIs
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard KPIs
 * /api/v1/admin/dashboard/transactions-chart:
 *   get:
 *     summary: Admin bieu do giao dich
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Transaction chart
 * /api/v1/admin/dashboard/success-rate:
 *   get:
 *     summary: Admin ty le thanh cong
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Success rate
 * /api/v1/admin/dashboard/top-merchants:
 *   get:
 *     summary: Admin top merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Top merchants
 * /api/v1/admin/dashboard/recent-activities:
 *   get:
 *     summary: Admin hoat dong gan day
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Recent activities
 * /api/v1/admin/dashboard/alerts:
 *   get:
 *     summary: Admin canh bao he thong
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: System alerts
 */
router.get('/dashboard/kpis', notImplemented('GET /admin/dashboard/kpis'));
router.get('/dashboard/transactions-chart', notImplemented('GET /admin/dashboard/transactions-chart'));
router.get('/dashboard/success-rate', notImplemented('GET /admin/dashboard/success-rate'));
router.get('/dashboard/top-merchants', notImplemented('GET /admin/dashboard/top-merchants'));
router.get('/dashboard/recent-activities', notImplemented('GET /admin/dashboard/recent-activities'));
router.get('/dashboard/alerts', notImplemented('GET /admin/dashboard/alerts'));

/**
 * @swagger
 * /api/v1/admin/reports/topups:
 *   get:
 *     summary: Bao cao topup
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Topup report
 * /api/v1/admin/reports/transfers:
 *   get:
 *     summary: Bao cao transfer
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Transfer report
 * /api/v1/admin/reports/payments:
 *   get:
 *     summary: Bao cao payment
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment report
 * /api/v1/admin/reports/refunds:
 *   get:
 *     summary: Bao cao refund
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Refund report
 * /api/v1/admin/reports/merchants:
 *   get:
 *     summary: Bao cao merchant
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant report
 * /api/v1/admin/reports/webhooks:
 *   get:
 *     summary: Bao cao webhook
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Webhook report
 * /api/v1/admin/reports/ledger:
 *   get:
 *     summary: Bao cao ledger
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Ledger report
 * /api/v1/admin/reports/export:
 *   get:
 *     summary: Export bao cao
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Report export file
 */
router.get('/reports/topups', notImplemented('GET /admin/reports/topups'));
router.get('/reports/transfers', notImplemented('GET /admin/reports/transfers'));
router.get('/reports/payments', notImplemented('GET /admin/reports/payments'));
router.get('/reports/refunds', notImplemented('GET /admin/reports/refunds'));
router.get('/reports/merchants', notImplemented('GET /admin/reports/merchants'));
router.get('/reports/webhooks', notImplemented('GET /admin/reports/webhooks'));
router.get('/reports/ledger', notImplemented('GET /admin/reports/ledger'));
router.get('/reports/export', notImplemented('GET /admin/reports/export'));

/**
 * @swagger
 * /api/v1/admin/settings:
 *   get:
 *     summary: Admin xem cau hinh he thong
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Settings
 * /api/v1/admin/settings/{key}:
 *   patch:
 *     summary: Admin cap nhat mot setting
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Setting updated
 * /api/v1/admin/settings/history:
 *   get:
 *     summary: Admin xem lich su thay doi setting
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Setting histories
 */
router.get('/settings', notImplemented('GET /admin/settings'));
router.patch('/settings/:key', notImplemented('PATCH /admin/settings/{key}'));
router.get('/settings/history', notImplemented('GET /admin/settings/history'));

/**
 * @swagger
 * /api/v1/admin/audit-logs:
 *   get:
 *     summary: Admin xem audit logs
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Audit logs
 * /api/v1/admin/audit-logs/{id}:
 *   get:
 *     summary: Admin xem chi tiet audit log
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Audit log detail
 * /api/v1/admin/system-logs:
 *   get:
 *     summary: Admin xem system logs
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: System logs
 * /api/v1/admin/payment-traces/{payment_order_id}:
 *   get:
 *     summary: Admin trace payment flow
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Payment trace
 */
router.get('/audit-logs', notImplemented('GET /admin/audit-logs'));
router.get('/audit-logs/:id', notImplemented('GET /admin/audit-logs/{id}'));
router.get('/system-logs', notImplemented('GET /admin/system-logs'));
router.get('/payment-traces/:payment_order_id', notImplemented('GET /admin/payment-traces/{payment_order_id}'));

module.exports = router;
