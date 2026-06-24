/**
 * Admin Payments Routes
 * 
 * Endpoints:
 * - GET    /payment-orders                    → listPaymentOrders
 * - GET    /payment-orders/:id                → getPaymentOrderDetail
 * - GET    /payment-orders/:id/timeline       → getPaymentTimeline
 * - GET    /payment-orders/:id/ledger         → getPaymentLedger
 * - GET    /payment-orders/:id/callbacks      → getPaymentCallbacks
 * - GET    /qr-payments                       → listQrPayments
 * - GET    /qr-payments/:id                   → getQrPaymentDetail
 * - POST   /qr-payments/jobs/expire           → runExpireJob
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const paymentsController = require('./payments.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L686-724)

module.exports = router;
