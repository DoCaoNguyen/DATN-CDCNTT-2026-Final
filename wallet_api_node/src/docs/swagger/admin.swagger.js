/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: Admin quan tri user, wallet, merchant, payment, transaction, refund, webhook, dashboard, report, setting va audit
 */

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
 *             required: [new_password, confirm_new_password, reason]
 *             properties:
 *               new_password:
 *                 type: string
 *                 example: NewPassword@123
 *               confirm_new_password:
 *                 type: string
 *                 example: NewPassword@123
 *               reason:
 *                 type: string
 *                 example: User requested account recovery
 *     responses:
 *       200:
 *         description: Password reset
 *       400:
 *         description: Du lieu khong hop le
 *       403:
 *         description: Khong co quyen reset tai khoan nay
 * /api/v1/admin/users/{id}/audit-logs:
 *   get:
 *     summary: Admin xem audit log lien quan user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: action
 *         schema:
 *           type: string
 *       - in: query
 *         name: from
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: to
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: page_size
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Audit logs cua user
 */

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
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [reason]
 *             properties:
 *               reason:
 *                 type: string
 *                 example: Giao dịch bị nghi ngờ là gian lận
 *     responses:
 *       200:
 *         description: Wallet locked
 *       400:
 *         description: Thieu ly do hoac wallet_id khong hop le
 *       409:
 *         description: Vi da khoa hoac da dong
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
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [reason]
 *             properties:
 *               reason:
 *                 type: string
 *                 example: Đánh giá rủi ro đã hoàn thành
 *     responses:
 *       200:
 *         description: Wallet unlocked
 *       400:
 *         description: Thieu ly do hoac wallet_id khong hop le
 *       409:
 *         description: Vi khong bi khoa hoac da dong
 */

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