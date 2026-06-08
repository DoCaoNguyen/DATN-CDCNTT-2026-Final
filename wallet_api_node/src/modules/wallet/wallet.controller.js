const walletService = require('./wallet.service');
const pool = require('../../config/db');

const walletController = {
    getBalance: async (req, res) => {
        try {
            const userId = req.user.userId; 
            
            const result = await walletService.getWalletInfo(userId);
            
            res.status(200).json({ 
                message: 'Lấy thông tin số dư thành công', 
                data: result 
            });
        } catch (error) {
            if (error.message === 'Wallet_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy ví của người dùng này' });
            }
            console.error("Lỗi lấy số dư ví:", error);
            res.status(500).json({ error: 'Lỗi hệ thống khi lấy số dư' });
        }
    },

    setWalletCode: async (req, res) => {
        const userId = req.user.userId;
        const { wallet_code } = req.body;

        if (!wallet_code) {
            return res.status(400).json({ error: 'Vui lòng nhập mã ví.' });
        }

        const cleanCode = wallet_code.trim();

        const isValidFormat = /^\d{6}$/.test(cleanCode);
        if (!isValidFormat) {
            return res.status(400).json({ error: 'Mã ví không hợp lệ (Bắt buộc phải là 6 chữ số).' });
        }
        
        try {
    
            const newWalletCode = await walletService.setWalletCode(userId, cleanCode);
            
            res.status(200).json({ 
                message: 'Tạo mã ví thành công', 
                wallet_code: newWalletCode 
            });

        } catch (error) {
            if (error.message === 'Wallet_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy ví của người dùng.' });
            }
            if (error.message === 'Wallet_Code_Exists') {
                return res.status(400).json({ error: 'Mã ví này đã có người sử dụng. Vui lòng chọn mã khác.' });
            }
            
            console.error('Lỗi set wallet code:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tạo mã ví' });
        }
    },

    getPersonalQR: async (req, res) => {
        const userId = req.user.userId;
        const { amount, note } = req.query;

        try {
            if (amount) {
                const parsedAmount = BigInt(amount);
                if (parsedAmount <= 0n) {
                    return res.status(400).json({ error: 'Số tiền phải lớn hơn 0' });
                }
            }
        } catch (e) {
            return res.status(400).json({ error: 'Số tiền không hợp lệ' });
        }

        try {
            const result = await walletService.getPersonalQR(userId, amount, note);
            res.status(200).json({
                message: 'Tạo mã QR thanh toán thành công',
                data: result
            });
        } catch (error) {
            if (error.message === 'User_Not_Found') {
                return res.status(404).json({ error: 'Không tìm thấy thông tin người dùng.' });
            }
            console.error('Lỗi sinh mã QR chuyển tiền:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tạo mã QR thanh toán' });
        }
    }
};

module.exports = walletController;