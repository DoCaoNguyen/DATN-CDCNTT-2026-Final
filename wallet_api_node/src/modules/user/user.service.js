const userRepository = require('./user.repository');
const otpRepository = require('../system/otp.repository');
const bcrypt = require('bcrypt');
const mailer = require('../../utils/mailer');

const userService = {
    searchUsers: async (searchQuery, currentUserId) => {
        const cleanQuery = searchQuery.trim();
        const users = await userRepository.searchUsers(cleanQuery, currentUserId);
        return users;
    },

    checkContacts: async (phones, currentUserId) => {
        return await userRepository.getUsersByPhones(phones, currentUserId);
    },

    getUserProfile: async (userId) => {
        const user = await userRepository.getUserProfile(userId);
        return user;
    },


    requestEmailOtp: async (userId, email) => {
        const existingUser = await userRepository.getUserByEmail(email);
        if (existingUser && existingUser.id !== userId) {
            throw new Error('Email này đã được sử dụng bởi một tài khoản khác.');
        }

        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        const otpHash = await bcrypt.hash(otpCode, 10);
        await otpRepository.upsertOtp(null, email, otpHash, 'VERIFY_EMAIL');
        await mailer.sendOtpEmail(email, otpCode);
    },

    verifyEmailOtp: async (userId, email, otpCode) => {
        const otpRecord = await otpRepository.findOtp({ email: email, purpose: 'VERIFY_EMAIL' });
        if (!otpRecord) {
            throw new Error('Bạn chưa yêu cầu mã OTP');
        }
        const isValid = await bcrypt.compare(otpCode, otpRecord.otp_hash);
        if (!isValid) {
            throw new Error('Mã OTP không chính xác');
        }
        if (new Date(otpRecord.expired_at) < new Date()) {
            throw new Error('Mã OTP đã hết hạn');
        }
        await userRepository.updateUserEmail(userId, email);
        
        await otpRepository.deleteOtp(email);
    }

};

module.exports = userService;