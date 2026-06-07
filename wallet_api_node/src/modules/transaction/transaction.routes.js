const express = require('express');
const router = express.Router();
const transactionController = require('./transaction.controller');
const verifyToken = require('../../middlewares/auth.middleware');


const withIdempotency = require('../../middlewares/idempotency.middleware');


router.use(verifyToken);


router.post('/deposit', withIdempotency, transactionController.deposit);
router.post('/transfer', withIdempotency, transactionController.transfer);
router.get('/history', transactionController.getHistory);

module.exports = router;