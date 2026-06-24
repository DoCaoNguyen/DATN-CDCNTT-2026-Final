/**
 * Admin Webhooks Routes
 * 
 * Endpoints:
 * - GET    /                      → listWebhooks
 * - GET    /:id                   → getWebhookDetail
 * - POST   /:id/actions/retry     → retryWebhook
 * - POST   /jobs/retry-due        → runRetryDueJob
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const webhooksController = require('./webhooks.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L804-807)

module.exports = router;
