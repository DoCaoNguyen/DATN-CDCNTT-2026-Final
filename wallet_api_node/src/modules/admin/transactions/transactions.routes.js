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



module.exports = router;
