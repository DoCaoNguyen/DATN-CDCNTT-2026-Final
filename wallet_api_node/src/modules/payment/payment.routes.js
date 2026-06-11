const express = require('express');
const router = express.Router();
const paymentController = require('../../modules/payment/payment.controller');
const verifyApiKey = require('../../middlewares/merchant.middleware');
const verifyToken = require('../../middlewares/auth.middleware');

const withIdempotency = require('../../middlewares/idempotency.middleware'); 

/**
 * @swagger
 * tags:
 *   name: Payment
 *   description: Các API liên quan đến thanh toán hóa đơn và cổng thanh toán (Merchant / User QR)
 */

/**
 * @swagger
 * /api/v1/payment/create:
 *   post:
 *     summary: Tạo hóa đơn thanh toán động (Dành cho Merchant/Đối tác)
 *     tags: [Payment]
 *     security:
 *       - ApiKeyAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - amount
 *             properties:
 *               amount:
 *                 type: number
 *                 description: Số tiền cần thanh toán
 *                 example: 50000
 *               callback_url:
 *                 type: string
 *                 description: URL để nhận webhook thông báo kết quả thanh toán
 *                 example: "https://yourdomain.com/webhook"
 *               description:
 *                 type: string
 *                 description: Mô tả đơn hàng
 *                 example: "Thanh toán đơn hàng ORD123"
 *     responses:
 *       201:
 *         description: Tạo hóa đơn thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Tạo đơn hàng thanh toán thành công"
 *                 data:
 *                   type: object
 *                   properties:
 *                     order_id:
 *                       type: string
 *                     qr_token:
 *                       type: string
 *       400:
 *         description: Số tiền không hợp lệ
 *       401:
 *         description: API Key không hợp lệ hoặc thiếu
 *       500:
 *         description: Lỗi hệ thống
 */
router.post('/create', verifyApiKey, paymentController.createOrder);

/**
 * @swagger
 * /api/v1/payment/request:
 *   post:
 *     summary: Tạo QR nhận tiền cá nhân kèm số tiền tùy chỉnh
 *     tags: [Payment]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - amount
 *             properties:
 *               amount:
 *                 type: number
 *                 description: Số tiền muốn nhận
 *                 example: 100000
 *               description:
 *                 type: string
 *                 description: Nội dung nhắn gửi khi nhận tiền
 *                 example: "Chuyen tien an trua"
 *     responses:
 *       201:
 *         description: Tạo QR nhận tiền thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Tạo QR nhận tiền thành công"
 *                 data:
 *                   type: object
 *       400:
 *         description: Số tiền không hợp lệ
 *       401:
 *         description: Chưa xác thực
 *       500:
 *         description: Lỗi hệ thống
 */
router.post('/request', verifyToken, paymentController.requestMoney);

/**
 * @swagger
 * /api/v1/payment/process:
 *   post:
 *     summary: Thực hiện thanh toán hóa đơn từ QR Code của đối tác
 *     tags: [Payment]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - qr_token
 *             properties:
 *               qr_token:
 *                 type: string
 *                 description: Token QR lấy từ đơn hàng của Merchant
 *                 example: "f5e9464b9c384f124a8ca17da3a9f4f26bb3e5e554291ab13decdd55e9af0998"
 *     responses:
 *       200:
 *         description: Thanh toán thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Thanh toán thành công"
 *                 data:
 *                   type: object
 *                   properties:
 *                     order_id:
 *                       type: string
 *                     amount_paid:
 *                       type: string
 *                     balance_remaining:
 *                       type: string
 *       400:
 *         description: Số tiền không đủ, QR hết hạn hoặc đơn hàng đã xử lý
 *       401:
 *         description: Chưa xác thực
 *       500:
 *         description: Lỗi hệ thống
 */
router.post('/process', verifyToken, withIdempotency, paymentController.processPayment);

module.exports = router;