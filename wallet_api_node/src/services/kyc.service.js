const fs = require('fs');
const axios = require('axios');
const FormData = require('form-data');
const kycRepository = require('../repositories/kyc.repository');

const kycService = {
    // --- MỚI THÊM: Xử lý logic check ID ---
    checkIfIdUsed: async (idNumber) => {
        return await kycRepository.checkIdExists(idNumber);
    },

    processEKYC: async (userId, ocrData, idFrontPath, idBackPath, faceImagePath) => {
        
        console.log(`[1/3] Đã nhận dữ liệu OCR từ App Flutter:`, ocrData.id_number);

        console.log(`[2/3] Đang gọi Face++ API để so khớp khuôn mặt...`);
        const matchResult = await kycService.verifyFaceMatchFacePlusPlus(idFrontPath, faceImagePath);
        
        if (!matchResult.faceFound) {
            throw new Error('Không tìm thấy khuôn mặt rõ ràng trong ảnh thẻ hoặc ảnh selfie. Vui lòng chụp lại.');
        }

        let status = 'PENDING';
        if (matchResult.isMatch) {
            status = 'VERIFIED';
            console.log(`=> KHUÔN MẶT KHỚP! Độ chính xác: ${matchResult.score}%`);
        } else {
            status = 'REJECTED'; 
            console.log(`=> KHUÔN MẶT KHÔNG KHỚP! Chỉ đạt: ${matchResult.score}%`);
            throw new Error('Khuôn mặt không khớp với ảnh trên thẻ CCCD.');
        }

        console.log(`[3/3] Đang lưu hồ sơ vào Database...`);
        // Gọi xuống DB, truyền thêm đường dẫn ảnh
        const savedKyc = await kycRepository.saveKYCResult(
            userId, 
            ocrData, 
            idFrontPath, 
            idBackPath, 
            faceImagePath, 
            status, 
            matchResult.score
        );

        return {
            ocrInfo: ocrData,
            faceMatchScore: matchResult.score,
            status: status,
            record: savedKyc
        };
    },

    verifyFaceMatchFacePlusPlus: async (idFrontPath, selfiePath) => {
        try {
            const form = new FormData();
            form.append('api_key', process.env.FACEPP_API_KEY);
            form.append('api_secret', process.env.FACEPP_API_SECRET);
            form.append('image_file1', fs.createReadStream(idFrontPath));
            form.append('image_file2', fs.createReadStream(selfiePath));

            const response = await axios.post('https://api-us.faceplusplus.com/facepp/v3/compare', form, {
                headers: form.getHeaders()
            });

            const data = response.data;
            if (!data.faces1 || data.faces1.length === 0 || !data.faces2 || data.faces2.length === 0) {
                return { faceFound: false, isMatch: false, score: 0 };
            }

            const confidence = data.confidence; 
            const threshold = data.thresholds['1e-5']; 

            return {
                faceFound: true,
                isMatch: confidence >= threshold,
                score: parseFloat(confidence.toFixed(2))
            };
        } catch (error) {
            console.error("Lỗi Face++:", error.response ? error.response.data : error.message);
            return { faceFound: false, isMatch: false, score: 0 };
        }
    }
};

module.exports = kycService;