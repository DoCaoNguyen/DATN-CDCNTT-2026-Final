const merchantRepository = require('./merchant.repository');
const merchantService = require('./merchant.service');
const crypto = require('crypto');
const { v7: uuidv7 } = require('uuid');
const pool = require('../../config/db');
const bcrypt = require('bcrypt');
const merchantRepository = require('./merchant.repository');

// In-memory store for Auth Codes (Demo purpose only)
// Trong thực tế sẽ dùng Redis có expire (TTL)
const authCodeMap = new Map();

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
    },

    // [Thêm mới] API cấp Auth_Code dùng 1 lần cho Deep Link
    generateAuthCode: async (req, res) => {
        try {
            const userId = req.user.userId;
            const result = await pool.query('SELECT phone FROM users WHERE id = $1', [userId]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'User not found' });
            }
            
            let phone = result.rows[0].phone;
            // Không che số điện thoại để Merchant (TikTok Shop) có thể lưu lại và dùng làm wallet_account khi gọi API Charge
            
            const authCode = crypto.randomUUID();
            
            // Lưu vào Map, hết hạn sau 5 phút
            authCodeMap.set(authCode, { 
                phone, 
                userId, 
                expiresAt: Date.now() + 5 * 60 * 1000 
            });
            
            res.status(200).json({ success: true, auth_code: authCode });
        } catch (error) {
            console.error('Lỗi sinh Auth_Code:', error);
            res.status(500).json({ error: 'Lỗi hệ thống' });
        }
    },

    // [Thêm mới] API xác thực Auth_Code từ phía Merchant/TikTok Shop gọi sang
    verifyAuthCode: async (req, res) => {
        try {
            const { auth_code, merchant_name } = req.body;
            
            if (!auth_code || !authCodeMap.has(auth_code)) {
                return res.status(400).json({ success: false, error: 'Mã xác thực không hợp lệ hoặc đã hết hạn' });
            }
            
            const data = authCodeMap.get(auth_code);
            
            if (Date.now() > data.expiresAt) {
                authCodeMap.delete(auth_code);
                return res.status(400).json({ success: false, error: 'Mã xác thực đã hết hạn' });
            }
            
            // LƯU LIÊN KẾT VÀO DATABASE
            
            if (merchant_name && data.userId) {
                const check = await pool.query('SELECT id FROM user_linked_services WHERE user_id = $1 AND service_name = $2', [data.userId, merchant_name]);
                if (check.rows.length === 0) {
                    let icon = 'https://cdn-icons-png.flaticon.com/512/2875/2875364.png';
                    if (merchant_name.toLowerCase().includes('tiktok')) {
                        icon = 'https://cdn-icons-png.flaticon.com/512/3046/3046121.png'; // TikTok icon
                    } else if (merchant_name.toLowerCase().includes('google')) {
                        icon = 'https://cdn-icons-png.flaticon.com/512/300/300218.png'; // Google icon
                    }
                    
                    const newId = uuidv7();
                    
                    await pool.query(
                        'INSERT INTO user_linked_services (id, user_id, service_name, service_icon) VALUES ($1, $2, $3, $4)',
                        [newId, data.userId, merchant_name, icon]
                    );
                }
            }

            // THU HỒI NGAY LẬP TỨC ĐỂ CHỐNG REPLAY ATTACK (Mỗi mã chỉ được đổi 1 lần)
            authCodeMap.delete(auth_code);
            
            // GENERATE BILLING TOKEN
            const jwt = require('jsonwebtoken');
            const tokenStr = jwt.sign(
                { userId: data.userId, phone: data.phone }, 
                process.env.JWT_SECRET || 'mio_secret_key',
                { expiresIn: '3650d' } // Token siêu dài hạn (10 năm)
            );
            const billing_token = 'tok_mio_' + tokenStr;
            const masked_phone = '******' + data.phone.slice(-4);

            res.status(200).json({ 
                success: true, 
                wallet_token: billing_token,
                masked_phone: masked_phone,
                message: 'Xác thực thành công'
            });
        } catch (error) {
            console.error('Lỗi xác thực Auth_Code:', error);
            res.status(500).json({ error: 'Lỗi hệ thống' });
        }
    },

    // ===== NEW: API Ra lệnh trừ tiền tự động (Auto-Debit) =====
    charge: async (req, res) => {
        try {
            const { api_key, merchant_code, wallet_token, amount, order_id } = req.body;
            
            if (!api_key || !wallet_token || !amount) {
                return res.status(400).json({ error: 'Thiếu thông tin bắt buộc (api_key, wallet_token, amount)' });
            }

            // Bỏ hardcode AUTO_DEBIT_LIMIT ở đây, sẽ check phía dưới sau khi có thông tin ví.

            // Giải mã Token Ủy Quyền
            let wallet_account = '';
            if (wallet_token && wallet_token.startsWith('tok_mio_')) {
                try {
                    const jwt = require('jsonwebtoken');
                    const decoded = jwt.verify(
                        wallet_token.replace('tok_mio_', ''), 
                        process.env.JWT_SECRET || 'mio_secret_key'
                    );
                    wallet_account = decoded.phone;
                } catch (err) {
                    return res.status(401).json({ error: 'Token uỷ quyền không hợp lệ hoặc đã hết hạn' });
                }
            } else {
                return res.status(400).json({ error: 'Yêu cầu Token uỷ quyền hợp lệ' });
            }

            // 0. KHÔNG CẦN XÁC THỰC BẢO MẬT (Luồng Auto-Debit hoàn toàn)
            // Lấy token ủy quyền (wallet_account) là đủ để xác định user.
            // Bỏ qua check PIN hoặc Biometric để giao dịch mượt mà như Grab/Ví Mio.

            // 1. Xác thực Merchant bằng api_key
            const merchant = await merchantRepository.getMerchantByApiKey(api_key);
            if (!merchant) {
                return res.status(401).json({ error: 'Xác thực Merchant thất bại' });
            }

            // 1.5 KIỂM TRA HẠN MỨC GIAO DỊCH (Database-Driven)
            const walletRepo = require('../wallet/wallet.repository');
            const walletInfo = await merchantRepository.getWalletIdByPhone(wallet_account);
            if (!walletInfo) {
                return res.status(404).json({ error: 'Không tìm thấy ví liên kết với số điện thoại này' });
            }
            const { wallet_id, user_id } = walletInfo;

            // a. Kiểm tra hạn mức chung của Ví trong ngày
            const { limits, usage } = await walletRepo.getLimitsAndUsage(wallet_id);
            const globalLimit = BigInt(Math.floor(Number(limits.daily_transaction_limit || 50000000)));
            const globalUsage = BigInt(Math.floor(Number(usage.daily_transaction_usage || 0)));
            const requestAmount = BigInt(Math.floor(Number(amount)));
            
            if (globalUsage + requestAmount > globalLimit) {
                return res.status(400).json({ error: `Giao dịch thất bại: Vượt quá hạn mức giao dịch tối đa trong ngày của Ví Mio (${Number(globalLimit).toLocaleString('vi-VN')}đ).` });
            }

            // b. Kiểm tra hạn mức riêng của App Liên Kết (Auto-Debit Limit)
            // Tìm tên dịch vụ gốc (VD: 'TikTok Shop VN' -> lấy 'TikTok')
            const searchName = merchant.merchant_name.split(' ')[0]; 
            const linkedApp = await merchantRepository.getLinkedService(user_id, searchName);
            
            if (linkedApp && linkedApp.limit_per_day) {
                const appLimit = BigInt(Math.floor(Number(linkedApp.limit_per_day)));
                const appDailyUsage = await merchantRepository.getDailyUsageForMerchant(wallet_id, merchant.id);
                
                if (appDailyUsage + requestAmount > appLimit) {
                    return res.status(400).json({ error: `Giao dịch thất bại: Vượt quá hạn mức thanh toán tự động (${Number(appLimit).toLocaleString('vi-VN')}đ/ngày) của ứng dụng liên kết. Bạn đã tiêu ${Number(appDailyUsage).toLocaleString('vi-VN')}đ hôm nay.` });
                }
            }

            // 2. Xử lý thanh toán Auto Debit
            const paymentService = require('../payment/payment.service');
            const result = await paymentService.processAutoDebit(
                merchant.merchant_user_id,
                merchant.id,
                wallet_account, 
                amount, 
                order_id || 'AUTO_' + Date.now()
            );

            res.status(200).json({ 
                success: true, 
                message: 'Thanh toán thành công',
                data: result
            });

        } catch (error) {
            console.error('Lỗi Auto-Debit Charge:', error);
            if (error.message === 'Wallet_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy ví liên kết với số điện thoại này' });
            }
            if (error.message === 'Insufficient_Balance') {
                return res.status(400).json({ error: 'Số dư không đủ để thanh toán' });
            }
            res.status(500).json({ error: 'Lỗi hệ thống khi thanh toán tự động' });
        }
    }
};

module.exports = merchantController;
