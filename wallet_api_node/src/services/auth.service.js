const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db'); 
const { sendSMS } = require('../utils/sms');
const userRepository = require('../repositories/user.repository');
const walletRepository = require('../repositories/wallet.repository');
const otpRepository = require('../repositories/otp.repository'); // Nhúng repo mới vào

const authService = {
    requestOtp: async (email, phone) => {
        // 1. Kiểm tra tồn tại trong bảng users
        const userExist = await userRepository.checkExists(email, phone);
        if (userExist) throw new Error('Email_Phone_Exists');

        // 2. Kiểm tra xem tài khoản có đang bị khóa hay không
        const record = await otpRepository.findByPhone(phone);
        if (record && record.locked_until && new Date(record.locked_until) > new Date()) {
            throw new Error('Account_Locked');
        }

        // 3. Sinh OTP và Lưu xuống DB thông qua Repository
        const otpCode = Math.floor(1000 + Math.random() * 9000).toString();
        await otpRepository.upsertOtp(phone, email, otpCode);

        // 4. Gửi SMS
        await sendSMS(phone, otpCode);
        return true;
    },

    verifyOtp: async (phone, otp) => {
        // 1. Lấy dữ liệu OTP từ DB
        const record = await otpRepository.findByPhone(phone);
        if (!record) throw new Error('OTP_Not_Found');

        // 2. Kiểm tra trạng thái khóa
        if (record.locked_until && new Date(record.locked_until) > new Date()) {
            throw new Error('Account_Locked');
        }

        // 3. Kiểm tra hết hạn (5 phút)
        if (new Date() > new Date(record.expired_at)) {
            throw new Error('OTP_Expired');
        }

        // 4. KIỂM TRA MÃ OTP SAI
        if (record.otp_code !== otp) {
            const newAttempts = record.failed_attempts + 1;
            
            // Nếu sai 5 lần -> Khóa 30 phút
            if (newAttempts >= 5) {
                await otpRepository.lockAccount(phone, newAttempts, 30);
                throw new Error('Account_Locked_Now');
            } else {
                // Nếu sai < 5 lần -> Cập nhật số lần sai
                await otpRepository.updateAttempts(phone, newAttempts);
                
                const remaining = 5 - newAttempts;
                const err = new Error('OTP_Invalid');
                err.remainingAttempts = remaining;
                throw err; 
            }
        }

        // 5. HỢP LỆ: Ký token và Xóa dữ liệu OTP tạm
        const registerToken = jwt.sign(
            { email: record.email, phone: phone }, 
            process.env.JWT_SECRET, 
            { expiresIn: '15m' }
        );
        
        await otpRepository.deleteByPhone(phone);
        
        return registerToken;
    },

    registerUserAndWallet: async (registerToken, password) => {
        const decoded = jwt.verify(registerToken, process.env.JWT_SECRET);
        const { email, phone } = decoded;

        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const saltRounds = 10;
            const passwordHash = await bcrypt.hash(password, saltRounds);
            
            const newUserId = await userRepository.create(client, email, phone, passwordHash);
            await walletRepository.create(client, newUserId);

            await client.query('COMMIT');
            return newUserId;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error; 
        } finally {
            client.release();
        }
    },

    login: async (identifier, password) => {
        const user = await userRepository.findByEmailOrPhone(identifier);
        if (!user) throw new Error('Invalid_Credentials'); 

        // 1. KIỂM TRA TÀI KHOẢN CÓ ĐANG BỊ KHÓA KHÔNG
        if (user.locked_until) {
            if (new Date(user.locked_until) > new Date()) {
                throw new Error('Account_Locked');
            } else {
                user.failed_login_attempts = 0; 
                await userRepository.resetFailedLogin(user.id);
            }
        }

        const isMatch = await bcrypt.compare(password, user.password_hash);
        
        // 2. XỬ LÝ KHI SAI MẬT KHẨU
        if (!isMatch) {
            const newAttempts = (user.failed_login_attempts || 0) + 1;
            
            // Nếu sai 5 lần -> Khóa 30 phút
            if (newAttempts >= 5) {
                await userRepository.updateFailedLogin(user.id, newAttempts, 30);
                throw new Error('Account_Locked_Now');
            } 
            // Nếu sai < 5 lần -> Cộng dồn số lần sai
            else {
                await userRepository.updateFailedLogin(user.id, newAttempts, 0);
                const err = new Error('Invalid_Credentials');
                err.remainingAttempts = 5 - newAttempts; // Báo về số lần thử còn lại
                throw err;
            }
        } 

        // 3. XỬ LÝ KHI ĐÚNG MẬT KHẨU
        if (user.status !== 'ACTIVE') throw new Error('Account_Inactive');

        // Reset lại số lần sai về 0 (nếu trước đó có nhập sai)
        if (user.failed_login_attempts > 0 || user.locked_until) {
            await userRepository.resetFailedLogin(user.id);
        }

        // Tạo JWT Token
        const accessToken = jwt.sign(
            { userId: user.id, role: user.role }, 
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        return {
            access_token: accessToken,
            user_info: { 
                id: user.id, 
                email: user.email, 
                phone: user.phone, 
                role: user.role,
                is_kyc_verified: user.is_kyc_verified
            }
        };
    }
};

module.exports = authService;