const express = require('express');
const router = express.Router();
const paymentController = require('../../modules/payment/payment.controller');
const { verifyApiKey, verifyApiKeyWithSignature } = require('../../middlewares/merchant.middleware');
const verifyToken = require('../../middlewares/auth.middleware');

const withIdempotency = require('../../middlewares/idempotency.middleware'); 

// Sử dụng cấu hình Multer tập trung (có fileFilter + limits bảo mật)
const upload = require('../../config/multer');

router.post('/create', verifyApiKey, paymentController.createOrder);

router.post('/cancel', verifyApiKeyWithSignature, paymentController.cancelOrder);

router.get('/status', verifyApiKey, paymentController.getOrderStatus);

router.get('/transaction/:id', verifyApiKey, paymentController.getPaymentTransaction);

router.get('/preview', verifyToken, paymentController.previewPayment);

router.post('/request', verifyToken, paymentController.requestMoney);

router.post('/process', verifyToken, upload.single('face_image'), withIdempotency, paymentController.processPayment);



module.exports = router;