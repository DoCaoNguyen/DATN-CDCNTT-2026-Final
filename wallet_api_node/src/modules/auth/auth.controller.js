const authService = require('./auth.service');

function getRequestMeta(req) {
    return {
        ipAddress: req.ip || req.connection.remoteAddress,
        userAgent: req.headers['user-agent'] || null
    };
}

function success(res, data, message = 'OK', status = 200) {
    return res.status(status).json({
        success: true,
        code: 'OK',
        message,
        data
    });
}

function error(res, status, code, message, extra = {}) {
    return res.status(status).json({
        success: false,
        code,
        error: message,
        ...extra
    });
}

const authController = {
    register: async (req, res) => {
        const { full_name, username, email, phone, password, confirm_password } = req.body;
        try {
            const result = await authService.register({
                fullName: full_name,
                username,
                email,
                phone,
                password,
                confirmPassword: confirm_password,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Đăng ký tài khoản thành công', 201);
        } catch (err) {
            if (err.message === 'Validation_Error') return error(res, 400, 'VALIDATION_ERROR', 'Thiếu thông tin đăng ký bắt buộc');
            if (err.message === 'Password_Confirm_Not_Match') return error(res, 400, 'VALIDATION_ERROR', 'Mật khẩu xác nhận không khớp');
            if (err.message === 'Password_Policy_Invalid') return error(res, 400, 'VALIDATION_ERROR', 'Mật khẩu phải có tối thiểu 8 ký tự');
            if (err.message === 'Email_Phone_Exists') return error(res, 409, 'CONFLICT', 'Email hoặc số điện thoại đã được đăng ký');
            console.error('Lỗi API Register:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi đăng ký');
        }
    },

    sendOtp: async (req, res) => {
        const { email, phone } = req.body;
        if (!phone) return error(res, 400, 'VALIDATION_ERROR', 'Cần cung cấp số điện thoại');

        try {
            if (email) {
                await authService.requestOtp(email, phone);
            } else {
                await authService.requestOtp(phone);
            }
            return success(res, null, 'Đã gửi mã OTP qua tin nhắn SMS');
        } catch (err) {
            if (err.message === 'Email_Phone_Exists') {
                return error(res, 400, 'CONFLICT', 'Email hoặc số điện thoại đã được đăng ký', { isExist: true });
            }
            if (err.message === 'Account_Locked') {
                return error(res, 403, 'ACCOUNT_LOCKED', 'Số điện thoại này đang bị khóa bảo mật. Vui lòng thử lại sau.');
            }
            console.error(err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi server khi gửi OTP');
        }
    },

    verifyOtp: async (req, res) => {
        const { phone, otp } = req.body;
        if (!phone || !otp) return error(res, 400, 'VALIDATION_ERROR', 'Cần cung cấp số điện thoại và OTP');

        try {
            const token = await authService.verifyOtp(phone, otp);
            return success(res, { register_token: token }, 'Xác thực OTP thành công');
        } catch (err) {
            if (err.message === 'Account_Locked' || err.message === 'Account_Locked_Now') {
                return error(res, 403, 'ACCOUNT_LOCKED', 'Tài khoản đã bị khóa do nhập sai quá nhiều lần.');
            }
            if (err.message === 'OTP_Invalid') {
                return error(res, 400, 'VALIDATION_ERROR', 'Mã OTP không chính xác', {
                    remainingAttempts: err.remainingAttempts
                });
            }

            const errorMessages = {
                OTP_Not_Found: 'Không tìm thấy yêu cầu OTP cho số điện thoại này',
                OTP_Expired: 'Mã OTP đã hết hạn'
            };
            return error(res, 400, 'VALIDATION_ERROR', errorMessages[err.message] || 'Lỗi xác thực OTP');
        }
    },

    setPassword: async (req, res) => {
        const { register_token, password } = req.body;
        if (!register_token || !password) return error(res, 400, 'VALIDATION_ERROR', 'Thiếu token hoặc mật khẩu');

        try {
            await authService.registerUserAndWallet(register_token, password);
            return success(res, null, 'Tạo tài khoản và ví thành công', 201);
        } catch (err) {
            if (err.name === 'TokenExpiredError' || err.name === 'JsonWebTokenError') {
                return error(res, 401, 'UNAUTHORIZED', 'Token đăng ký không hợp lệ hoặc đã hết hạn');
            }
            console.error('Lỗi DB:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi tạo tài khoản');
        }
    },

    login: async (req, res) => {
        const loginId = req.body.login_id || req.body.identifier;
        const { password } = req.body;
        const rememberMe = Boolean(req.body.remember_me);

        if (!loginId || !password) {
            return error(res, 400, 'VALIDATION_ERROR', 'Vui lòng nhập username/email/số điện thoại và mật khẩu');
        }

        try {
            const result = await authService.login({
                loginId,
                password,
                rememberMe,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Đăng nhập thành công');
        } catch (err) {
            if (err.message === 'Account_Locked' || err.message === 'Account_Locked_Now') {
                return error(res, 403, 'ACCOUNT_LOCKED', 'Tài khoản đã bị khóa do đăng nhập sai quá nhiều lần.');
            }

            if (err.message === 'Invalid_Credentials') {
                return error(res, 401, 'INVALID_CREDENTIALS', 'Tài khoản hoặc mật khẩu không chính xác.', {
                    remainingAttempts: err.remainingAttempts
                });
            }

            if (err.message === 'Account_Inactive') {
                return error(res, 403, 'FORBIDDEN', 'Tài khoản đã bị khóa hoặc chưa kích hoạt');
            }

            if (err.message === 'Auth_Config_Missing') {
                return error(res, 500, 'AUTH_CONFIG_MISSING', 'Thiếu JWT_SECRET trong cấu hình môi trường');
            }

            console.error('Lỗi API Login:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi đăng nhập');
        }
    },

    refreshToken: async (req, res) => {
        const { refresh_token } = req.body;
        if (!refresh_token) return error(res, 400, 'VALIDATION_ERROR', 'Thiếu refresh_token');

        try {
            const result = await authService.refreshToken({
                refreshToken: refresh_token,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Refresh token thành công');
        } catch (err) {
            if (err.message === 'Refresh_Token_Invalid') {
                return error(res, 401, 'REFRESH_TOKEN_INVALID', 'Refresh token không hợp lệ');
            }
            console.error('Lỗi refresh token:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi refresh token');
        }
    },

    logout: async (req, res) => {
        const { refresh_token } = req.body;

        try {
            await authService.logout({
                userId: req.user.userId,
                refreshToken: refresh_token,
                ...getRequestMeta(req)
            });
            return success(res, null, 'Đăng xuất thành công');
        } catch (err) {
            if (err.message === 'Refresh_Token_Required') {
                return error(res, 400, 'VALIDATION_ERROR', 'Thiếu refresh_token');
            }
            if (err.message === 'Refresh_Token_Invalid') {
                return error(res, 401, 'REFRESH_TOKEN_INVALID', 'Refresh token không hợp lệ');
            }
            console.error('Lỗi API Logout:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi đăng xuất');
        }
    },

    revokeToken: async (req, res) => {
        const { refresh_token, revoke_all } = req.body;

        try {
            await authService.revokeToken({
                userId: req.user.userId,
                refreshToken: refresh_token,
                revokeAll: Boolean(revoke_all),
                ipAddress: getRequestMeta(req).ipAddress
            });
            return success(res, null, 'Revoke token thành công');
        } catch (err) {
            if (err.message === 'Refresh_Token_Required') {
                return error(res, 400, 'VALIDATION_ERROR', 'Thiếu refresh_token');
            }
            if (err.message === 'Refresh_Token_Invalid') {
                return error(res, 401, 'REFRESH_TOKEN_INVALID', 'Refresh token không hợp lệ');
            }
            console.error('Lỗi revoke token:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi revoke token');
        }
    },

    me: async (req, res) => {
        try {
            const result = await authService.getMe(req.user.userId);
            return success(res, result, 'Lấy thông tin người dùng hiện tại thành công');
        } catch (err) {
            if (err.message === 'User_Not_Found') {
                return error(res, 401, 'UNAUTHORIZED', 'Người dùng không tồn tại');
            }
            console.error('Lỗi API Me:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi lấy thông tin người dùng');
        }
    },

    forgotPassword: async (req, res) => {
        const loginId = req.body.login_id || req.body.identifier;
        if (!loginId) return error(res, 400, 'VALIDATION_ERROR', 'Thiếu login_id');

        try {
            const result = await authService.forgotPassword({
                loginId,
                ...getRequestMeta(req)
            });
            return success(res, result, 'Nếu tài khoản tồn tại, thông tin đặt lại mật khẩu đã được tạo');
        } catch (err) {
            console.error('Lỗi forgot password:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi yêu cầu đặt lại mật khẩu');
        }
    },

    resetPassword: async (req, res) => {
        const { reset_token, new_password, confirm_new_password } = req.body;
        if (!reset_token || !new_password || !confirm_new_password) return error(res, 400, 'VALIDATION_ERROR', 'Thiếu thông tin đặt lại mật khẩu');

        try {
            await authService.resetPassword({
                resetToken: reset_token,
                newPassword: new_password,
                confirmNewPassword: confirm_new_password,
                ...getRequestMeta(req)
            });
            return success(res, null, 'Đặt lại mật khẩu thành công');
        } catch (err) {
            if (err.message === 'Password_Reset_Token_Invalid') return error(res, 400, 'PASSWORD_RESET_TOKEN_INVALID', 'Reset token không hợp lệ hoặc đã hết hạn');
            if (err.message === 'Password_Confirm_Not_Match') return error(res, 400, 'VALIDATION_ERROR', 'Mật khẩu xác nhận không khớp');
            if (err.message === 'Password_Policy_Invalid') return error(res, 400, 'VALIDATION_ERROR', 'Mật khẩu phải có tối thiểu 8 ký tự');
            console.error('Lỗi reset password:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi đặt lại mật khẩu');
        }
    },

    changePassword: async (req, res) => {
        const { current_password, new_password, confirm_new_password, revoke_other_sessions } = req.body;
        if (!current_password || !new_password || !confirm_new_password) return error(res, 400, 'VALIDATION_ERROR', 'Thiếu thông tin đổi mật khẩu');

        try {
            await authService.changePassword({
                userId: req.user.userId,
                currentPassword: current_password,
                newPassword: new_password,
                confirmNewPassword: confirm_new_password,
                revokeOtherSessions: revoke_other_sessions !== false,
                ...getRequestMeta(req)
            });
            return success(res, null, 'Đổi mật khẩu thành công');
        } catch (err) {
            if (err.message === 'Invalid_Current_Password') return error(res, 401, 'INVALID_CREDENTIALS', 'Mật khẩu hiện tại không chính xác');
            if (err.message === 'Password_Same_As_Current') return error(res, 400, 'VALIDATION_ERROR', 'Mật khẩu mới không được trùng mật khẩu hiện tại');
            if (err.message === 'Password_Confirm_Not_Match') return error(res, 400, 'VALIDATION_ERROR', 'Mật khẩu xác nhận không khớp');
            if (err.message === 'Password_Policy_Invalid') return error(res, 400, 'VALIDATION_ERROR', 'Mật khẩu phải có tối thiểu 8 ký tự');
            console.error('Lỗi change password:', err);
            return error(res, 500, 'INTERNAL_SERVER_ERROR', 'Lỗi hệ thống khi đổi mật khẩu');
        }
    }
};

module.exports = authController;
