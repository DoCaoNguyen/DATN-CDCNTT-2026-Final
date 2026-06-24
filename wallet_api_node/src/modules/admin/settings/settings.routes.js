/**
 * Admin Settings Routes
 * 
 * Endpoints:
 * - GET    /            → listSettings
 * - PATCH  /:key        → updateSetting
 * - GET    /history     → getSettingHistory
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const settingsController = require('./settings.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L987-989)

module.exports = router;
