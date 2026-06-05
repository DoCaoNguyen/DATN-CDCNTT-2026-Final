const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const verifyApiKey = require('../middlewares/merchant.middleware');
const verifyToken = require('../middlewares/auth.middleware');

// THÊM MIDDLEWARE IDEMPOTENCY
const withIdempotency = require('../middlewares/idempotency.middleware'); 

router.post('/create', verifyApiKey, paymentController.createOrder);

// Khi App gọi thanh toán, luồng sẽ đi qua: Xác thực Token -> Check Idempotency -> Xử lý trừ tiền
router.post('/process', verifyToken, withIdempotency, paymentController.processPayment);

module.exports = router;