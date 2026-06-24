/**
 * Admin Merchants Routes
 * 
 * Endpoints:
 * - GET    /                          → listMerchants
 * - GET    /:id                       → getMerchantDetail
 * - POST   /:id/actions/approve       → approveMerchant
 * - POST   /:id/actions/reject        → rejectMerchant
 * - POST   /:id/actions/suspend       → suspendMerchant
 * - POST   /:id/actions/activate      → activateMerchant
 * - GET    /:id/api-keys              → getMerchantApiKeys
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const merchantsController = require('./merchants.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L630-636)

module.exports = router;
