const txService = require('../services/transaction.service');

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
        const { receiver_identifier, amount, note } = req.body;

        if (!receiver_identifier || !amount) {
            return res.status(400).json({ error: 'Vui lòng nhập người nhận và số tiền' });
        }

        let bigAmount;
        try {
            bigAmount = BigInt(amount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const result = await txService.transfer(senderId, receiver_identifier, bigAmount, note);
            res.status(200).json({ message: 'Chuyển tiền thành công', data: result });
        } catch (error) {
            const errorMap = {
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
    }
};

module.exports = transactionController;