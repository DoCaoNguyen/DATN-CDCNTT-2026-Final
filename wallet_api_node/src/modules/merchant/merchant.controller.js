const merchantRepository = require('./merchant.repository');
const merchantService = require('./merchant.service');

const merchantController = {
    getProfile: async (req, res) => {
        try {
            const { merchant_id, role_code, is_owner } = req.merchantContext;
            const profile = await merchantRepository.getMerchantProfile(merchant_id);
            if (!profile) return res.status(404).json({ success: false, message: 'Merchant not found' });
            
            res.json({ success: true, data: { ...profile, role_code, is_owner } });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    updateCallback: async (req, res) => {
        try {
            const { merchant_id, role_code, is_owner } = req.merchantContext;
            const permissions = req.user.permissions || [];
            
            if (!is_owner && role_code !== 'MERCHANT_OWNER' && !permissions.includes('merchant.profile.update')) {
                return res.status(403).json({ success: false, message: 'Bạn không có quyền cập nhật cấu hình Callback' });
            }

            const { default_callback_url, default_redirect_url } = req.body;
            if (default_callback_url && !/^https?:\/\//.test(default_callback_url)) {
                return res.status(400).json({ success: false, message: 'URL không hợp lệ' });
            }

            const updated = await merchantRepository.updateCallbackConfig(merchant_id, { default_callback_url, default_redirect_url });
            res.json({ success: true, message: 'Cập nhật thành công', data: updated });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getApiKeys: async (req, res) => {
        try {
            const keys = await merchantRepository.getApiKeys(req.merchantContext.merchant_id);
            res.json({ success: true, data: keys });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    createApiKey: async (req, res) => {
        try {
            const { merchant_id, role_code, is_owner } = req.merchantContext;
            const permissions = req.user.permissions || [];
            
            if (!is_owner && role_code !== 'MERCHANT_OWNER' && !permissions.includes('merchant.api_keys.create')) {
                return res.status(403).json({ success: false, message: 'Bạn không có quyền tạo API Key' });
            }

            const { key_name } = req.body;
            if (!key_name) {
                return res.status(400).json({ success: false, message: 'Thiếu key_name' });
            }

            const ipAddress = req.ip || req.connection.remoteAddress;
            const userAgent = req.headers['user-agent'];

            const result = await merchantService.createApiKey(merchant_id, key_name, req.user.userId || req.user.id, ipAddress, userAgent);
            res.status(201).json({ success: true, message: 'Tạo API Key thành công', data: result });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    rotateApiKey: async (req, res) => {
        try {
            const { merchant_id, role_code, is_owner } = req.merchantContext;
            const permissions = req.user.permissions || [];
            
            if (!is_owner && role_code !== 'MERCHANT_OWNER' && !permissions.includes('merchant.api_keys.rotate')) {
                return res.status(403).json({ success: false, message: 'Bạn không có quyền đổi Secret API Key' });
            }

            const { keyId } = req.params;
            const ipAddress = req.ip || req.connection.remoteAddress;
            const userAgent = req.headers['user-agent'];

            const result = await merchantService.rotateApiKey(merchant_id, keyId, req.user.userId || req.user.id, ipAddress, userAgent);
            res.json({ success: true, message: 'Đổi Secret thành công', data: result });
        } catch (err) {
            if (err.message === 'Api_Key_Not_Found') return res.status(404).json({ success: false, message: 'Không tìm thấy API Key' });
            if (err.message === 'Api_Key_Already_Revoked') return res.status(400).json({ success: false, message: 'API Key đã bị thu hồi' });
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    revokeApiKey: async (req, res) => {
        try {
            const { merchant_id, role_code, is_owner } = req.merchantContext;
            const permissions = req.user.permissions || [];
            
            if (!is_owner && role_code !== 'MERCHANT_OWNER' && !permissions.includes('merchant.api_keys.revoke')) {
                return res.status(403).json({ success: false, message: 'Bạn không có quyền thu hồi API Key' });
            }

            const { keyId } = req.params;
            const { reason } = req.body;
            const ipAddress = req.ip || req.connection.remoteAddress;
            const userAgent = req.headers['user-agent'];

            await merchantService.revokeApiKey(merchant_id, keyId, reason, req.user.userId || req.user.id, ipAddress, userAgent);
            res.json({ success: true, message: 'Thu hồi API Key thành công' });
        } catch (err) {
            if (err.message === 'Api_Key_Not_Found') return res.status(404).json({ success: false, message: 'Không tìm thấy API Key' });
            if (err.message === 'Api_Key_Already_Revoked') return res.status(400).json({ success: false, message: 'API Key đã bị thu hồi' });
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getPaymentOrders: async (req, res) => {
        try {
            const data = await merchantRepository.getPaymentOrders(req.merchantContext.merchant_id, req.query);
            res.json({ success: true, data });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getPaymentOrderById: async (req, res) => {
        try {
            const order = await merchantRepository.getPaymentOrderById(req.merchantContext.merchant_id, req.params.id);
            if (!order) return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng' });
            res.json({ success: true, data: order });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getTransactions: async (req, res) => {
        try {
            const data = await merchantRepository.getTransactions(req.merchantContext.merchant_id, req.query);
            res.json({ success: true, data });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getTransactionById: async (req, res) => {
        try {
            const tx = await merchantRepository.getTransactionById(req.merchantContext.merchant_id, req.params.id);
            if (!tx) return res.status(404).json({ success: false, message: 'Không tìm thấy giao dịch' });
            res.json({ success: true, data: tx });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getWebhooks: async (req, res) => {
        try {
            const data = await merchantRepository.getWebhooks(req.merchantContext.merchant_id, req.query);
            res.json({ success: true, data });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getWebhookById: async (req, res) => {
        try {
            const wh = await merchantRepository.getWebhookById(req.merchantContext.merchant_id, req.params.id);
            if (!wh) return res.status(404).json({ success: false, message: 'Không tìm thấy webhook' });
            res.json({ success: true, data: wh });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    retryWebhook: async (req, res) => {
        try {
            const wh = await merchantRepository.retryWebhook(req.merchantContext.merchant_id, req.params.id);
            res.json({ success: true, message: 'Đã đưa webhook vào hàng đợi retry', data: wh });
        } catch (err) {
            console.error(err);
            if (err.message === 'Webhook event not found') {
                return res.status(404).json({ success: false, message: 'Webhook không tồn tại hoặc không thuộc Merchant này' });
            }
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getBalance: async (req, res) => {
        try {
            const balance = await merchantRepository.getMerchantBalance(req.merchantContext.merchant_id);
            if (!balance) return res.status(404).json({ success: false, message: 'Không tìm thấy thông tin số dư' });
            res.json({ success: true, data: balance });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    getStatement: async (req, res) => {
        try {
            const data = await merchantRepository.getMerchantStatement(req.merchantContext.merchant_id, req.query);
            res.json({ success: true, data });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    }
};

module.exports = merchantController;
