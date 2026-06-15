const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const pool = require('../../config/db');
const { sendOTP, verifyOTP } = require('../../utils/sms');
const authRepository = require('./auth.repository');
const walletRepository = require('../wallet/wallet.repository');
const otpRepository = require('../system/otp.repository');

const ACCESS_TOKEN_TTL_SECONDS = Number(process.env.JWT_ACCESS_TTL_SECONDS || process.env.JWT_EXPIRES_SECONDS || 15 * 60);
const REFRESH_TOKEN_TTL_DAYS = Number(process.env.JWT_REFRESH_TTL_DAYS || process.env.REFRESH_TOKEN_DAYS || 30);
const REMEMBER_REFRESH_TOKEN_TTL_DAYS = Number(process.env.JWT_REMEMBER_REFRESH_TTL_DAYS || process.env.REFRESH_TOKEN_REMEMBER_DAYS || 60);
const MAX_LOGIN_ATTEMPTS = Number(process.env.MAX_LOGIN_ATTEMPTS || process.env.MAX_FAILED_LOGIN || 5);
const LOCK_DURATION_MINUTES = Number(process.env.LOCK_DURATION_MINUTES || process.env.LOGIN_LOCK_MINUTES || 30);
const PASSWORD_RESET_TTL_MINUTES = Number(process.env.PASSWORD_RESET_TTL_MINUTES || 15);

function hashOpaqueToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
}

function generateOpaqueToken() {
    return crypto.randomBytes(48).toString('base64url');
}

function getActorType(user) {
    if (!user) return 'SYSTEM';
    if (['ADMIN', 'SUPER_ADMIN', 'SUPPORT_STAFF'].includes(user.user_type)) {
        return 'ADMIN';
    }
    if (user.user_type === 'MERCHANT_USER') {
        return 'MERCHANT';
    }
    return 'USER';
}

function addDays(date, days) {
    const copy = new Date(date);
    copy.setDate(copy.getDate() + days);
    return copy;
}

function addMinutes(date, minutes) {
    const copy = new Date(date);
    copy.setMinutes(copy.getMinutes() + minutes);
    return copy;
}

function validatePassword(password) {
    if (!password || password.length < 8) {
        throw new Error('Password_Policy_Invalid');
    }
}

function getJwtSecret() {
    if (!process.env.JWT_SECRET) {
        throw new Error('Auth_Config_Missing');
    }
    return process.env.JWT_SECRET;
}

const authService = {
    requestOtp: async (emailOrPhone, phoneOpt) => {
        let phone = phoneOpt;
        let email = emailOrPhone;
        if (!phoneOpt) {
            phone = emailOrPhone;
            email = null;
        }

        const userExist = await authRepository.checkExists(email, phone);
        if (userExist) throw new Error('Email_Phone_Exists');

        const record = await otpRepository.findByPhone(phone);
        if (record && record.locked_until && new Date(record.locked_until) > new Date()) {
            throw new Error('Account_Locked');
        }

        await otpRepository.upsertOtp(phone, email, 'TW_VFY');

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

        const twilioResult = await verifyOTP(phone, otp);

        if (!twilioResult.valid) {
            const newAttempts = record.failed_attempts + 1;

            if (newAttempts >= 5) {
                await otpRepository.lockAccount(phone, newAttempts, 30);
                throw new Error('Account_Locked_Now');
            }

            await otpRepository.updateAttempts(phone, newAttempts);
            const err = new Error('OTP_Invalid');
            err.remainingAttempts = 5 - newAttempts;
            throw err;
        }

        const registerToken = jwt.sign(
            { email: record.email, phone: phone },
            getJwtSecret(),
            { expiresIn: '15m' }
        );

        await otpRepository.deleteByPhone(phone);

        return registerToken;
    },

    registerUserAndWallet: async (registerToken, password) => {
        const decoded = jwt.verify(registerToken, getJwtSecret());
        const { email, phone } = decoded;

        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const saltRounds = 10;
            const passwordHash = await bcrypt.hash(password, saltRounds);

            const newUserId = await authRepository.create(client, email, phone, passwordHash);
            await authRepository.assignRoleByCode(client, newUserId, 'USER');
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

    register: async ({ fullName, username, email, phone, password, confirmPassword, ipAddress, userAgent }) => {
        if (!fullName || !phone || !password) throw new Error('Validation_Error');
        if (confirmPassword !== undefined && password !== confirmPassword) throw new Error('Password_Confirm_Not_Match');
        validatePassword(password);

        const userExist = await authRepository.checkExists(email, phone);
        if (userExist) throw new Error('Email_Phone_Exists');

        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const passwordHash = await bcrypt.hash(password, 10);
            const newUserId = await authRepository.create(client, email || null, phone, passwordHash, fullName, username || null);
            await authRepository.assignRoleByCode(client, newUserId, 'USER');
            await walletRepository.create(client, newUserId);
            await client.query('COMMIT');

            await authRepository.writeAuthAuditLog({
                actorType: 'USER',
                actorId: newUserId,
                action: 'auth.register',
                metadata: { phone, email: email || null },
                ipAddress,
                userAgent
            });

            return { user_id: newUserId };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    buildUserSessionContext: async (user) => {
        const { roles, permissions } = await authRepository.getRolesAndPermissions(user.id);
        const fallbackRoles = roles.length > 0 ? roles : [user.user_type || 'USER'];
        const merchantContext = await authRepository.getMerchantContext(user.id);

        return {
            user: {
                id: user.id,
                user_type: user.user_type,
                full_name: user.full_name,
                username: user.username,
                email: user.email,
                phone: user.phone,
                status: user.status,
                is_kyc_verified: user.is_kyc_verified,
                last_login_at: user.last_login_at
            },
            roles: fallbackRoles,
            permissions,
            merchant_context: merchantContext ? {
                merchant_id: merchantContext.merchant_id,
                role_code: merchantContext.role_code,
                is_owner: merchantContext.is_owner,
                merchant_status: merchantContext.merchant_status
            } : null
        };
    },

    signAccessToken: (context, tokenVersion) => {
        const payload = {
            sub: context.user.id,
            userId: context.user.id,
            user_type: context.user.user_type,
            roles: context.roles,
            permissions: context.permissions,
            merchant_context: context.merchant_context,
            token_type: 'ACCESS',
            tokenVersion
        };

        return jwt.sign(payload, getJwtSecret(), { expiresIn: ACCESS_TOKEN_TTL_SECONDS });
    },

    issueTokenPair: async ({ user, context, rememberMe, ipAddress, userAgent }) => {
        const accessToken = authService.signAccessToken(context, user.token_version);
        const refreshToken = generateOpaqueToken();
        const refreshTokenHash = hashOpaqueToken(refreshToken);
        const refreshTtlDays = rememberMe ? REMEMBER_REFRESH_TOKEN_TTL_DAYS : REFRESH_TOKEN_TTL_DAYS;
        const refreshRecord = await authRepository.createRefreshToken({
            userId: user.id,
            tokenHash: refreshTokenHash,
            expiresAt: addDays(new Date(), refreshTtlDays),
            ipAddress,
            userAgent
        });

        return {
            access_token: accessToken,
            refresh_token: refreshToken,
            token_type: 'Bearer',
            expires_in: ACCESS_TOKEN_TTL_SECONDS,
            refresh_expires_at: refreshRecord.expires_at
        };
    },

    login: async ({ loginId, password, rememberMe = false, ipAddress, userAgent }) => {
        const user = await authRepository.findByLoginId(loginId);
        if (!user) {
            await authRepository.recordLoginAttempt({
                loginId,
                success: false,
                failureReason: 'USER_NOT_FOUND',
                ipAddress,
                userAgent
            });
            throw new Error('Invalid_Credentials');
        }

        if (user.locked_until) {
            if (new Date(user.locked_until) > new Date()) {
                await authRepository.recordLoginAttempt({
                    loginId,
                    userId: user.id,
                    success: false,
                    failureReason: 'ACCOUNT_LOCKED',
                    ipAddress,
                    userAgent
                });
                throw new Error('Account_Locked');
            }
            await authRepository.resetFailedLogin(user.id);
            user.failed_login_attempts = 0;
        }

        if (['LOCKED', 'BLOCKED', 'INACTIVE'].includes(user.status)) {
            await authRepository.recordLoginAttempt({
                loginId,
                userId: user.id,
                success: false,
                failureReason: `ACCOUNT_${user.status}`,
                ipAddress,
                userAgent
            });
            throw new Error('Account_Inactive');
        }

        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            const currentAttempts = user.failed_login_attempts || 0;
            const newAttempts = currentAttempts + 1;
            const shouldLock = newAttempts >= MAX_LOGIN_ATTEMPTS;

            await authRepository.updateFailedLogin(user.id, newAttempts, shouldLock ? LOCK_DURATION_MINUTES : 0);
            await authRepository.recordLoginAttempt({
                loginId,
                userId: user.id,
                success: false,
                failureReason: shouldLock ? 'ACCOUNT_LOCKED_BY_FAILED_LOGIN' : 'INVALID_PASSWORD',
                ipAddress,
                userAgent
            });

            if (shouldLock) {
                await authRepository.writeAuthAuditLog({
                    actorType: getActorType(user),
                    actorId: user.id,
                    action: 'auth.account_locked',
                    metadata: { reason: 'FAILED_LOGIN_LIMIT' },
                    ipAddress,
                    userAgent
                });
                throw new Error('Account_Locked_Now');
            }

            const err = new Error('Invalid_Credentials');
            err.remainingAttempts = MAX_LOGIN_ATTEMPTS - newAttempts;
            throw err;
        }

        await authRepository.markLoginSuccess(user.id);
        const latestUser = await authRepository.findUserContextById(user.id);
        const context = await authService.buildUserSessionContext(latestUser);
        const tokenPair = await authService.issueTokenPair({
            user: latestUser,
            context,
            rememberMe,
            ipAddress,
            userAgent
        });

        await authRepository.recordLoginAttempt({
            loginId,
            userId: user.id,
            success: true,
            ipAddress,
            userAgent
        });
        await authRepository.writeAuthAuditLog({
            actorType: getActorType(latestUser),
            actorId: latestUser.id,
            action: 'auth.login_success',
            metadata: { roles: context.roles },
            ipAddress,
            userAgent
        });

        return {
            ...tokenPair,
            ...context,
            user_info: context.user
        };
    },

    refreshToken: async ({ refreshToken, ipAddress, userAgent }) => {
        const tokenHash = hashOpaqueToken(refreshToken);
        const storedToken = await authRepository.findRefreshTokenByHash(tokenHash);

        if (!storedToken) {
            throw new Error('Refresh_Token_Invalid');
        }

        if (storedToken.revoked_at) {
            await authRepository.markRefreshTokenReused(storedToken.id);
            await authRepository.revokeRefreshTokenFamily(storedToken.token_family_id, ipAddress);
            await authRepository.writeSecurityLog({
                event: 'auth.refresh_token_reuse_detected',
                message: 'Refresh token reuse detected',
                context: { token_family_id: storedToken.token_family_id },
                entityId: storedToken.user_id
            });
            throw new Error('Refresh_Token_Invalid');
        }

        if (new Date(storedToken.expires_at) <= new Date() || storedToken.user_status !== 'ACTIVE') {
            throw new Error('Refresh_Token_Invalid');
        }

        const user = await authRepository.findUserContextById(storedToken.user_id);
        if (!user || user.status !== 'ACTIVE') {
            throw new Error('Refresh_Token_Invalid');
        }

        await authRepository.revokeRefreshToken(storedToken.id, ipAddress);

        const context = await authService.buildUserSessionContext(user);
        const accessToken = authService.signAccessToken(context, user.token_version);
        const newRefreshToken = generateOpaqueToken();
        const newRefreshTokenHash = hashOpaqueToken(newRefreshToken);
        const refreshRecord = await authRepository.createRefreshToken({
            userId: user.id,
            tokenHash: newRefreshTokenHash,
            tokenFamilyId: storedToken.token_family_id,
            expiresAt: addDays(new Date(), REFRESH_TOKEN_TTL_DAYS),
            ipAddress,
            userAgent
        });

        return {
            access_token: accessToken,
            refresh_token: newRefreshToken,
            token_type: 'Bearer',
            expires_in: ACCESS_TOKEN_TTL_SECONDS,
            refresh_expires_at: refreshRecord.expires_at,
            ...context
        };
    },

    logout: async ({ userId, refreshToken, ipAddress, userAgent }) => {
        if (!refreshToken) throw new Error('Refresh_Token_Required');

        const tokenHash = hashOpaqueToken(refreshToken);
        const revoked = await authRepository.revokeRefreshTokenByHash(userId, tokenHash, ipAddress);
        if (!revoked) throw new Error('Refresh_Token_Invalid');

        const user = await authRepository.findUserContextById(userId);
        await authRepository.writeAuthAuditLog({
            actorType: getActorType(user),
            actorId: userId,
            action: 'auth.logout',
            ipAddress,
            userAgent
        });

        return true;
    },

    revokeToken: async ({ userId, refreshToken, revokeAll = false, ipAddress }) => {
        if (revokeAll) {
            await authRepository.revokeAllRefreshTokensForUser(userId, ipAddress);
            return true;
        }

        if (!refreshToken) throw new Error('Refresh_Token_Required');

        const tokenHash = hashOpaqueToken(refreshToken);
        const revoked = await authRepository.revokeRefreshTokenByHash(userId, tokenHash, ipAddress);
        if (!revoked) throw new Error('Refresh_Token_Invalid');

        return true;
    },

    getMe: async (userId) => {
        const user = await authRepository.findUserContextById(userId);
        if (!user) throw new Error('User_Not_Found');
        return authService.buildUserSessionContext(user);
    },

    forgotPassword: async ({ loginId, ipAddress, userAgent }) => {
        const user = await authRepository.findByLoginId(loginId);
        if (!user) {
            return { reset_token: null, expires_at: null };
        }

        await authRepository.revokeUnusedPasswordResets(user.id);
        const resetToken = generateOpaqueToken();
        const resetRecord = await authRepository.createPasswordReset({
            userId: user.id,
            tokenHash: hashOpaqueToken(resetToken),
            expiresAt: addMinutes(new Date(), PASSWORD_RESET_TTL_MINUTES),
            ipAddress,
            userAgent
        });

        await authRepository.writeAuthAuditLog({
            actorType: getActorType(user),
            actorId: user.id,
            action: 'auth.password_reset_requested',
            ipAddress,
            userAgent
        });

        return {
            reset_token: resetToken,
            expires_at: resetRecord.expires_at
        };
    },

    resetPassword: async ({ resetToken, newPassword, confirmNewPassword, ipAddress, userAgent }) => {
        if (newPassword !== confirmNewPassword) throw new Error('Password_Confirm_Not_Match');
        validatePassword(newPassword);

        const resetRecord = await authRepository.findPasswordResetByHash(hashOpaqueToken(resetToken));
        if (!resetRecord || resetRecord.used_at || new Date(resetRecord.expires_at) <= new Date() || resetRecord.user_status !== 'ACTIVE') {
            throw new Error('Password_Reset_Token_Invalid');
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            await authRepository.updatePasswordHash(client, resetRecord.user_id, await bcrypt.hash(newPassword, 10));
            await authRepository.markPasswordResetUsed(client, resetRecord.id);
            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }

        await authRepository.revokeAllRefreshTokensForUser(resetRecord.user_id, ipAddress);
        await authRepository.writeAuthAuditLog({
            actorType: 'USER',
            actorId: resetRecord.user_id,
            action: 'auth.password_reset_success',
            ipAddress,
            userAgent
        });

        return true;
    },

    changePassword: async ({ userId, currentPassword, newPassword, confirmNewPassword, revokeOtherSessions = true, ipAddress, userAgent }) => {
        if (newPassword !== confirmNewPassword) throw new Error('Password_Confirm_Not_Match');
        validatePassword(newPassword);

        const contextUser = await authRepository.findUserContextById(userId);
        if (!contextUser) throw new Error('User_Not_Found');

        const user = await authRepository.findByLoginId(contextUser.email || contextUser.phone || contextUser.username);
        const currentMatch = await bcrypt.compare(currentPassword, user.password_hash);
        if (!currentMatch) throw new Error('Invalid_Current_Password');

        const samePassword = await bcrypt.compare(newPassword, user.password_hash);
        if (samePassword) throw new Error('Password_Same_As_Current');

        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            await authRepository.updatePasswordHash(client, userId, await bcrypt.hash(newPassword, 10));
            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }

        if (revokeOtherSessions) {
            await authRepository.revokeAllRefreshTokensForUser(userId, ipAddress);
        }

        await authRepository.writeAuthAuditLog({
            actorType: getActorType(contextUser),
            actorId: userId,
            action: 'auth.password_change',
            metadata: { revoke_other_sessions: revokeOtherSessions },
            ipAddress,
            userAgent
        });

        return true;
    }
};

module.exports = authService;
