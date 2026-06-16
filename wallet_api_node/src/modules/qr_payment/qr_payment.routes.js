const express = require('express');
const router = express.Router();
const { authenticateJwt, requireAdmin } = require('../../middlewares/auth.middleware');
const notImplemented = require('../../utils/notImplemented');

/**
 * @swagger
 * tags:
 *   name: QR Payment
 *   description: User quet QR merchant, resolve QR, confirm/cancel payment va admin tra cuu QR
 */

/**
 * @swagger
 * /api/v1/qr-payments/{qr_token}:
 *   get:
 *     summary: Resolve QR token va xem thong tin thanh toan
 *     tags: [QR Payment]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: qr_token
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Thong tin payment order cua QR
 */
router.get('/:qr_token', authenticateJwt, notImplemented('GET /qr-payments/{qr_token}'));

/**
 * @swagger
 * /api/v1/qr-payments/{qr_token}/confirm:
 *   post:
 *     summary: User xac nhan thanh toan QR
 *     tags: [QR Payment]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: header
 *         name: Idempotency-Key
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: qr_token
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               pin_or_otp:
 *                 type: string
 *     responses:
 *       200:
 *         description: Thanh toan QR thanh cong
 */
router.post('/:qr_token/confirm', authenticateJwt, notImplemented('POST /qr-payments/{qr_token}/confirm'));

/**
 * @swagger
 * /api/v1/qr-payments/{qr_token}/cancel:
 *   post:
 *     summary: User huy thao tac thanh toan QR tren app
 *     tags: [QR Payment]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: qr_token
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Huy thao tac QR thanh cong
 */
router.post('/:qr_token/cancel', authenticateJwt, notImplemented('POST /qr-payments/{qr_token}/cancel'));

module.exports = router;
