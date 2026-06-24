/**
 * Admin Users Routes
 * 
 * Endpoints:
 * - GET    /           → listUsers
 * - POST   /           → createUser
 * - GET    /:id        → getUserDetail
 * - PATCH  /:id        → updateUser
 * - GET    /:id/wallet → getUserWallet
 * - POST   /:id/actions/lock          → lockUser
 * - POST   /:id/actions/unlock        → unlockUser
 * - POST   /:id/actions/reset-password → resetUserPassword
 * - GET    /:id/audit-logs            → getUserAuditLogs
 * 
 * Roles & Permissions (notImplemented):
 * - GET    /roles
 * - POST   /roles
 * - GET    /roles/:id
 * - PATCH  /roles/:id
 * - GET    /permissions
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const usersController = require('./users.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L260-320)

module.exports = router;
