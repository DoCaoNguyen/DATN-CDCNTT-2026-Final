const express = require('express');
const router = express.Router();
const redPacketController = require('./red_packet.controller');
const verifyToken = require('../../middlewares/auth.middleware');

/**
 * @swagger
 * tags:
 *   name: RedPacket
 *   description: API Lì Xì
 */

/**
 * @swagger
 * /api/v1/red-packet/create:
 *   post:
 *     summary: Tạo gói lì xì mới
 *     tags: [RedPacket]
 *     security:
 *       - bearerAuth: []
 */
router.post('/create', verifyToken, redPacketController.createRedPacket);

/**
 * @swagger
 * /api/v1/red-packet/{id}/claim:
 *   post:
 *     summary: Mở gói lì xì
 *     tags: [RedPacket]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:id/claim', verifyToken, redPacketController.claimRedPacket);

/**
 * @swagger
 * /api/v1/red-packet/{id}:
 *   get:
 *     summary: Lấy thông tin gói lì xì
 *     tags: [RedPacket]
 *     security:
 *       - bearerAuth: []
 */
router.get('/:id', verifyToken, redPacketController.getRedPacketDetails);

module.exports = router;
