const express = require('express');
const rateLimit = require('express-rate-limit');
const authController = require('./auth.controller');
const { authenticateJwt } = require('../../middlewares/auth.middleware');

const router = express.Router();

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 phút
    limit: 10, // 10 lần
    message: { error: 'Bạn thao tác quá nhanh, vui lòng thử lại sau 15 phút.' }
});

router.post('/check-phone', authController.checkPhone);

router.post('/register', authLimiter, authController.register);

router.post('/login', authLimiter, authController.login);

router.post('/set-password', authController.setPassword);

router.post('/forgot-password-otp', authController.forgotPasswordOtp);

router.post('/reset-password', authController.resetPassword);

router.post('/forgot-password', authLimiter, authController.forgotPassword);

router.post('/reset-password', authLimiter, authController.resetPassword);

router.post('/logout', authenticateJwt, authController.logout);

router.post('/change-password', authenticateJwt, authController.changePassword);

router.get('/me', authenticateJwt, authController.me);

// Mobile OTP registration and password recovery endpoints.

router.post('/check-phone', authController.checkPhone);

router.post('/send-otp', authLimiter, authController.sendOtp);

router.post('/verify-otp', authLimiter, authController.verifyOtp);

router.post('/set-password', authLimiter, authController.setPassword);

router.post('/forgot-password-otp', authLimiter, authController.forgotPasswordOtp);

module.exports = router;
