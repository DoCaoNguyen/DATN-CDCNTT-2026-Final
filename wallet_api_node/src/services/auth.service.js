const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db'); // Vẫn cần pool để tạo Transaction (client)
const { sendOTP } = require('../utils/mailer');
const userRepository = require('../repositories/user.repository');
const walletRepository = require('../repositories/wallet.repository');

global.otpStorage = {};

const authService = {
    requestOtp: async (email, phone) => {
        // 1. Gọi Repo để kiểm tra tồn tại
        const userExist = await userRepository.checkExists(email, phone);
        if (userExist) {
            throw new Error('Email_Phone_Exists');
        }

        // 2. Sinh và lưu OTP
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        global.otpStorage[email] = { 
            otp: otpCode, 
            phone: phone, 
            expiresAt: Date.now() + 5 * 60 * 1000 
        };

        // 3. Gửi mail
        await sendOTP(email, otpCode);
        return true;
    },

    verifyOtp: (email, otp) => {
        // ... (Giữ nguyên logic kiểm tra và sinh JWT như cũ)
        const record = global.otpStorage[email];
        if (!record) throw new Error('OTP_Not_Found');
        if (Date.now() > record.expiresAt) throw new Error('OTP_Expired');
        if (record.otp !== otp) throw new Error('OTP_Invalid');

        const registerToken = jwt.sign(
            { email: email, phone: record.phone }, 
            process.env.JWT_SECRET, 
            { expiresIn: '15m' }
        );
        delete global.otpStorage[email];
        return registerToken;
    },

    registerUserAndWallet: async (registerToken, password) => {
        const decoded = jwt.verify(registerToken, process.env.JWT_SECRET);
        const { email, phone } = decoded;

        // Bắt đầu Transaction
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            
            const saltRounds = 10;
            const passwordHash = await bcrypt.hash(password, saltRounds);
            
            // 1. Gọi Repo tạo User, BẮT BUỘC TRUYỀN 'client' XUỐNG
            const newUserId = await userRepository.create(client, email, phone, passwordHash);

            // 2. Gọi Repo tạo Wallet, BẮT BUỘC TRUYỀN 'client' XUỐNG
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
        // 1. Tìm user trong DB
        const user = await userRepository.findByEmailOrPhone(identifier);
        if (!user) {
            throw new Error('Invalid_Credentials'); // Không tìm thấy user
        }

        // 2. So sánh mật khẩu đã băm
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            throw new Error('Invalid_Credentials'); // Sai mật khẩu
        }

        // 3. Kiểm tra trạng thái tài khoản
        if (user.status !== 'ACTIVE') {
            throw new Error('Account_Inactive');
        }

        // 4. Sinh Access Token (Thời hạn sống 7 ngày)
        const accessToken = jwt.sign(
            { userId: user.id, role: user.role }, // Lưu thông tin cơ bản vào Payload
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        // Trả về token và thông tin cơ bản (không trả về password)
        return {
            access_token: accessToken,
            user_info: {
                id: user.id,
                email: user.email,
                phone: user.phone,
                role: user.role
            }
        };
    }
};

module.exports = authService;