const express = require('express');
const router = express.Router();
const multer = require('multer');
const kycController = require('../controllers/kyc.controller');

// Cấu hình Multer lưu file tạm vào thư mục uploads/
const upload = multer({ dest: 'uploads/' });

// --- MỚI THÊM: API kiểm tra CCCD trùng lặp ---
router.get('/check-id', kycController.checkId);

// API nhận 3 ảnh: mặt trước, mặt sau, khuôn mặt
router.post('/verify', upload.fields([
    { name: 'id_front', maxCount: 1 },
    { name: 'id_back', maxCount: 1 },
    { name: 'face_image', maxCount: 1 }
]), kycController.verifyKYC);

module.exports = router;