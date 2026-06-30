const express = require('express');
const router = express.Router();
const walletController = require('../controllers/wallet.controller');

router.get('/:userId', walletController.getLinkedWallets);
router.post('/link', walletController.linkWallet);

module.exports = router;
