const express = require('express');
const router = express.Router();
const { authenticateJwt, requireAdmin } = require('../../middlewares/auth.middleware');
const notImplemented = require('../../utils/notImplemented');

/**
 * @swagger
 * tags:
 *   name: Topup
 *   description: User nap tien gia lap, idempotency, ledger va admin tra cuu topup
 */

/**
 * @swagger
 * /api/v1/topups:
 *   post:
 *     summary: User tao giao dich nap tien gia lap
 *     tags: [Topup]
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
 *             required: [amount, method]
 *             properties:
 *               amount:
 *                 type: integer
 *                 example: 100000
 *               method:
 *                 type: string
 *                 enum: [SANDBOX_BANK, SANDBOX_CARD]
 *               note:
 *                 type: string
 *     responses:
 *       201:
 *         description: Tao topup thanh cong
 *       501:
 *         description: Chua trien khai
 */
router.post('/', authenticateJwt, notImplemented('POST /topups'));

/**
 * @swagger
 * /api/v1/topups/me:
 *   get:
 *     summary: User xem lich su nap tien cua minh
 *     tags: [Topup]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sach topup cua user hien tai
 */
router.get('/me', authenticateJwt, notImplemented('GET /topups/me'));

/**
 * @swagger
 * /api/v1/topups/me/{id}:
 *   get:
 *     summary: User xem chi tiet giao dich nap tien cua minh
 *     tags: [Topup]
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
 *         description: Chi tiet topup
 */
router.get('/me/:id', authenticateJwt, notImplemented('GET /topups/me/{id}'));

/**
 * @swagger
 * /api/v1/topups/{id}/ledger:
 *   get:
 *     summary: User xem ledger cua topup neu thuoc ve minh
 *     tags: [Topup]
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
 *         description: Ledger entries cua topup
 */
router.get('/:id/ledger', authenticateJwt, notImplemented('GET /topups/{id}/ledger'));

module.exports = router;
