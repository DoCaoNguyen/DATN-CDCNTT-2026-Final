const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../../config/db'); 
const { sendSMS } = require('../../utils/sms');
const authRepository = require('./auth.repository');
const walletRepository = require('../wallet/wallet.repository');
const otpRepository = require('../system/otp.repository');

const authService = {
    requestOtp: async (email, phone) => {
    
        const userExist = await authRepository.checkExists(email, phone);
        if (userExist) throw new Error('Email_Phone_Exists');

        const record = await otpRepository.findByPhone(phone);
        if (record && record.locked_until && new Date(record.locked_until) > new Date()) {
            throw new Error('Account_Locked');
        }
       
        const otpCode = Math.floor(1000 + Math.random() * 9000).toString();
        await otpRepository.upsertOtp(phone, email, otpCode);

        await sendSMS(phone, otpCode);
        return true;
    },

    verifyOtp: async (phone, otp) => {

        const record = await otpRepository.findByPhone(phone);
        if (!record) throw new Error('OTP_Not_Found');

        if (record.locked_until && new Date(record.locked_until) > new Date()) {
            throw new Error('Account_Locked');
        }

        if (new Date() > new Date(record.expired_at)) {
            throw new Error('OTP_Expired');
        }

        
        if (record.otp_code !== otp) {
            const newAttempts = record.failed_attempts + 1;
            
            
            if (newAttempts >= 5) {
                await otpRepository.lockAccount(phone, newAttempts, 30);
                throw new Error('Account_Locked_Now');
            } else {
                
                await otpRepository.updateAttempts(phone, newAttempts);
                
                const remaining = 5 - newAttempts;
                const err = new Error('OTP_Invalid');
                err.remainingAttempts = remaining;
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