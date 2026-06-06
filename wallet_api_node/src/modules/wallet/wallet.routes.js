const express = require('express');
const router = express.Router();
const walletController = require('./wallet.controller');
const verifyToken = require('../../middlewares/auth.middleware');


router.use(verifyToken);


router.get('/balance', walletController.getBalance);
router.post('/set-code', walletController.setWalletCode);
router.get('/check-code/:code', walletController.checkWalletCode);

module.exports = router;