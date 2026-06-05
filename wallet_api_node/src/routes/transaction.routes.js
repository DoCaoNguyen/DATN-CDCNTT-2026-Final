const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transaction.controller');
const verifyToken = require('../middlewares/auth.middleware');

// Import Middleware chống Double Payment
const withIdempotency = require('../middlewares/idempotency.middleware');

// Mọi API trong này đều phải qua cửa kiểm duyệt Token
router.use(verifyToken);

// Gắn chốt chặn Idempotency vào trước Controller để bảo vệ giao dịch
router.post('/deposit', withIdempotency, transactionController.deposit);
router.post('/transfer', withIdempotency, transactionController.transfer);

module.exports = router;