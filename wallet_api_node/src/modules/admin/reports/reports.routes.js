/**
 * Admin Reports Routes
 * 
 * Endpoints:
 * - GET    /topups       → getTopupReport
 * - GET    /transfers    → getTransferReport
 * - GET    /payments     → getPaymentReport
 * - GET    /refunds      → getRefundReport
 * - GET    /merchants    → getMerchantReport
 * - GET    /webhooks     → getWebhookReport
 * - GET    /ledger       → getLedgerReport
 * - GET    /export       → exportReport
 */
const express = require('express');
const router = express.Router();
const reportsController = require('./reports.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L948-955)

module.exports = router;
