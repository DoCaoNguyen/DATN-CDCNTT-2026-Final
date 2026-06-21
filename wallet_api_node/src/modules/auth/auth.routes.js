const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const verifyToken = require('../../middlewares/auth.middleware');

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: Các API đăng ký, đăng nhập và xác thực OTP
 */

router.post('/check-phone', authController.checkPhone);

/**
 * @swagger
 * /api/v1/auth/send-otp:
 *   post:
 *     summary: Gửi mã OTP xác thực qua số điện thoại/email
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *             properties:
 *               phone:
 *                 type: string
 *                 description: Số điện thoại nhận OTP
 *                 example: "0987654321"
 *               email:
 *                 type: string
 *                 description: Email để đồng bộ hoặc gửi thông tin
 *                 example: "user@example.com"
 *     responses:
 *       200:
 *         description: Đã gửi mã OTP thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Đã gửi mã OTP qua tin nhắn SMS"
 *       400:
 *         description: Thiếu số điện thoại hoặc thông tin đã tồn tại
 *       403:
 *         description: Tài khoản bị tạm khóa bảo mật
 *       500:
 *         description: Lỗi server nội bộ
 */
router.post('/send-otp', authController.sendOtp);

/**
 * @swagger
 * /api/v1/auth/verify-otp:
 *   post:
 *     summary: Xác thực mã OTP nhận được
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *               - otp
 *             properties:
 *               phone:
 *                 type: string
 *                 example: "0987654321"
 *               otp:
 *                 type: string
 *                 description: Mã OTP gồm 6 chữ số
 *                 example: "123456"
 *     responses:
 *       200:
 *         description: Xác thực OTP thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Xác thực OTP thành công"
 *                 register_token:
 *                   type: string
 *                   description: JWT token dùng để thiết lập mật khẩu
 *                   example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
 *       400:
 *         description: Mã OTP sai hoặc đã hết hạn
 *       403:
 *         description: Tài khoản bị khóa do nhập sai quá nhiều lần
 */
router.post('/verify-otp', authController.verifyOtp);

/**
 * @swagger
 * /api/v1/auth/set-password:
 *   post:
 *     summary: Thiết lập mật khẩu và khởi tạo ví cho tài khoản mới
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - register_token
 *               - password
 *             properties:
 *               register_token:
 *                 type: string
 *                 description: Token nhận được sau khi xác thực OTP thành công
 *                 example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
 *               password:
 *                 type: string
 *                 description: Mật khẩu mong muốn cho tài khoản
 *                 example: "SecurePass123!"
 *     responses:
 *       201:
 *         description: Tạo tài khoản và ví thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Tạo tài khoản và Ví thành công!"
 *       400:
 *         description: Thiếu tham số bắt buộc
 *       401:
 *         description: Token đăng ký không hợp lệ hoặc đã hết hạn
 *       500:
 *         description: Lỗi hệ thống nội bộ
 */
router.post('/set-password', authController.setPassword);

router.post('/forgot-password-otp', authController.forgotPasswordOtp);
router.post('/reset-password', authController.resetPassword);

/**
 * @swagger
 * /api/v1/auth/login:
 *   post:
 *     summary: Đăng nhập hệ thống bằng SĐT hoặc Email
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - identifier
 *               - password
 *             properties:
 *               identifier:
 *                 type: string
 *                 description: Số điện thoại hoặc Email đăng ký
 *                 example: "0987654321"
 *               password:
 *                 type: string
 *                 example: "SecurePass123!"
 *     responses:
 *       200:
 *         description: Đăng nhập thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Đăng nhập thành công"
 *                 data:
 *                   type: object
 *                   properties:
 *                     token:
 *                       type: string
 *                       description: JWT Access Token dùng cho các API tiếp theo
 *                     user:
 *                       type: object
 *                       properties:
 *                         user_id:
 *                           type: string
 *                         full_name:
 *                           type: string
 *                         phone:
 *                           type: string
 *                         email:
 *                           type: string
 *       400:
 *         description: Thiếu thông tin đăng nhập
 *       401:
 *         description: Sai thông tin đăng nhập (mật khẩu)
 *       403:
 *         description: Tài khoản bị khóa hoặc chưa kích hoạt
 */
router.post('/login', authController.login);

/**
 * @swagger
 * /api/v1/auth/logout:
 *   post:
 *     summary: Đăng xuất khỏi hệ thống
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Đăng xuất thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Đăng xuất thành công"
 *       401:
 *         description: Token không hợp lệ hoặc thiếu token
 *       500:
 *         description: Lỗi hệ thống
 */
router.post('/logout', verifyToken, authController.logout);

/**
 * @swagger
 * /api/v1/auth/refresh-token:
 *   post:
 *     summary: Làm mới Access Token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refresh_token
 *             properties:
 *               refresh_token:
 *                 type: string
 *     responses:
 *       200:
 *         description: Refresh token thành công
 *       400:
 *         description: Thiếu Refresh Token
 *       401:
 *         description: Refresh Token không hợp lệ hoặc hết hạn
 */
router.post('/refresh-token', authController.refreshToken);

module.exports = router;