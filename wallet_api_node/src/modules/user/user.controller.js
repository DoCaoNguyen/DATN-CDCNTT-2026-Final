const userService = require('./user.service'); 

const userController = {
    search: async (req, res) => {
        try {
            const currentUserId = req.user.userId; 
            let { q } = req.query; 

            
            if (!q || q.trim() === '') {
                return res.status(200).json({ data: [] });
            }

            q = q.trim();
            if (q.startsWith('+84')) {
                q = '0' + q.slice(3);
            } else if (q.startsWith('84') && q.length === 11) {
                q = '0' + q.slice(2);
            }
            
            const users = await userService.searchUsers(q, currentUserId);
            
            
            res.status(200).json({ data: users });

        } catch (error) {
            console.error("Lỗi tìm kiếm user:", error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tìm kiếm' });
        }
    },

    checkContacts: async (req, res) => {
        try {
            const currentUserId = req.user.userId;
            let { phones } = req.body;
            if (!phones || !Array.isArray(phones)) {
                return res.status(400).json({ error: 'Vui lòng cung cấp danh sách số điện thoại hợp lệ' });
            }
            
            phones = phones.map(p => {
                let val = String(p).trim();
                if (val.startsWith('+84')) return '0' + val.slice(3);
                if (val.startsWith('84') && val.length === 11) return '0' + val.slice(2);
                return val;
            });

            const users = await userService.checkContacts(phones, currentUserId);
            res.status(200).json({ data: users });
        } catch (error) {
            console.error("Lỗi so khớp danh bạ:", error);
            res.status(500).json({ error: 'Lỗi hệ thống khi kiểm tra danh bạ' });
        }
    },

    getProfile: async (req, res) => {
        try {
            const userId = req.user.userId; 
            const user = await userService.getUserProfile(userId);
            if (!user) {
                return res.status(404).json({ error: 'Không tìm thấy người dùng' });
            }
            res.status(200).json({ data: user });
        } catch (error) {
            console.error("Lỗi lấy thông tin profile:", error);
            res.status(500).json({ error: 'Lỗi hệ thống' });
        }
    },


    requestEmailOtp: async (req, res) => {
        try {
            const userId = req.user.userId;
            const { email } = req.body;
            if (!email) {
                return res.status(400).json({ error: 'Vui lòng cung cấp email' });
            }
            // Basic email validation
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                return res.status(400).json({ error: 'Email không hợp lệ' });
            }

            await userService.requestEmailOtp(userId, email);
            res.status(200).json({ message: 'Mã xác thực đã được gửi đến email của bạn' });
        } catch (error) {
            console.error("Lỗi yêu cầu gửi OTP email:", error);
            if (error.message.includes('đã được sử dụng')) {
                return res.status(400).json({ error: error.message });
            }
            res.status(500).json({ error: 'Không thể gửi email OTP' });
        }
    },

    verifyEmailOtp: async (req, res) => {
        try {
            const userId = req.user.userId;
            const { email, otp } = req.body;
            if (!email || !otp) {
                return res.status(400).json({ error: 'Vui lòng cung cấp email và mã OTP' });
            }

            await userService.verifyEmailOtp(userId, email, otp);
            res.status(200).json({ message: 'Xác thực email thành công' });
        } catch (error) {
            console.error("Lỗi xác thực OTP email:", error);
            const errMsg = error.message;
            if (errMsg.includes('không chính xác') || errMsg.includes('hết hạn') || errMsg.includes('chưa yêu cầu')) {
                return res.status(400).json({ error: errMsg });
            }
            res.status(500).json({ error: 'Lỗi hệ thống' });
        }
    }
};

module.exports = userController;