const paymentService = require('./payment.service');

const paymentController = {
    createOrder: async (req, res) => {
        const merchantId = req.merchant.merchant_id;
        const { amount, callback_url, description } = req.body;

        if (!amount || amount <= 0) {
            return res.status(400).json({ error: 'Số tiền đơn hàng không hợp lệ' });
        }

        try {
            const result = await paymentService.createDynamicQR(merchantId, amount, callback_url, description);
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
        const { qr_token } = req.body;

        if (!qr_token) return res.status(400).json({ error: 'Thiếu mã QR Token' });

        try {
            const result = await paymentService.processQrPayment(userId, qr_token);
            res.status(200).json({
                message: 'Thanh toán thành công',
                data: result
            });
        } catch (error) {
            const errorMap = {
                'Order_Not_Found': 'Mã QR không tồn tại hoặc không hợp lệ',
                'QR_Expired': 'Mã QR đã hết hạn, vui lòng tạo lại',
                'Order_Already_Processed': 'Đơn hàng này đã được thanh toán hoặc đã hủy',
                'Wallet_Not_Found': 'Không tìm thấy ví của bạn',
                'Wallet_Not_Active': 'Ví đang bị khóa hoặc không còn hoạt động',
                'Insufficient_Balance': 'Số dư trong ví không đủ để thanh toán'
            };

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

        if (!amount || Number(amount) <= 0) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const userRepo = require('../user/user.repository');
            const user = await userRepo.getUserProfile(req.user.userId);
            if (!user) {
                return res.status(404).json({ error: 'Không tìm thấy người dùng' });
            }

            const result = await paymentService.createUserQR(Number(amount), description, user.phone, user.full_name);
            res.status(201).json({
                message: 'Tạo QR nhận tiền thành công',
                data: result
            });
        } catch (error) {
            console.error('Lỗi tạo QR nhận tiền:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tạo QR' });
        }
    }
};

module.exports = paymentController;
