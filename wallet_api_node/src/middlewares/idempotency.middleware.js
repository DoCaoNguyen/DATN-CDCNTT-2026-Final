const crypto = require('crypto');
const idempotencyRepo = require('../modules/system/idempotency.repository');

const withIdempotency = async (req, res, next) => {
    const idempotencyKey = req.headers['idempotency-key'];
    if (!idempotencyKey) {
        return next();
    }
    try {
        const existingRecord = await idempotencyRepo.findByKey(idempotencyKey);
        if (existingRecord) {
            return res.status(200).json(existingRecord.response_data);
        }
        const originalJson = res.json;
        res.json = function (body) {
            if (res.statusCode >= 200 && res.statusCode < 300) {
                const requestHash = crypto.createHash('sha256').update(JSON.stringify(req.body)).digest('hex');
                idempotencyRepo.saveKey(idempotencyKey, requestHash, body)
                    .catch(err => console.error('Lỗi lưu Idempotency Key:', err));
            }
            return originalJson.call(this, body);
        };
        next();
    } catch (error) {
        console.error('Lỗi kiểm tra Idempotency:', error);
        next();
    }
};

module.exports = withIdempotency;