const pool = require('../config/db');

const verifyApiKey = async (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    
    if (!apiKey) {
        return res.status(401).json({ error: 'Thiếu API Key' });
    }

    try {
        const query = `
            SELECT m.id AS merchant_id, m.status 
            FROM merchant_api_keys mak
            JOIN merchants m ON mak.merchant_id = m.id
            WHERE mak.api_key = $1 AND (mak.expired_at IS NULL OR mak.expired_at > CURRENT_TIMESTAMP)
        `;
        const result = await pool.query(query, [apiKey]);

        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'API Key không hợp lệ hoặc đã hết hạn' });
        }

        if (result.rows[0].status !== 'ACTIVE') {
            return res.status(403).json({ error: 'Tài khoản Merchant đã bị khóa' });
        }

        req.merchant = result.rows[0];
        next();
    } catch (error) {
        console.error('Lỗi xác thực API Key:', error);
        res.status(500).json({ error: 'Lỗi hệ thống xác thực' });
    }
};

const { verifyToken, requireMerchant } = require('./auth.middleware');

const resolveMerchantContext = async (req, res, next) => {
    try {
        const userId = req.user.id;
        
        const result = await pool.query(`
            SELECT merchant_id, role_code, is_owner, is_active
            FROM merchant_users
            WHERE user_id = $1 AND is_active = true
            LIMIT 1
        `, [userId]);

        if (result.rows.length === 0) {
            return res.status(403).json({
                success: false,
                error_code: 'FORBIDDEN',
                message: 'Tài khoản không thuộc về bất kỳ Merchant nào hoặc đã bị vô hiệu hóa'
            });
        }

        const context = result.rows[0];
        req.merchantContext = {
            merchant_id: context.merchant_id,
            role_code: context.role_code,
            is_owner: context.is_owner
        };

        next();
    } catch (error) {
        console.error('Error resolving merchant context:', error);
        return res.status(500).json({
            success: false,
            message: 'Lỗi server khi kiểm tra quyền merchant',
            error_code: 'Internal_Server_Error'
        });
    }
};

const requireMerchantUser = [verifyToken, requireMerchant, resolveMerchantContext];

module.exports = {
    verifyApiKey,
    resolveMerchantContext,
    requireMerchantUser
};