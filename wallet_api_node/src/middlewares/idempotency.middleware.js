const crypto = require('crypto');
const idempotencyRepo = require('../repositories/idempotency.repository');

const withIdempotency = async (req, res, next) => {
    const idempotencyKey = req.headers['idempotency-key'];

    // Nếu không có key, cứ cho qua bình thường (hoặc bạn có thể báo lỗi ép buộc phải có)
    if (!idempotencyKey) {
        return next();
    }

    try {
        // 1. Kiểm tra xem Key này đã được xử lý thành công trước đó chưa
        const existingRecord = await idempotencyRepo.findByKey(idempotencyKey);
        
        if (existingRecord) {
            // Nếu có rồi, trả về data cũ ngay lập tức, CHẶN không cho chạy vào Controller
            return res.status(200).json(existingRecord.response_data);
        }

        // 2. Nếu chưa có, ta phải "đánh chặn" hàm res.json() của Express
        // Để khi Controller xử lý xong và gọi res.json(), ta sẽ lén copy data lại để lưu DB
        const originalJson = res.json;
        
        res.json = function (body) {
            // Chỉ lưu Idempotency Key khi request thành công (Status 2xx)
            if (res.statusCode >= 200 && res.statusCode < 300) {
                // Băm cái body request lại để đối chiếu (đề phòng app gửi trùng key nhưng sai data)
                const requestHash = crypto.createHash('sha256').update(JSON.stringify(req.body)).digest('hex');
                
                // Lưu vào DB chạy ngầm (không dùng await để tránh làm chậm response)
                idempotencyRepo.saveKey(idempotencyKey, requestHash, body)
                    .catch(err => console.error('Lỗi lưu Idempotency Key:', err));
            }
            
            // Trả về cho Client như bình thường
            return originalJson.call(this, body);
        };

        next(); // Cho phép đi tiếp vào Controller xử lý
    } catch (error) {
        console.error('Lỗi kiểm tra Idempotency:', error);
        next();
    }
};

module.exports = withIdempotency;