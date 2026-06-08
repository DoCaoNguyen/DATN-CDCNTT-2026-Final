const express = require('express');
const router = express.Router();
const notificationController = require('./notification.controller');
const authMiddleware = require('../../middlewares/auth.middleware'); // Kéo middleware check login của bạn vào

// Endpoint để app mobile đăng ký FCM Token lên hệ thống
router.post('/register-device', authMiddleware, notificationController.registerDevice);

module.exports = router;