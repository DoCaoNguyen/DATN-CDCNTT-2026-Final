const kycService = require('./kyc.service');

const kycController = {
    // --- MỚI THÊM: Controller xử lý API check ID ---
    checkId: async (req, res) => {
        try {
            const idNumber = req.query.id;
            if (!idNumber) {
                return res.status(400).json({ error: 'Thiếu tham số Số CCCD (id)' });
            }

            const isUsed = await kycService.checkIfIdUsed(idNumber);
            res.status(200).json({ is_used: isUsed });
        } catch (error) {
            console.error("Lỗi Controller Check ID:", error);
            res.status(500).json({ error: 'Lỗi hệ thống khi kiểm tra CCCD' });
        }
    },

    verifyKYC: async (req, res) => {
        try {
            if (!req.files || !req.files['id_front'] || !req.files['id_back'] || !req.files['face_image']) {
                return res.status(400).json({ error: 'Vui lòng cung cấp đủ 3 ảnh' });
            }
            
            const userId = req.body.user_id; 
            const ocrDataString = req.body.ocr_data; // Dữ liệu chữ do Flutter tự đọc gửi lên
            
            if (!userId || !ocrDataString) {
                return res.status(400).json({ error: 'Thiếu thông tin user_id hoặc dữ liệu OCR.' });
            }

            const ocrData = JSON.parse(ocrDataString);
            const idFrontPath = req.files['id_front'][0].path;
            const idBackPath = req.files['id_back'][0].path;
            const faceImagePath = req.files['face_image'][0].path;

            const result = await kycService.processEKYC(userId, ocrData, idFrontPath, idBackPath, faceImagePath);

            res.status(200).json({ message: 'Xác thực eKYC thành công', data: result });

        } catch (error) {
            console.error("Lỗi Controller Verify KYC:", error);
            res.status(500).json({ error: error.message || 'Lỗi hệ thống' });
        }
    }
};

module.exports = kycController;