const express = require('express');
const router = express.Router();
const { authenticateJwt } = require('../../middlewares/auth.middleware');
const notImplemented = require('../../utils/notImplemented');

/**
 * @swagger
 * tags:
 *   name: Transaction
 *   description: Lich su giao dich, ledger entries va doi soat ledger
 */

/**
 * @swagger
 * /api/v1/transactions/me:
 *   get:
 *     summary: User xem lich su giao dich lien quan den vi cua minh
 *     tags: [Transaction]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Danh sach giao dich cua user hien tai
 */
router.get('/me', authenticateJwt, notImplemented('GET /transactions/me'));

/**
 * @swagger
 * /api/v1/transactions/me/{id}:
 *   get:
 *     summary: User xem chi tiet giao dich cua minh
 *     tags: [Transaction]
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
 *         description: Chi tiet giao dich
 */
router.get('/me/:id', authenticateJwt, notImplemented('GET /transactions/me/{id}'));

/**
 * @swagger
 * /api/v1/transactions/{id}/ledger:
 *   get:
 *     summary: Xem ledger entries cua mot giao dich
 *     tags: [Transaction]
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
 *         description: Ledger entries cua giao dich
 */
router.get('/:id/ledger', authenticateJwt, notImplemented('GET /transactions/{id}/ledger'));

module.exports = router;
