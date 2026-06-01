const txService = require('../services/transaction.service');

const transactionController = {
    deposit: async (req, res) => {
        const userId = req.user.userId; // Lấy từ token qua Middleware
        const { amount } = req.body;

        try {
            const result = await txService.depositMock(userId, Number(amount));
            res.status(200).json({ message: 'Nạp tiền thành công', data: result });
        } catch (error) {
            if (error.message === 'Invalid_Amount') return res.status(400).json({ error: 'Số tiền không hợp lệ' });
            console.error('Lỗi Nạp tiền:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi nạp tiền' });
        }
    },

    transfer: async (req, res) => {
        const senderId = req.user.userId;
        const { receiver_identifier, amount, note } = req.body;

        if (!receiver_identifier || !amount) {
            return res.status(400).json({ error: 'Vui lòng nhập người nhận và số tiền' });
        }

        try {
            const result = await txService.transfer(senderId, receiver_identifier, Number(amount), note);
            res.status(200).json({ message: 'Chuyển tiền thành công', data: result });
        } catch (error) {
            const errorMap = {
                'Invalid_Amount': 'Số tiền không hợp lệ',
                'Receiver_Wallet_Not_Found': 'Không tìm thấy ví người nhận (Sai SĐT/Email)',
                'Self_Transfer_Not_Allowed': 'Không thể tự chuyển tiền cho chính mình',
                'Insufficient_Balance': 'Số dư trong ví không đủ'
            };
            
            if (errorMap[error.message]) {
                return res.status(400).json({ error: errorMap[error.message] });
            }
            
            console.error('Lỗi Chuyển tiền:', error);
            res.status(500).json({ error: 'Giao dịch chuyển tiền thất bại' });
        }
    }
};

module.exports = transactionController;