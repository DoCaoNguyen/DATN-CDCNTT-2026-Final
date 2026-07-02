const wealthBagRepository = require('./wealth_bag.repository');

const wealthBagController = {
    getStatus: async (req, res) => {
        try {
            const userId = req.user.userId;
            const status = await wealthBagRepository.getWealthBagStatus(userId);
            
            if (!status) {
                return res.status(200).json({ 
                    success: true, 
                    data: { is_active: false, balance: '0', total_profit: '0' } 
                });
            }
            
            return res.status(200).json({ success: true, data: status });
        } catch (error) {
            console.error('Error getting wealth bag status:', error);
            res.status(500).json({ success: false, message: 'Lỗi máy chủ nội bộ' });
        }
    },

    activate: async (req, res) => {
        try {
            const userId = req.user.userId;
            // Xác thực PIN / Biometric đã được client xử lý thông qua API /verify-pin trước đó.
            // Ở đây chỉ đơn thuần kích hoạt Túi Thần Tài.
            
            const newWealthBag = await wealthBagRepository.activateWealthBag(userId);
            
            return res.status(200).json({ 
                success: true, 
                message: 'Kích hoạt Túi Thần Tài thành công',
                data: newWealthBag 
            });
        } catch (error) {
            console.error('Error activating wealth bag:', error);
            res.status(500).json({ success: false, message: 'Lỗi máy chủ nội bộ' });
        }
    }
};

module.exports = wealthBagController;
