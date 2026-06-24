/**
 * Admin Transactions Routes
 * 
 * Endpoints:
 * - GET    /topups              → listTopups
 * - GET    /topups/:id          → getTopupDetail
 * - GET    /transfers           → listTransfers
 * - GET    /transfers/:id       → getTransferDetail
 * - GET    /                    → listTransactions
 * - GET    /:id                 → getTransactionDetail
 * - GET    /ledger-entries      → listLedgerEntries
 * - POST   /reconcile          → runReconciliation
 * - GET    /refunds             → listRefunds
 * - GET    /refunds/:id         → getRefundDetail
 * - POST   /refunds             → createRefund
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const transactionsController = require('./transactions.controller');
const notImplemented = require('../../../utils/notImplemented');

// TODO: Di chuyển routes từ admin.routes.js (L515-563, L761-763)

module.exports = router;
