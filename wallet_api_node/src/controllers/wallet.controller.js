const walletService = require('../services/wallet.service');

const walletController = {
    getBalance: async (req, res) => {
        try {
            // Lấy userId từ Token do Auth Middleware giải mã
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
    }
};

module.exports = walletController;