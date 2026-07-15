const paymentService = require('./payment.service');
const paymentRepo = require('./payment.repository');

const paymentController = {
    createOrder: async (req, res) => {
        const merchantId = req.merchant.merchant_id;
        const { amount, description, merchant_order_id } = req.body;

        if (!amount) {
            return res.status(400).json({ error: 'Số tiền đơn hàng không hợp lệ' });
        }

        let bigAmount;
        try {
            let cleanAmount = amount;
            if (typeof amount === 'string') {
                cleanAmount = amount.replace(/[.,\s]/g, '');
            }
            bigAmount = BigInt(cleanAmount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền đơn hàng không hợp lệ' });
        }

        try {
            const environment = req.merchant.environment || 'SANDBOX';
            const result = await paymentService.createDynamicQR(merchantId, bigAmount, description, merchant_order_id || null, environment);
            res.status(201).json({
                message: 'Tạo đơn hàng thanh toán thành công',
                data: result
            });
        } catch (error) {
            console.error('Lỗi tạo payment order:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi sinh QR Code' });
        }
    },

    processPayment: async (req, res) => {
        const userId = req.user.userId;
        const { qr_token, pin } = req.body;
        const faceImagePath = req.file ? req.file.path : null;
        const idempotencyKey = req.headers['idempotency-key'];

        if (!idempotencyKey) {
            return res.status(400).json({ error: 'MISSING_IDEMPOTENCY_KEY' });
        }

        if (!qr_token) return res.status(400).json({ error: 'Thiếu mã QR Token' });

        if (!pin) return res.status(400).json({ error: 'Vui lòng nhập mã PIN để xác nhận thanh toán' });

        try {
            const result = await paymentService.processQrPayment(userId, qr_token, pin, faceImagePath, idempotencyKey);
            res.status(200).json({
                message: 'Thanh toán thành công',
                data: result
            });
        } catch (error) {
            const errorMap = {
                'Order_Not_Found': 'Mã QR không tồn tại hoặc không hợp lệ',
                'QR_Expired': 'Mã QR đã hết hạn, vui lòng tạo lại',
                'Order_Already_Processed': 'Đơn hàng này đã được thanh toán hoặc đã hủy',
                'Order_Canceled': 'Đơn thanh toán đã bị hủy hoặc không còn hiệu lực.',
                'Wallet_Not_Found': 'Không tìm thấy ví của bạn',
                'Insufficient_Balance': 'Số dư trong ví không đủ để thanh toán',
                'PIN_Required': 'Vui lòng nhập mã PIN để xác nhận',
                'Wallet_Locked_PIN': 'Ví đã bị khóa do nhập sai PIN quá nhiều lần. Vui lòng thử lại sau 30 phút',
                'Face_Verification_Required': 'Giao dịch trên 30 triệu yêu cầu xác thực khuôn mặt',
                'Face_Verification_Failed': 'Xác thực khuôn mặt thất bại'
            };

            // Xử lý lỗi sai PIN (Wrong_PIN_1, Wrong_PIN_2)
            if (error.message && error.message.startsWith('Wrong_PIN_')) {
                const remaining = error.message.split('_')[2];
                return res.status(400).json({ error: `Mã PIN không đúng. Bạn còn ${remaining} lần thử` });
            }

            if (errorMap[error.message]) {
                return res.status(400).json({ error: errorMap[error.message] });
            }

            console.error('Lỗi xử lý thanh toán QR:', error);
            res.status(500).json({ error: 'Giao dịch thất bại do lỗi hệ thống' });
        }
    },

    // Endpoint cho user tạo QR "nhận tiền" kèm số tiền tùy chỉnh
    requestMoney: async (req, res) => {
        const { amount, description } = req.body;

        if (!amount) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        let bigAmount;
        try {
            let cleanAmount = amount;
            if (typeof amount === 'string') {
                cleanAmount = amount.replace(/[.,\s]/g, '');
            }
            bigAmount = BigInt(cleanAmount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        if (bigAmount > 50000000n) {
            return res.status(400).json({ error: 'Số tiền tạo mã không được vượt quá 50.000.000đ' });
        }

        try {
            const userRepo = require('../user/user.repository');
            const user = await userRepo.getUserProfile(req.user.userId);
            if (!user) {
                return res.status(404).json({ error: 'Không tìm thấy người dùng' });
            }

            const result = await paymentService.createUserQR(bigAmount, description, user.phone, user.full_name);
            res.status(201).json({
                message: 'Tạo QR nhận tiền thành công',
                data: result
            });
        } catch (error) {
            console.error('Lỗi tạo QR nhận tiền:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tạo QR' });
        }
    },

    // ===== NEW: Preview đơn hàng từ QR token (Mobile app xem trước khi xác nhận) =====
    previewPayment: async (req, res) => {
        const { qr_token } = req.query;

        if (!qr_token) {
            return res.status(400).json({ error: 'Thiếu mã QR Token' });
        }

        try {
            const order = await paymentRepo.getOrderByQrToken(qr_token);

            if (!order) {
                return res.status(404).json({ error: 'Không tìm thấy đơn hàng từ mã QR này' });
            }

            let isExpired = new Date() > new Date(order.expired_at);
            
            if (isExpired && order.status === 'PENDING') {
                await paymentRepo.lazyUpdateOrderToExpired(order.order_id);
                order.status = 'EXPIRED';
            }

            if (order.status === 'CANCELED' || order.status === 'EXPIRED') {
                return res.status(400).json({ error: 'Đơn thanh toán đã bị hủy hoặc không còn hiệu lực.' });
            }

            if (order.status === 'PAID' || order.status === 'SUCCESS') {
                return res.status(400).json({ error: 'Đơn hàng này đã được thanh toán.' });
            }

            res.status(200).json({
                message: 'Lấy thông tin đơn hàng thành công',
                data: {
                    order_code: order.order_code,
                    merchant_order_id: order.merchant_order_id || null,
                    amount: order.amount ? order.amount.toString() : '0',
                    description: order.description || null,
                    currency: order.currency || 'VND',
                    status: order.status,
                    merchant_name: order.merchant_name || null,
                    expired_at: order.expired_at,
                    is_expired: isExpired,
                    can_pay: order.status === 'PENDING' && !isExpired
                }
            });
        } catch (error) {
            console.error('Lỗi preview payment:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi lấy thông tin đơn hàng' });
        }
    },

    getOrderStatus: async (req, res) => {
        const merchantId = req.merchant.merchant_id;
        const { order_code, merchant_order_id } = req.query;

        if (!order_code && !merchant_order_id) {
            return res.status(400).json({ error: 'Vui lòng cung cấp order_code hoặc merchant_order_id' });
        }

        try {
            let order;
            if (order_code) {
                order = await paymentRepo.getOrderByCode(merchantId, order_code);
            } else {
                order = await paymentRepo.getOrderByMerchantOrderId(merchantId, merchant_order_id);
            }

            if (!order) {
                return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
            }

            let isExpired = new Date() > new Date(order.expired_at);
            if (isExpired && order.status === 'PENDING') {
                await paymentRepo.lazyUpdateOrderToExpired(order.order_id);
                order.status = 'EXPIRED';
            }

            res.status(200).json({
                message: 'Tra cứu trạng thái thành công',
                data: {
                    order_id: order.order_id,
                    order_code: order.order_code,
                    merchant_order_id: order.merchant_order_id || null,
                    amount: order.amount ? order.amount.toString() : '0',
                    description: order.description || null,
                    currency: order.currency || 'VND',
                    order_status: order.status,
                    expired_at: order.expired_at,
                    created_at: order.created_at,
                    payment: order.payment_transaction_id ? {
                        transaction_id: order.payment_transaction_id,
                        payment_status: order.payment_status,
                        paid_at: order.paid_at
                    } : null
                }
            });
        } catch (error) {
            console.error('Lỗi tra cứu trạng thái đơn hàng:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tra cứu' });
        }
    },

    getPaymentTransaction: async (req, res) => {
        const merchantId = req.merchant.merchant_id;
        const { id } = req.params;

        if (!id) {
            return res.status(400).json({ error: 'Thiếu ID giao dịch' });
        }

        try {
            const transaction = await paymentRepo.getPaymentTransactionById(merchantId, id);

            if (!transaction) {
                return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
            }

            res.status(200).json({
                message: 'Lấy thông tin giao dịch thành công',
                data: {
                    transaction_id: transaction.id,
                    order_code: transaction.order_code,
                    merchant_order_id: transaction.merchant_order_id || null,
                    amount: transaction.amount ? transaction.amount.toString() : '0',
                    description: transaction.description || null,
                    payment_status: transaction.status,
                    order_status: transaction.order_status,
                    paid_at: transaction.paid_at,
                    created_at: transaction.created_at
                }
            });
        } catch (error) {
            console.error('Lỗi tra cứu giao dịch thanh toán:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tra cứu giao dịch' });
        }
    },


    // ===== NEW: Merchant Hủy đơn thanh toán =====
    cancelOrder: async (req, res) => {
        const merchantId = req.merchant.merchant_id;
        const { merchant_order_id } = req.body;

        if (!merchant_order_id) {
            return res.status(400).json({ error: 'Vui lòng cung cấp merchant_order_id' });
        }

        try {
            const order = await paymentRepo.getOrderByMerchantOrderId(merchantId, merchant_order_id);

            if (!order) {
                return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
            }

            if (order.status === 'PAID' || order.status === 'SUCCESS') {
                return res.status(400).json({ error: 'Đơn hàng đã được thanh toán, không thể hủy.' });
            }

            if (order.status === 'CANCELED') {
                return res.status(200).json({ message: 'Đơn hàng đã được hủy trước đó', data: { status: 'CANCELED' } });
            }

            if (order.status === 'EXPIRED') {
                return res.status(400).json({ error: 'Mã QR đã hết hạn' });
            }
            
            if (new Date() > new Date(order.expired_at)) {
                if (order.status === 'PENDING') {
                    await paymentRepo.lazyUpdateOrderToExpired(order.order_id);
                }
                return res.status(400).json({ error: 'Mã QR đã hết hạn' });
            }

            await paymentRepo.cancelPaymentOrder(order.order_id);

            res.status(200).json({
                message: 'Hủy đơn thanh toán thành công',
                data: {
                    merchant_order_id,
                    status: 'CANCELED'
                }
            });
        } catch (error) {
            console.error('Lỗi hủy đơn hàng:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi hủy đơn hàng' });
        }
    },
};

module.exports = paymentController;