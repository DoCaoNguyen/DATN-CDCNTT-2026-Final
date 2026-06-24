/**
 * Admin Dashboard Routes
 * 
 * Endpoints:
 * - GET    /kpis                  → getDashboardKPIs
 * - GET    /transactions-chart    → getTransactionsChart
 * - GET    /success-rate          → getSuccessRate
 * - GET    /top-merchants         → getTopMerchants
 * - GET    /recent-activities     → getRecentActivities
 * - GET    /alerts                → getAlerts
 */
const express = require('express');
const router = express.Router();
const dashboardController = require('./dashboard.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L866-871)

module.exports = router;
