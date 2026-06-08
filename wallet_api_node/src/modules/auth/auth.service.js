const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../../config/db');
const { sendOTP, verifyOTP } = require('../../utils/sms');
const authRepository = require('./auth.repository');
const walletRepository = require('../wallet/wallet.repository');
const otpRepository = require('../system/otp.repository');

const authService = {
    // Sửa lại để phòng trường hợp user chỉ truyền phone vào hàm (như trong controller họ đang sửa)
    requestOtp: async (emailOrPhone, phoneOpt) => {
        // Tự động phân tích tham số nếu chỉ truyền 1 tham số (phone)
        let phone = phoneOpt;
        let email = emailOrPhone;
        if (!phoneOpt) {
            phone = emailOrPhone; // Nếu truyền 1 tham số thì đó là phone
            email = null; // Set thẳng email bằng null theo yêu cầu
        }

        const userExist = await authRepository.checkExists(email, phone);
        if (userExist) throw new Error('Email_Phone_Exists');

        const record = await otpRepository.findByPhone(phone);
        if (record && record.locked_until && new Date(record.locked_until) > new Date()) {
            throw new Error('Account_Locked');
        }

        // Lưu tạm vào DB với OTP là 'TW_VFY' (Twilio Verify)
        await otpRepository.upsertOtp(phone, email, 'TW_VFY');

        // Gửi bằng Twilio Verify Service do user cung cấp
        const result = await sendOTP(phone);
        if (!result.success) {
            throw new Error(`OTP_Send_Failed: ${result.message}`);
        }

        return true;
    },


    verifyOtp: async (phone, otp) => {

        const record = await otpRepository.findByPhone(phone);
        if (!record) throw new Error('OTP_Not_Found');

        if (record.locked_until && new Date(record.locked_until) > new Date()) {
            throw new Error('Account_Locked');
        }

        // Sử dụng Twilio Verify do user cung cấp
        const twilioResult = await verifyOTP(phone, otp);

        if (!twilioResult.valid) {
            const newAttempts = record.failed_attempts + 1;
            
            if (newAttempts >= 5) {
                await otpRepository.lockAccount(phone, newAttempts, 30);
                throw new Error('Account_Locked_Now');
            } else {
                await otpRepository.updateAttempts(phone, newAttempts);
                const err = new Error('OTP_Invalid');
                err.remainingAttempts = 5 - newAttempts;
                throw err; 
            }
        }

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

            const newUserId = await authRepository.create(client, email, phone, passwordHash);
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
        const user = await authRepository.findByEmailOrPhone(identifier);
        if (!user) throw new Error('Invalid_Credentials');


        if (user.locked_until) {
            if (new Date(user.locked_until) > new Date()) {
                throw new Error('Account_Locked');
            } else {
                user.failed_login_attempts = 0;
                await authRepository.resetFailedLogin(user.id);
            }
        }

        const isMatch = await bcrypt.compare(password, user.password_hash);


        if (!isMatch) {
            const newAttempts = (user.failed_login_attempts || 0) + 1;


            if (newAttempts >= 5) {
                await authRepository.updateFailedLogin(user.id, newAttempts, 30);
                throw new Error('Account_Locked_Now');
            }

            else {
                await authRepository.updateFailedLogin(user.id, newAttempts, 0);
                const err = new Error('Invalid_Credentials');
                err.remainingAttempts = 5 - newAttempts;
                throw err;
            }
        }


        if (user.status !== 'ACTIVE') throw new Error('Account_Inactive');


        if (user.failed_login_attempts > 0 || user.locked_until) {
            await authRepository.resetFailedLogin(user.id);
        }


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