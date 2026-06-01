const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');

// Import cả 2 loại Middleware bảo vệ
const verifyApiKey = require('../middlewares/merchant.middleware');
const verifyToken = require('../middlewares/auth.middleware');

// 1. Route cho Merchant (Máy tính tiền quán nước gọi)
// Sử dụng Header: x-api-key
router.post('/create', verifyApiKey, paymentController.createOrder);

// 2. Route cho Mobile App (Người dùng cầm điện thoại quét)
// Sử dụng Header: Authorization: Bearer <token>
router.post('/process', verifyToken, paymentController.processPayment);

module.exports = router;