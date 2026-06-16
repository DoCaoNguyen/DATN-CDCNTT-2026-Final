const express = require('express');
const router = express.Router();
const { authenticateJwt } = require('../../middlewares/auth.middleware');
const notImplemented = require('../../utils/notImplemented');

/**
 * @swagger
 * tags:
 *   name: Transfer
 *   description: Chuyen tien giua vi, lookup nguoi nhan, idempotency va ledger
 */

/**
 * @swagger
 * /api/v1/transfers/receivers/lookup:
 *   get:
 *     summary: Tim nguoi nhan bang so dien thoai hoac ma vi
 *     tags: [Transfer]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: identifier
 *         required: true
 *         schema:
 *           type: string
 *         description: So dien thoai, email hoac wallet_no/wallet_code
 *     responses:
 *       200:
 *         description: Thong tin nguoi nhan da mask
 */
router.get('/receivers/lookup', authenticateJwt, notImplemented('GET /transfers/receivers/lookup'));

/**
 * @swagger
 * /api/v1/transfers:
 *   post:
 *     summary: User tao giao dich chuyen tien
 *     tags: [Transfer]
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
 *             required: [receiver_identifier, amount]
 *             properties:
 *               receiver_identifier:
 *                 type: string
 *                 example: "0912345678"
 *               amount:
 *                 type: integer
 *                 example: 50000
 *               description:
 *                 type: string
 *               pin_or_otp:
 *                 type: string
 *     responses:
 *       201:
 *         description: Chuyen tien thanh cong
 */
router.post('/', authenticateJwt, notImplemented('POST /transfers'));

/**
 * @swagger
 * /api/v1/transfers/me:
 *   get:
 *     summary: User xem lich su chuyen tien cua minh
 *     tags: [Transfer]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sach transfer cua user hien tai
 */
router.get('/me', authenticateJwt, notImplemented('GET /transfers/me'));

/**
 * @swagger
 * /api/v1/transfers/me/{id}:
 *   get:
 *     summary: User xem chi tiet chuyen tien cua minh
 *     tags: [Transfer]
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
 *         description: Chi tiet transfer
 */
router.get('/me/:id', authenticateJwt, notImplemented('GET /transfers/me/{id}'));

/**
 * @swagger
 * /api/v1/transfers/{id}/ledger:
 *   get:
 *     summary: User xem ledger cua transfer neu lien quan den vi cua minh
 *     tags: [Transfer]
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
 *         description: Ledger entries cua transfer
 */
router.get('/:id/ledger', authenticateJwt, notImplemented('GET /transfers/{id}/ledger'));

module.exports = router;
