const express = require('express');
const router = express.Router();
const notificationController = require('./notification.controller');
<<<<<<< HEAD
const authMiddleware = require('../../middlewares/auth.middleware'); // Kéo middleware check login của bạn vào

// Endpoint để app mobile đăng ký FCM Token lên hệ thống
router.post('/register-device', authMiddleware, notificationController.registerDevice);

module.exports = router;
=======
const verifyToken = require('../../middlewares/auth.middleware');

/**
 * @swagger
 * /api/notifications/register-device:
 *   post:
 *     summary: Register or update user device FCM token
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - fcmToken
 *             properties:
 *               fcmToken:
 *                 type: string
 *               deviceName:
 *                 type: string
 *               deviceType:
 *                 type: string
 *                 enum: [ANDROID, IOS, WEB]
 *     responses:
 *       200:
 *         description: Success
 *       400:
 *         description: Missing fields
 *       401:
 *         description: Unauthorized
 */
router.post('/register-device', verifyToken, notificationController.registerDeviceToken);

module.exports = router;
>>>>>>> 17911097008a4a5c28a2a340113d4c6297ed2811
