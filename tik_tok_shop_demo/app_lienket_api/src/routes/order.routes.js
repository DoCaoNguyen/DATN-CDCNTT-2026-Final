const express = require('express');
const router = express.Router();
const OrderController = require('../controllers/order.controller');

router.post('/checkout', OrderController.checkout);

// [Thêm mới] Endpoint nhận Webhook báo kết quả thanh toán từ Ví Mio
router.post('/webhook/payment', OrderController.handlePaymentWebhook);

module.exports = router;
