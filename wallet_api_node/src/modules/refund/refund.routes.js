const express = require('express');
const router = express.Router();
const { authenticateJwt } = require('../../middlewares/auth.middleware');
const verifyApiKey = require('../../middlewares/merchant.middleware');
const notImplemented = require('../../utils/notImplemented');

/**
 * @swagger
 * tags:
 *   name: Refund
 *   description: Merchant/Admin tao refund, user/merchant/admin tra cuu refund va ledger/callback phat sinh
 */

/**
 * @swagger
 * /api/v1/refunds/me:
 *   get:
 *     summary: User xem refund lien quan den vi cua minh
 *     tags: [Refund]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sach refund cua user
 */
router.get('/refunds/me', authenticateJwt, notImplemented('GET /refunds/me'));

/**
 * @swagger
 * /api/v1/merchant/refunds:
 *   post:
 *     summary: Merchant tao refund cho payment da thanh toan
 *     tags: [Refund]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: header
 *         name: Idempotency-Key
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [payment_order_id, amount, reason]
 *             properties:
 *               payment_order_id:
 *                 type: string
 *               amount:
 *                 type: integer
 *               reason:
 *                 type: string
 *     responses:
 *       201:
 *         description: Refund created
 *   get:
 *     summary: Merchant xem danh sach refund cua minh
 *     tags: [Refund]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Merchant refunds
 */
router.post('/merchant/refunds', authenticateJwt, notImplemented('POST /merchant/refunds'));
router.get('/merchant/refunds', authenticateJwt, notImplemented('GET /merchant/refunds'));

/**
 * @swagger
 * /api/v1/merchant/refunds/{id}:
 *   get:
 *     summary: Merchant xem chi tiet refund cua minh
 *     tags: [Refund]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Refund detail
 */
router.get('/merchant/refunds/:id', authenticateJwt, notImplemented('GET /merchant/refunds/{id}'));

module.exports = router;
