/**
 * Admin Wallets Routes
 * 
 * Endpoints:
 * - GET    /                           → listWallets
 * - GET    /:wallet_id                 → getWalletDetail
 * - GET    /:wallet_id/summary         → getWalletSummary
 * - GET    /:wallet_id/ledger          → getWalletLedger
 * - POST   /:wallet_id/actions/lock    → lockWallet
 * - POST   /:wallet_id/actions/unlock  → unlockWallet
 */
const express = require('express');
const router = express.Router();
const { requirePermission } = require('../../../middlewares/auth.middleware');
const walletsController = require('./wallets.controller');

// TODO: Di chuyển routes từ admin.routes.js (L469-474)

module.exports = router;
