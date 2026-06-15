const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const {
    authenticateJwt
} = require('../../middlewares/auth.middleware');

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: Dang ky, dang nhap, token, session, password va profile hien tai
 */

/**
 * @swagger
 * /api/v1/auth/register:
 *   post:
 *     summary: Dang ky tai khoan user bang email/so dien thoai va mat khau
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [full_name, phone, password, confirm_password]
 *             properties:
 *               full_name:
 *                 type: string
 *                 example: Nguyen Van A
 *               username:
 *                 type: string
 *                 example: user01
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user01@example.com
 *               phone:
 *                 type: string
 *                 example: "0911111111"
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Password@123
 *               confirm_password:
 *                 type: string
 *                 format: password
 *                 example: Password@123
 *     responses:
 *       201:
 *         description: Dang ky thanh cong va tao vi mac dinh
 *       400:
 *         description: Du lieu dang ky khong hop le
 *       409:
 *         description: Email hoac so dien thoai da ton tai
 */
router.post('/register', authController.register);

/**
 * @swagger
 * /api/v1/auth/send-otp:
 *   post:
 *     summary: Gui ma OTP dang ky qua so dien thoai
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [phone]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user01@example.com
 *               phone:
 *                 type: string
 *                 example: "0911111111"
 *     responses:
 *       200:
 *         description: Da gui OTP
 *       400:
 *         description: Thieu so dien thoai hoac tai khoan da ton tai
 */
router.post('/send-otp', authController.sendOtp);

/**
 * @swagger
 * /api/v1/auth/verify-otp:
 *   post:
 *     summary: Xac thuc OTP va tra register_token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [phone, otp]
 *             properties:
 *               phone:
 *                 type: string
 *                 example: "0911111111"
 *               otp:
 *                 type: string
 *                 example: "123456"
 *     responses:
 *       200:
 *         description: Xac thuc OTP thanh cong, tra register_token
 *       400:
 *         description: OTP khong hop le hoac da het han
 *       403:
 *         description: Tai khoan tam khoa do sai OTP qua nhieu lan
 */
router.post('/verify-otp', authController.verifyOtp);

/**
 * @swagger
 * /api/v1/auth/set-password:
 *   post:
 *     summary: Thiet lap mat khau va tao vi cho user moi tu register_token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [register_token, password]
 *             properties:
 *               register_token:
 *                 type: string
 *                 description: Token nhan duoc sau khi verify OTP
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Password@123
 *     responses:
 *       201:
 *         description: Tao tai khoan va vi thanh cong
 *       401:
 *         description: Register token khong hop le hoac het han
 */
router.post('/set-password', authController.setPassword);

/**
 * @swagger
 * /api/v1/auth/login:
 *   post:
 *     summary: Dang nhap he thong bang username, email hoac so dien thoai
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [password]
 *             properties:
 *               login_id:
 *                 type: string
 *                 description: Username, email hoac so dien thoai. Field chuan theo tai lieu.
 *                 example: admin01
 *               identifier:
 *                 type: string
 *                 deprecated: true
 *                 description: Alias cu de tuong thich mobile hien tai.
 *                 example: "0987654321"
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Password@123
 *               remember_me:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Dang nhap thanh cong, tra access_token, refresh_token, roles va permissions
 *       400:
 *         description: Thieu thong tin dang nhap
 *       401:
 *         description: Sai tai khoan hoac mat khau
 *       403:
 *         description: Tai khoan bi khoa hoac khong hoat dong
 */
router.post('/login', authController.login);

/**
 * @swagger
 * /api/v1/auth/refresh-token:
 *   post:
 *     summary: Refresh access token va rotation refresh token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refresh_token]
 *             properties:
 *               refresh_token:
 *                 type: string
 *                 example: refresh-token-value
 *     responses:
 *       200:
 *         description: Refresh thanh cong, tra cap token moi
 *       401:
 *         description: Refresh token khong hop le, het han hoac da bi revoke
 */
router.post('/refresh-token', authController.refreshToken);

/**
 * @swagger
 * /api/v1/auth/refresh:
 *   post:
 *     summary: Alias cua /api/v1/auth/refresh-token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refresh_token]
 *             properties:
 *               refresh_token:
 *                 type: string
 *                 example: refresh-token-value
 *     responses:
 *       200:
 *         description: Refresh thanh cong
 */
router.post('/refresh', authController.refreshToken);

/**
 * @swagger
 * /api/v1/auth/me:
 *   get:
 *     summary: Lay thong tin user, roles, permissions va merchant context hien tai
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lay thong tin nguoi dung hien tai thanh cong
 *       401:
 *         description: Thieu token, token khong hop le hoac het han
 */
router.get('/me', authenticateJwt, authController.me);

/**
 * @swagger
 * /api/v1/auth/logout:
 *   post:
 *     summary: Dang xuat va revoke refresh token cua session hien tai
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refresh_token]
 *             properties:
 *               refresh_token:
 *                 type: string
 *                 example: refresh-token-value
 *     responses:
 *       200:
 *         description: Dang xuat thanh cong
 *       401:
 *         description: Token khong hop le
 */
router.post('/logout', authenticateJwt, authController.logout);

/**
 * @swagger
 * /api/v1/auth/revoke-token:
 *   post:
 *     summary: Revoke mot refresh token hoac tat ca session cua user hien tai
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               refresh_token:
 *                 type: string
 *                 description: Bat buoc neu revoke_all = false
 *                 example: refresh-token-value
 *               revoke_all:
 *                 type: boolean
 *                 description: true de dang xuat tat ca session
 *                 example: false
 *     responses:
 *       200:
 *         description: Revoke token thanh cong
 *       401:
 *         description: Token khong hop le
 */
router.post('/revoke-token', authenticateJwt, authController.revokeToken);

/**
 * @swagger
 * /api/v1/auth/forgot-password:
 *   post:
 *     summary: Tao yeu cau dat lai mat khau bang username, email hoac so dien thoai
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               login_id:
 *                 type: string
 *                 example: "0911111111"
 *               identifier:
 *                 type: string
 *                 deprecated: true
 *                 example: "0911111111"
 *     responses:
 *       200:
 *         description: Neu tai khoan ton tai, reset token se duoc tao de test demo
 */
router.post('/forgot-password', authController.forgotPassword);

/**
 * @swagger
 * /api/v1/auth/reset-password:
 *   post:
 *     summary: Dat lai mat khau bang reset_token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [reset_token, new_password, confirm_new_password]
 *             properties:
 *               reset_token:
 *                 type: string
 *               new_password:
 *                 type: string
 *                 format: password
 *                 example: NewPassword@123
 *               confirm_new_password:
 *                 type: string
 *                 format: password
 *                 example: NewPassword@123
 *     responses:
 *       200:
 *         description: Dat lai mat khau thanh cong va revoke cac refresh token cu
 *       400:
 *         description: Reset token khong hop le hoac mat khau khong dat chinh sach
 */
router.post('/reset-password', authController.resetPassword);

/**
 * @swagger
 * /api/v1/auth/change-password:
 *   post:
 *     summary: Doi mat khau user hien tai
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [current_password, new_password, confirm_new_password]
 *             properties:
 *               current_password:
 *                 type: string
 *                 format: password
 *                 example: Password@123
 *               new_password:
 *                 type: string
 *                 format: password
 *                 example: NewPassword@123
 *               confirm_new_password:
 *                 type: string
 *                 format: password
 *                 example: NewPassword@123
 *               revoke_other_sessions:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Doi mat khau thanh cong
 *       401:
 *         description: Mat khau hien tai khong dung hoac token khong hop le
 */
router.post('/change-password', authenticateJwt, authController.changePassword);

module.exports = router;
