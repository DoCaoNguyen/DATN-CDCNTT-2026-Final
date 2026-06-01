const authService = require('../services/auth.service');

const authController = {
    // API 1: Yêu cầu gửi OTP
    sendOtp: async (req, res) => {
        const { email, phone } = req.body;
        if (!email || !phone) return res.status(400).json({ error: 'Cần cung cấp Email và SĐT' });

        try {
            await authService.requestOtp(email, phone);
            res.status(200).json({ message: 'Đã gửi mã OTP qua Email' });
        } catch (error) {
            // Bắt lỗi từ tầng Service ném lên
            if (error.message === 'Email_Phone_Exists') {
                return res.status(400).json({ error: 'Email hoặc Số điện thoại đã được đăng ký' });
            }
            console.error(error);
            res.status(500).json({ error: 'Lỗi server khi gửi OTP' });
        }
    },

    // API 2: Xác thực OTP và cấp Token Tạm thời
    verifyOtp: (req, res) => {
        const { email, otp } = req.body;
        if (!email || !otp) return res.status(400).json({ error: 'Cần cung cấp Email và OTP' });

        try {
            const token = authService.verifyOtp(email, otp);
            res.status(200).json({ 
                message: 'Xác thực OTP thành công',
                register_token: token 
            });
        } catch (error) {
            // Dịch các mã lỗi từ Service thành câu thông báo cho Frontend
            const errorMessages = {
                'OTP_Not_Found': 'Không tìm thấy yêu cầu OTP cho email này',
                'OTP_Expired': 'Mã OTP đã hết hạn',
                'OTP_Invalid': 'Mã OTP không chính xác'
            };
            const message = errorMessages[error.message] || 'Lỗi xác thực OTP';
            res.status(400).json({ error: message });
        }
    },

    // API 3: Nhập Mật khẩu và Ghi vào DB
    setPassword: async (req, res) => {
        const { register_token, password } = req.body;
        if (!register_token || !password) return res.status(400).json({ error: 'Thiếu token hoặc mật khẩu' });

        try {
            await authService.registerUserAndWallet(register_token, password);
            res.status(201).json({ message: 'Tạo tài khoản và Ví thành công!' });
        } catch (error) {
            // Xử lý lỗi Token do thư viện jsonwebtoken văng ra
            if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
                return res.status(401).json({ error: 'Token đăng ký không hợp lệ hoặc đã hết hạn' });
            }
            
            console.error('Lỗi DB:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tạo tài khoản' });
        }
    },

    login: async (req, res) => {
        // Client có thể gửi 'identifier' là email hoặc sđt
        const { identifier, password } = req.body; 
        
        if (!identifier || !password) {
            return res.status(400).json({ error: 'Vui lòng nhập Email/Số điện thoại và Mật khẩu' });
        }

        try {
            const result = await authService.login(identifier, password);
            res.status(200).json({
                message: 'Đăng nhập thành công',
                data: result
            });
        } catch (error) {
            if (error.message === 'Invalid_Credentials') {
                return res.status(401).json({ error: 'Tài khoản hoặc mật khẩu không chính xác' });
            }
            if (error.message === 'Account_Inactive') {
                return res.status(403).json({ error: 'Tài khoản đã bị khóa hoặc chưa kích hoạt' });
            }
            
            console.error('Lỗi API Login:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi đăng nhập' });
        }
    }
};

module.exports = authController;