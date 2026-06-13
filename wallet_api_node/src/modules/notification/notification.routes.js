const express = require('express');
const router = express.Router();
const notificationController = require('./notification.controller');
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
