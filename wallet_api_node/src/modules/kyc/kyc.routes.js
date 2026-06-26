const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const kycController = require('../../modules/kyc/kyc.controller');

// Cấu hình Multer lưu file tạm vào thư mục uploads/ và giữ lại đuôi mở rộng
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

/**
 * @swagger
 * tags:
 *   name: KYC
 *   description: Các API liên quan đến Định danh người dùng (eKYC)
 */

/**
 * @swagger
 * /api/v1/kyc/check-id:
 *   get:
 *     summary: Kiểm tra xem Số CCCD đã được sử dụng hay chưa
 *     tags: [KYC]
 *     parameters:
 *       - in: query
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Số CCCD cần kiểm tra
 *         example: "012345678901"
 *     responses:
 *       200:
 *         description: Trạng thái sử dụng của số CCCD
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 is_used:
 *                   type: boolean
 *                   description: true nếu đã được sử dụng, ngược lại false
 *                   example: false
 *       400:
 *         description: Thiếu tham số id
 *       500:
 *         description: Lỗi hệ thống
 */
router.get('/check-id', kycController.checkId);

/**
 * @swagger
 * /api/v1/kyc/verify:
 *   post:
 *     summary: Thực hiện xác thực eKYC bằng cách upload ảnh CCCD và ảnh selfie
 *     tags: [KYC]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - user_id
 *               - ocr_data
 *               - id_front
 *               - id_back
 *               - face_image
 *             properties:
 *               user_id:
 *                 type: string
 *                 description: ID của người dùng thực hiện eKYC
 *                 example: "f0361838-ad7e-46ea-9bac-7e546622aa87"
 *               ocr_data:
 *                 type: string
 *                 description: Chuỗi JSON chứa thông tin OCR mà ứng dụng đọc được
 *                 example: '{"id":"012345678901","name":"NGUYỄN VĂN A","dob":"01/01/1995"}'
 *               id_front:
 *                 type: string
 *                 format: binary
 *                 description: Ảnh mặt trước CCCD
 *               id_back:
 *                 type: string
 *                 format: binary
 *                 description: Ảnh mặt sau CCCD
 *               face_image:
 *                 type: string
 *                 format: binary
 *                 description: Ảnh chụp khuôn mặt (selfie) của người dùng
 *     responses:
 *       200:
 *         description: Xác thực eKYC thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Xác thực eKYC thành công"
 *                 data:
 *                   type: object
 *       400:
 *         description: Thiếu dữ liệu hoặc file upload không hợp lệ
 *       500:
 *         description: Lỗi hệ thống khi đối sánh khuôn mặt hoặc OCR
 */
router.post('/verify', upload.fields([
    { name: 'id_front', maxCount: 1 },
    { name: 'id_back', maxCount: 1 },
    { name: 'face_image', maxCount: 1 }
]), kycController.verifyKYC);

router.post('/ocr-front', upload.single('id_front'), kycController.ocrFront);

module.exports = router;