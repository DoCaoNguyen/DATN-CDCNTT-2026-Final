const authService = require('./auth.service');

const authController = {
    sendOtp: async (req, res) => {
        const { email, phone } = req.body;
        if (!phone) return res.status(400).json({ error: 'Cần cung cấp Số điện thoại' });

        try {
            if (email) {
                await authService.requestOtp(email, phone);
            } else {
                await authService.requestOtp(phone);
            }
            res.status(200).json({ message: 'Đã gửi mã OTP qua tin nhắn SMS' });
        } catch (error) {
            if (error.message === 'Email_Phone_Exists') {
                return res.status(400).json({ error: 'Email hoặc Số điện thoại đã được đăng ký', isExist: true });
            }
            if (error.message === 'Account_Locked') {
                return res.status(403).json({ error: 'Số điện thoại này đang bị khóa bảo mật. Vui lòng thử lại sau 30 phút.' });
            }
            console.error(error);
            res.status(500).json({ error: 'Lỗi server khi gửi OTP' });
        }
    },

    verifyOtp: async (req, res) => {
        const { phone, otp } = req.body;
        if (!phone || !otp) return res.status(400).json({ error: 'Cần cung cấp Số điện thoại và OTP' });

        try {
            const token = await authService.verifyOtp(phone, otp);
            res.status(200).json({
                message: 'Xác thực OTP thành công',
                register_token: token
            });

        } catch (error) {

            if (error.message === 'Account_Locked' || error.message === 'Account_Locked_Now') {
                return res.status(403).json({
                    error: 'Tài khoản của bạn đã bị khóa do nhập sai quá nhiều lần. Vui lòng thử lại sau 30 phút.'
                });
            }

            if (error.message === 'OTP_Invalid') {
                return res.status(400).json({
                    error: 'Mã OTP không chính xác',
                    remainingAttempts: error.remainingAttempts
                });
            }

            const errorMessages = {
                'OTP_Not_Found': 'Không tìm thấy yêu cầu OTP cho số điện thoại này',
                'OTP_Expired': 'Mã OTP đã hết hạn'
            };
            const message = errorMessages[error.message] || 'Lỗi xác thực OTP';
            res.status(400).json({ error: message });
        }
    },

    setPassword: async (req, res) => {
        const { register_token, password } = req.body;
        if (!register_token || !password) return res.status(400).json({ error: 'Thiếu token hoặc mật khẩu' });

        try {
            await authService.registerUserAndWallet(register_token, password);
            res.status(201).json({ message: 'Tạo tài khoản và Ví thành công!' });
        } catch (error) {
            if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
                return res.status(401).json({ error: 'Token đăng ký không hợp lệ hoặc đã hết hạn' });
            }
            console.error('Lỗi DB:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi tạo tài khoản' });
        }
    },

    login: async (req, res) => {
        const { identifier, password } = req.body;

        if (!identifier || !password) {
            return res.status(400).json({ error: 'Vui lòng nhập Email/Số điện thoại và Mật khẩu' });
        }

        try {
            const ipAddress = req.ip || req.connection.remoteAddress;
            const userAgent = req.headers['user-agent'] || '';
            const result = await authService.login(identifier, password, ipAddress, userAgent);
            res.status(200).json({
                message: 'Đăng nhập thành công',
                data: result
            });
        } catch (error) {

            if (error.message === 'Account_Locked' || error.message === 'Account_Locked_Now') {
                return res.status(403).json({
                    error: 'Tài khoản của bạn đã bị khóa 30 phút do nhập sai mật khẩu quá nhiều lần.'
                });
            }

            if (error.message === 'Invalid_Credentials') {
                const remaining = error.remainingAttempts;
                const errorMsg = remaining
                    ? `Mật khẩu không chính xác. Bạn còn ${remaining} lần thử.`
                    : 'Tài khoản hoặc mật khẩu không chính xác.';

                return res.status(401).json({
                    error: errorMsg,
                    remainingAttempts: remaining
                });
            }

            if (error.message === 'Account_Inactive') {
                return res.status(403).json({ error: 'Tài khoản đã bị khóa hoặc chưa kích hoạt' });
            }

            console.error('Lỗi API Login:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi đăng nhập' });
        }
    },

    logout: async (req, res) => {
        const { refresh_token } = req.body;
        if (!refresh_token) {
            return res.status(400).json({ error: 'Cần cung cấp Refresh Token để đăng xuất' });
        }

        try {
            await authService.logout(refresh_token);
            res.status(200).json({ message: 'Đăng xuất thành công' });
        } catch (error) {
            console.error('Lỗi API Logout:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi đăng xuất' });
        }
    },

    refreshToken: async (req, res) => {
        const { refresh_token } = req.body;
        if (!refresh_token) {
            return res.status(400).json({ error: 'Thiếu Refresh Token' });
        }

        try {
            const ipAddress = req.ip || req.connection.remoteAddress;
            const userAgent = req.headers['user-agent'] || '';
            const result = await authService.refreshToken(refresh_token, ipAddress, userAgent);
            res.status(200).json({
                message: 'Refresh token thành công',
                data: result
            });
        } catch (error) {
            if (error.message === 'Refresh_Token_Reused') {
                return res.status(403).json({ error: 'Phiên đăng nhập bị xâm phạm. Vui lòng đăng nhập lại.' });
            }
            if (['Invalid_Refresh_Token', 'Refresh_Token_Expired', 'Refresh_Token_Revoked'].includes(error.message)) {
                return res.status(401).json({ error: 'Phiên làm việc hết hạn. Vui lòng đăng nhập lại.' });
            }
            if (error.message === 'Account_Inactive') {
                return res.status(403).json({ error: 'Tài khoản đã bị khóa hoặc chưa kích hoạt' });
            }
            console.error('Lỗi API Refresh Token:', error);
            res.status(500).json({ error: 'Lỗi hệ thống khi refresh token' });
        }
    }
};

module.exports = authController;