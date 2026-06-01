const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transaction.controller');
const verifyToken = require('../middlewares/auth.middleware');

// Mọi API trong này đều phải qua cửa kiểm duyệt Token
router.use(verifyToken);

router.post('/deposit', transactionController.deposit);
router.post('/transfer', transactionController.transfer);

module.exports = router;