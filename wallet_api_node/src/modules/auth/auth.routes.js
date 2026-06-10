const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const verifyToken = require('../../middlewares/auth.middleware');

router.post('/send-otp', authController.sendOtp);
router.post('/verify-otp', authController.verifyOtp);
router.post('/set-password', authController.setPassword);
router.post('/login', authController.login);
router.post('/logout', verifyToken, authController.logout);

module.exports = router;