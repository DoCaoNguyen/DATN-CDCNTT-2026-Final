/**
 * Admin Logs Routes
 * 
 * Endpoints:
 * - GET    /audit-logs                      → listAuditLogs
 * - GET    /audit-logs/:id                  → getAuditLogDetail
 * - GET    /system-logs                     → listSystemLogs
 * - GET    /payment-traces/:payment_order_id → getPaymentTrace
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const logsController = require('./logs.controller');
const notImplemented = require('../../../utils/notImplemented');

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



module.exports = router;
