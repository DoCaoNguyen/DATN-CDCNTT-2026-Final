const express = require('express');
const router = express.Router();
const paymentController = require('../../modules/payment/payment.controller');
const verifyApiKey = require('../../middlewares/merchant.middleware');
const verifyToken = require('../../middlewares/auth.middleware');


const withIdempotency = require('../../middlewares/idempotency.middleware'); 

router.post('/create', verifyApiKey, paymentController.createOrder);

// Tạo QR nhận tiền cho người dùng (xác thực bằng JWT)
router.post('/request', verifyToken, paymentController.requestMoney);

router.post('/process', verifyToken, withIdempotency, paymentController.processPayment);

module.exports = router;