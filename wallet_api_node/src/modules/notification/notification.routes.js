const express = require('express');
const router = express.Router();
const notificationController = require('./notification.controller');
const verifyToken = require('../../middlewares/auth.middleware');

/**
 * @swagger
 * /api/v1/notifications/register-device:
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

/**
 * @swagger
 * /api/v1/notifications:
 *   get:
 *     summary: Lấy danh sách thông báo của user
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/', verifyToken, notificationController.getNotifications);

/**
 * @swagger
 * /api/v1/notifications/unread-count:
 *   get:
 *     summary: Lấy số lượng thông báo chưa đọc
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/unread-count', verifyToken, notificationController.getUnreadCount);

/**
 * @swagger
 * /api/v1/notifications/read:
 *   put:
 *     summary: Đánh dấu danh sách thông báo đã đọc
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
 *               - notificationIds
 *             properties:
 *               notificationIds:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Thành công
 */
router.put('/read', verifyToken, notificationController.markAsRead);

/**
 * @swagger
 * /api/v1/notifications/read-all:
 *   put:
 *     summary: Đánh dấu tất cả thông báo đã đọc
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.put('/read-all', verifyToken, notificationController.markAllAsRead);

module.exports = router;
