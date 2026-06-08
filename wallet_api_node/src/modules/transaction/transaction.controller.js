const txService = require('./transaction.service');

const transactionController = {
    deposit: async (req, res) => {
        const userId = req.user.userId;
        const { amount } = req.body;

        let bigAmount;
        try {
            bigAmount = BigInt(amount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const result = await txService.depositMock(userId, bigAmount);
            res.status(200).json({ message: 'Nạp tiền thành công', data: result });
        } catch (error) {
            console.error('Lỗi Nạp tiền:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi nạp tiền' });
        }
    },

    transfer: async (req, res) => {
        const senderId = req.user.userId;
        
        const { receiver_identifier, amount, note, reference_code, pin } = req.body;

        if (!receiver_identifier || !amount || !pin) {
            return res.status(400).json({ error: 'Vui lòng nhập người nhận, số tiền và mã PIN' });
        }

        let bigAmount;
        try {
            bigAmount = BigInt(amount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const result = await txService.transfer(senderId, receiver_identifier, bigAmount, note, reference_code, pin);
            res.status(200).json({ message: 'Chuyển tiền thành công', data: result });
        } catch (error) {
            if (error.message.startsWith('Wrong_PIN_')) {
                const attemptsLeft = error.message.split('_')[2];
                return res.status(400).json({ error: `Mã PIN không chính xác, bạn còn ${attemptsLeft} thử.` });
            }

            const errorMap = {
                'Wallet_Locked_PIN': 'Tài khoản tạm khóa tính năng chuyển tiền trong 30 phút do nhập sai mã PIN quá 3 lần.',
                'Sender_Wallet_Not_Found': 'Không tìm thấy ví của bạn hoặc bạn chưa thiết lập mã PIN',
                'Receiver_Wallet_Not_Found': 'Không tìm thấy ví người nhận (Sai SĐT/Email)',
                'Self_Transfer_Not_Allowed': 'Không thể tự chuyển tiền cho chính mình',
                'Insufficient_Balance': 'Số dư trong ví không đủ',
                'Receiver_Not_KYC': 'Người nhận chưa xác thực danh tính (KYC). Giao dịch bị từ chối!'
            };
            
            if (errorMap[error.message]) {
                return res.status(400).json({ error: errorMap[error.message] });
            }
            
            console.error('Lỗi Chuyển tiền:', error);
            res.status(500).json({ error: 'Giao dịch chuyển tiền thất bại' });
        }
    },

    getHistory: async (req, res) => {
        const userId = req.user.userId;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;

        try {
            const history = await txService.getTransactionHistory(userId, page, limit);
            res.status(200).json({
                success: true,
                page,
                limit,
                data: history
            });
        } catch (error) {
            if (error.message === 'Wallet_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy ví của người dùng' });
            }
            console.error('Lỗi lấy lịch sử giao dịch:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi lấy lịch sử giao dịch' });
        }
    }
};

module.exports = transactionController;