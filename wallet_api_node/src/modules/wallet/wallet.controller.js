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

    checkWalletCode: async (req, res) => {
        try {
            const { code } = req.params;

            if (!code) {
                return res.status(400).json({ error: 'Vui lòng cung cấp mã ví cần kiểm tra' });
            }

            const walletInfo = await walletService.checkWalletCodeInfo(code);
            
            res.status(200).json({ 
                message: 'Thông tin ví hợp lệ', 
                data: walletInfo 
            });

        } catch (error) {
            if (error.message === 'Wallet_Code_Not_Found') {
                return res.status(404).json({ error: 'Mã ví không tồn tại trong hệ thống' });
            }
            console.error("Lỗi kiểm tra mã ví:", error);
            res.status(500).json({ error: 'Lỗi hệ thống khi kiểm tra thông tin ví' });
        }
    }
};

module.exports = walletController;