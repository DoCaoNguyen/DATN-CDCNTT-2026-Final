const crypto = require('crypto');
const idempotencyRepo = require('../modules/system/idempotency.repository');
const redis = require('../config/redis');

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

        // Lock bằng Redis (Chống Concurrency 100 requests cùng lúc)
        const lockKey = `idempotency_lock:${idempotencyKey}`;
        const acquired = await redis.setnx(lockKey, 'locked');
        if (!acquired) {
            return res.status(409).json({ message: 'Giao dịch đang được xử lý, vui lòng không lặp lại yêu cầu.' });
        }
        await redis.expire(lockKey, 30);

        const originalJson = res.json;
        res.json = function (body) {
            if (res.statusCode >= 200 && res.statusCode < 300) {
                const requestHash = crypto.createHash('sha256').update(JSON.stringify(req.body)).digest('hex');
                idempotencyRepo.saveKey(idempotencyKey, requestHash, body)
                    .catch(err => console.error('Lỗi lưu Idempotency Key:', err));
            }
            redis.del(lockKey).catch(() => {});
            return originalJson.call(this, body);
        };
        next();
    } catch (error) {
        console.error('Lỗi kiểm tra Idempotency:', error);
        next();
    }
};

module.exports = withIdempotency;