const txService = require('./transaction.service');

const transactionController = {
    deposit: async (req, res) => {
        const userId = req.user.userId;
        const { amount, pin, external_reference } = req.body;
        const faceImagePath = req.file ? req.file.path : null;

        let bigAmount;
        try {
            bigAmount = BigInt(amount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const result = await txService.deposit(userId, bigAmount, pin, faceImagePath, external_reference);
            res.status(200).json({ message: 'Nạp tiền thành công', data: result });
        } catch (error) {
            if (error.message.startsWith('Wrong_PIN_')) {
                const attemptsLeft = error.message.split('_')[2];
                return res.status(400).json({ error: `Mã PIN không chính xác, bạn còn ${attemptsLeft} lần thử.` });
            }

            const errorMap = {
                'Wallet_Locked_PIN': 'Tài khoản tạm khóa trong 30 phút do nhập sai mã PIN quá 3 lần.',
                'Wallet_Not_Found': 'Không tìm thấy ví của bạn hoặc bạn chưa thiết lập mã PIN',
                'PIN_Required': 'Vui lòng cung cấp mã PIN',
                'Face_Verification_Required': 'Yêu cầu hình ảnh quét khuôn mặt cho giao dịch từ 50 triệu trở lên',
                'No_KYC_Record_Found': 'Không tìm thấy dữ liệu khuôn mặt KYC để đối chiếu. Vui lòng hoàn tất KYC.',
                'Face_Verification_Failed': 'Xác thực khuôn mặt không trùng khớp với dữ liệu eKYC.'
            };

            if (errorMap[error.message]) {
                return res.status(400).json({ error: errorMap[error.message] });
            }

            console.error('Lỗi Nạp tiền:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi nạp tiền' });
        }
    },

    withdraw: async (req, res) => {
        const userId = req.user.userId;
        const { amount, pin, linked_bank_id, external_reference } = req.body;
        const faceImagePath = req.file ? req.file.path : null;

        if (!linked_bank_id) {
            return res.status(400).json({ error: 'Vui lòng chọn ngân hàng rút tiền' });
        }

        let bigAmount;
        try {
            bigAmount = BigInt(amount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const result = await txService.withdraw(userId, bigAmount, pin, faceImagePath, linked_bank_id, external_reference);
            res.status(200).json({ message: 'Rút tiền thành công', data: result });
        } catch (error) {
            if (error.message.startsWith('Wrong_PIN_')) {
                const attemptsLeft = error.message.split('_')[2];
                return res.status(400).json({ error: `Mã PIN không chính xác, bạn còn ${attemptsLeft} lần thử.` });
            }

            const errorMap = {
                'Wallet_Locked_PIN': 'Tài khoản tạm khóa trong 30 phút do nhập sai mã PIN quá 3 lần.',
                'Wallet_Not_Found': 'Không tìm thấy ví của bạn hoặc bạn chưa thiết lập mã PIN',
                'PIN_Required': 'Vui lòng cung cấp mã PIN',
                'Face_Verification_Required': 'Yêu cầu hình ảnh quét khuôn mặt cho giao dịch từ 50 triệu trở lên',
                'No_KYC_Record_Found': 'Không tìm thấy dữ liệu khuôn mặt KYC để đối chiếu. Vui lòng hoàn tất KYC.',
                'Face_Verification_Failed': 'Xác thực khuôn mặt không trùng khớp với dữ liệu eKYC.',
                'Insufficient_Balance': 'Số dư trong ví không đủ để rút số tiền này.'
            };

            if (errorMap[error.message]) {
                return res.status(400).json({ error: errorMap[error.message] });
            }

            console.error('Lỗi Rút tiền:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi rút tiền' });
        }
    },

    bankTransfer: async (req, res) => {
        const userId = req.user.userId;
        const { amount, pin, bank_code, bank_name, account_number, external_reference } = req.body;
        const faceImagePath = req.file ? req.file.path : null;

        if (!bank_code || !account_number) {
            return res.status(400).json({ error: 'Vui lòng cung cấp ngân hàng và số tài khoản nhận' });
        }

        let bigAmount;
        try {
            bigAmount = BigInt(amount);
            if (bigAmount <= 0n) throw new Error();
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const result = await txService.bankTransfer(
                userId,
                bigAmount,
                pin,
                faceImagePath,
                bank_code,
                bank_name || bank_code,
                account_number,
                external_reference
            );
            res.status(200).json({ message: 'Chuyển tiền ngân hàng thành công', data: result });
        } catch (error) {
            if (error.message.startsWith('Wrong_PIN_')) {
                const attemptsLeft = error.message.split('_')[2];
                return res.status(400).json({ error: `Mã PIN không chính xác, bạn còn ${attemptsLeft} lần thử.` });
            }

            const errorMap = {
                'Wallet_Locked_PIN': 'Tài khoản tạm khóa trong 30 phút do nhập sai mã PIN quá 3 lần.',
                'Wallet_Not_Found': 'Không tìm thấy ví của bạn hoặc bạn chưa thiết lập mã PIN',
                'PIN_Required': 'Vui lòng cung cấp mã PIN',
                'Face_Verification_Required': 'Yêu cầu hình ảnh quét khuôn mặt cho giao dịch từ 50 triệu trở lên',
                'No_KYC_Record_Found': 'Không tìm thấy dữ liệu khuôn mặt KYC để đối chiếu. Vui lòng hoàn tất KYC.',
                'Face_Verification_Failed': 'Xác thực khuôn mặt không trùng khớp với dữ liệu eKYC.',
                'Insufficient_Balance': 'Số dư trong ví không đủ để thực hiện giao dịch này.'
            };

            if (errorMap[error.message]) {
                return res.status(400).json({ error: errorMap[error.message] });
            }

            console.error('Lỗi Chuyển tiền ngân hàng:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi chuyển tiền ngân hàng' });
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
    },

    updateCategory: async (req, res) => {
        const transactionId = req.params.id;
        const { category_name, is_expense_counted } = req.body;
        const userId = req.user.userId;

        try {
            const result = await txService.updateTransactionCategory(
                userId,
                transactionId,
                category_name,
                is_expense_counted !== undefined ? is_expense_counted : true
            );
            res.status(200).json({
                success: true,
                message: 'Cập nhật danh mục thành công',
                data: result
            });
        } catch (error) {
            if (error.message === 'Forbidden_Error') {
                return res.status(403).json({ error: 'Bạn không có quyền chỉnh sửa giao dịch này' });
            }
            if (error.message === 'Transaction_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
            }
            console.error('Lỗi cập nhật danh mục giao dịch:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi cập nhật danh mục' });
        }
    },

    getStats: async (req, res) => {
        const userId = req.user.userId;
        try {
            const stats = await txService.getMonthlyStats(userId);
            res.status(200).json({
                success: true,
                data: stats
            });
        } catch (error) {
            if (error.message === 'Wallet_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy ví của người dùng' });
            }
            console.error('Lỗi lấy thống kê giao dịch:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi lấy thống kê' });
        }
    },

    getByMonth: async (req, res) => {
        const userId = req.user.userId;
        const month = parseInt(req.query.month);
        const year = parseInt(req.query.year);

        if (!month || !year) {
            return res.status(400).json({ error: 'Vui lòng cung cấp month và year' });
        }

        try {
            const transactions = await txService.getTransactionsByMonth(userId, month, year);
            res.status(200).json({
                success: true,
                data: transactions
            });
        } catch (error) {
            if (error.message === 'Wallet_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy ví của người dùng' });
            }
            console.error('Lỗi lấy giao dịch theo tháng:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi lấy giao dịch theo tháng' });
        }
    },

    getChatList: async (req, res) => {
        const userId = req.user.userId;
        try {
            const chats = await txService.getChatList(userId);
            res.status(200).json({
                success: true,
                data: chats
            });
        } catch (error) {
            if (error.message === 'Wallet_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy ví của người dùng' });
            }
            console.error('Lỗi lấy danh sách chat:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi lấy danh sách chat' });
        }
    },

    getChatHistory: async (req, res) => {
        const userId = req.user.userId;
        const phone = req.params.phone;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;

        try {
            const history = await txService.getChatHistory(userId, phone, page, limit);
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
            console.error('Lỗi lấy chi tiết chat:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi lấy chi tiết chat' });
        }
    }
};

module.exports = transactionController;