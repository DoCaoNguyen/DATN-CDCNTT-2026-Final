const bcrypt = require('bcrypt');
const usersRepository = require('./users.repository');
const auditLogService = require('../../system/audit_log.service');
const { ensureWriteAccess, sanitizeUserInput, normalizeOptional, SYSTEM_ROLES, withTransaction, isSuperAdmin, writeAuditLog } = require('../_shared');
const { sendStaffOnboardingEmail } = require('../../../shared/services/email.service');
const { 
    normalizeUsername, 
    normalizeEmail, 
    normalizeVietnamPhone,
    normalizeFullName
} = require('../_shared/validation.util');
const pool = require('../../../config/db');

function deriveUserType(roleCodes) {
    if (!roleCodes || roleCodes.length === 0) return 'USER';
    if (roleCodes.includes('SUPER_ADMIN')) return 'SUPER_ADMIN';
    if (roleCodes.includes('ADMIN')) return 'ADMIN';
    if (roleCodes.includes('SUPPORT_STAFF')) return 'SUPPORT_STAFF';
    if (roleCodes.includes('MERCHANT_OWNER') || roleCodes.includes('MERCHANT_STAFF')) return 'MERCHANT_USER';
    return 'USER';
}

const usersService = {
    listUsers: async (query) => {
        let uType = query.user_type;
        if (uType) {
            if (typeof uType === 'string') {
                uType = uType.replace(/PERSONAL/gi, 'USER');
            } else if (Array.isArray(uType)) {
                uType = uType.map(t => t.toUpperCase() === 'PERSONAL' ? 'USER' : t);
            }
        }
        return usersRepository.listUsers({
            page: query.page,
            limit: query.limit,
            q: query.q || query.search,
            status: query.status,
            userType: uType
        });
    },

    getUserDetail: async (userId) => {
        const user = await usersRepository.findUserById(userId);
        if (!user) throw new Error('User_Not_Found');
        return user;
    },

    createWalletUser: async ({ actor, payload, actorId, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        const data = sanitizeUserInput(payload);

        const normalizedPhone = normalizeVietnamPhone(data.phone);
        const normalizedEmail = data.email && String(data.email).trim() !== '' ? normalizeEmail(data.email) : null;
        const normalizedFullName = normalizeFullName(data.full_name || data.fullName);

        const conflict = await usersRepository.checkUserConflict({
            username: data.username,
            email: normalizedEmail,
            phone: normalizedPhone
        });
        
        if (conflict) {
            const errList = [];
            if (conflict.phone === normalizedPhone) {
                errList.push({ field: 'phone', code: 'PHONE_ALREADY_EXISTS', message: 'Số điện thoại này đã được sử dụng.' });
            }
            if (conflict.email && conflict.email === normalizedEmail) {
                errList.push({ field: 'email', code: 'EMAIL_ALREADY_EXISTS', message: 'Email này đã được sử dụng.' });
            }
            
            // If conflict by username somehow
            if (errList.length === 0) {
                 errList.push({ field: 'username', code: 'USERNAME_ALREADY_EXISTS', message: 'Dữ liệu đã được sử dụng.' });
            }

            const err = new Error('RESOURCE_CONFLICT');
            err.errors = errList;
            throw err;
        }

        const crypto = require('crypto');
        const rawPassword = crypto.randomBytes(32).toString('hex');
        const passwordHash = await bcrypt.hash(rawPassword, 10);
        
        const derivedUserType = 'USER';
        const roleCodes = ['USER'];
        
        const isForceChangePassword = true;
        const temporaryPasswordExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

        const created = await withTransaction(async (client) => {
            const userId = await usersRepository.createUser(client, {
                fullName: normalizedFullName,
                username: data.username,
                email: normalizedEmail,
                phone: normalizedPhone,
                passwordHash,
                userType: derivedUserType,
                status: 'PENDING_VERIFY',
                isForceChangePassword,
                temporaryPasswordExpiresAt
            });

            const rolesAssigned = await usersRepository.replaceRolesByCodes(client, userId, roleCodes);
            if (!rolesAssigned) throw new Error('Role_Not_Found');

            const authRepository = require('../../auth/auth.repository');
            const walletId = await authRepository.createWallet(client, userId);

            return { userId, walletId };
        });

        await writeAuditLog({
            actorId: actorId || actor.userId || actor.id,
            action: 'admin.wallet_user_created',
            entityType: 'users',
            entityId: created.userId,
            newData: {
                user_type: derivedUserType,
                roles: roleCodes,
                status: 'PENDING_VERIFY',
                wallet_id: created.walletId
            },
            ipAddress,
            userAgent
        });

        const user = await usersService.getUserDetail(created.userId);
        
        if (process.env.SMS_PROVIDER === 'TWILIO_VERIFY') {
            const twilioVerifyService = require('../../../shared/services/twilio-verify.service');
            let verifyResult = { sms_sent: false };
            
            if (user.phone) {
                const verifyRes = await twilioVerifyService.sendVerification({ phone: user.phone });
                if (verifyRes.success) {
                    verifyResult.sms_sent = true;
                } else {
                    verifyResult.sms_sent = false;
                    verifyResult.error_code = 'USER_CREATED_OTP_SEND_FAILED';
                    verifyResult.can_resend = true;
                }
            }
            
            return { ...user, ...verifyResult };
        }

        const smsService = require('../../../shared/services/sms.service');
        let smsResult = { sms_sent: false };
        if (user.phone) {
            const content = `${rawPassword} la ma xac minh dang ky Baotrixemay cua ban\nCam on quy khach da su dung dich vu cua chung toi. Chuc quy khach mot ngay tot lanh!`;
            const sms = await smsService.sendSms({ phone: user.phone, content, requestId: `CREATE_WU_${created.userId}` });
            smsResult.sms_sent = sms.success;
        }

        return { ...user, ...smsResult };
    },

    createStaff: async ({ actor, payload, actorId, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        const data = sanitizeUserInput(payload);
        
        if (data.username) data.username = normalizeUsername(data.username);
        if (data.email) data.email = normalizeEmail(data.email);
        if (data.phone) {
            const normalizedPhone = normalizeVietnamPhone(data.phone);
            data.phone = normalizedPhone || null;
        } else {
            data.phone = null;
        }
        

        let roleCodes = [];
        if (data.roleCodes) {
            roleCodes = Array.isArray(data.roleCodes) ? data.roleCodes : [data.roleCodes];
        } else if (data.role_codes) {
            roleCodes = Array.isArray(data.role_codes) ? data.role_codes : [data.role_codes];
        } else {
            throw new Error('Role_Required');
        }
        
        let derivedUserType = 'SUPPORT_STAFF';
        if (roleCodes.includes('SUPER_ADMIN')) {
            derivedUserType = 'SUPER_ADMIN';
            if (!isSuperAdmin(actor)) throw new Error('Super_Admin_Required');
        } else if (roleCodes.includes('ADMIN')) {
            derivedUserType = 'ADMIN';
            if (!isSuperAdmin(actor)) throw new Error('Super_Admin_Required');
        }

        const crypto = require('crypto');
        if (!data.username && data.email) {
            let baseUsername = data.email.split('@')[0].replace(/[^a-zA-Z0-9]/g, '');
            let isUnique = false;
            let attempt = 0;
            let finalUsername = baseUsername;
            
            while (!isUnique && attempt < 5) {
                const conflict = await usersRepository.checkUserConflict({ username: finalUsername });
                if (!conflict) {
                    isUnique = true;
                } else {
                    attempt++;
                    finalUsername = `${baseUsername}${crypto.randomBytes(2).toString('hex')}`;
                }
            }
            if (!isUnique) throw new Error('Cannot_Generate_Unique_Username');
            data.username = finalUsername;
        }
        const conflict = await usersRepository.checkUserConflict({
            username: data.username,
            email: data.email,
            phone: data.phone || null
        });
        if (conflict) {
            const conflictErr = new Error();
            conflictErr.isConflict = true;
            if (data.username && conflict.username === data.username) {
                conflictErr.field = 'username';
                conflictErr.conflictCode = 'USERNAME_ALREADY_EXISTS';
                conflictErr.message = 'Tên đăng nhập đã được sử dụng.';
                throw conflictErr;
            }
            if (data.email && conflict.email && conflict.email.toLowerCase() === data.email) {
                conflictErr.field = 'email';
                conflictErr.conflictCode = 'EMAIL_ALREADY_EXISTS';
                conflictErr.message = 'Email đã được sử dụng.';
                throw conflictErr;
            }
            if (data.phone && conflict.phone === data.phone) {
                conflictErr.field = 'phone';
                conflictErr.conflictCode = 'PHONE_ALREADY_EXISTS';
                conflictErr.message = 'Số điện thoại đã được sử dụng.';
                throw conflictErr;
            }
            throw new Error('User_Conflict');
        }

        const cryptoStr = require('crypto');
        const rawPassword = cryptoStr.randomBytes(6).toString('hex');
        const passwordHash = await bcrypt.hash(rawPassword, 10);
        
        const isForceChangePassword = true;
        const temporaryPasswordExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

        const created = await withTransaction(async (client) => {
            const userId = await usersRepository.createUser(client, {
                fullName: data.fullName || data.full_name,
                username: data.username,
                email: data.email,
                phone: data.phone,
                passwordHash,
                userType: derivedUserType,
                status: 'ACTIVE',
                isForceChangePassword,
                temporaryPasswordExpiresAt
            });

            const rolesAssigned = await usersRepository.replaceRolesByCodes(client, userId, roleCodes);
            if (!rolesAssigned) throw new Error('Role_Not_Found');

            return { userId };
        });

        await writeAuditLog({
            actorId: actorId || actor.userId || actor.id,
            action: 'admin.staff_created',
            entityType: 'users',
            entityId: created.userId,
            newData: {
                user_type: derivedUserType,
                roles: roleCodes,
                status: data.status || 'ACTIVE'
            },
            ipAddress,
            userAgent
        });

        const user = await usersService.getUserDetail(created.userId);
        let emailSent = false;

        if (data.email) {
            emailSent = await sendStaffOnboardingEmail(data.email, {
                fullName: data.fullName || data.username,
                username: data.username,
                password: rawPassword
            });
        }

        const responseData = { ...user, email_sent: emailSent };
        
        return responseData;
    },

    updateUser: async ({ actor, targetUserId, payload, actorId, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        const oldUser = await usersRepository.findUserRawById(targetUserId);
        if (!oldUser) throw new Error('User_Not_Found');

        const updates = {};
        ['full_name', 'username', 'email', 'phone'].forEach(key => {
            if (Object.prototype.hasOwnProperty.call(payload, key)) {
                updates[key] = normalizeOptional(payload[key]);
            }
        });
        if (Object.prototype.hasOwnProperty.call(payload, 'is_kyc_verified')) {
            updates.is_kyc_verified = Boolean(payload.is_kyc_verified);
        }

        let roleCodes = null;
        if (payload.role_codes && Array.isArray(payload.role_codes)) {
            roleCodes = payload.role_codes;
        } else if (payload.role_code) {
            roleCodes = [payload.role_code];
        }

        const isChangingRole = roleCodes !== null;
        let newType = oldUser.user_type;

        if (isChangingRole) {
            newType = deriveUserType(roleCodes);
            updates.user_type = newType;
            
            const involvesSystemRole = SYSTEM_ROLES.includes(oldUser.user_type) || SYSTEM_ROLES.includes(newType);
            if (involvesSystemRole && !isSuperAdmin(actor)) {
                throw new Error('Super_Admin_Required');
            }
            if ((actorId || actor.userId || actor.id) === targetUserId) {
                throw new Error('Cannot_Change_Own_Role');
            }
        }

        if (Object.keys(updates).length === 0 && !isChangingRole) throw new Error('No_Update_Field');

        const conflict = await usersRepository.checkUserConflict({
            username: updates.username,
            email: updates.email,
            phone: updates.phone,
            excludeUserId: targetUserId
        });
        if (conflict) throw new Error('User_Conflict');

        const updated = await withTransaction(async (client) => {
            let updatedUser = oldUser;
            if (Object.keys(updates).length > 0) {
                updatedUser = await usersRepository.updateUser(client, targetUserId, updates);
            }
            
            if (isChangingRole) {
                const roleAssigned = await usersRepository.replaceRolesByCodes(client, targetUserId, roleCodes);
                if (!roleAssigned) throw new Error('Role_Not_Found');
                await usersRepository.incrementTokenVersion(client, targetUserId);
                updatedUser.token_version += 1;
            }
            return updatedUser;
        });

        await writeAuditLog({
            actorId: actorId || actor.userId || actor.id,
            action: 'admin.user_updated',
            entityType: 'users',
            entityId: targetUserId,
            oldData: { ...oldUser },
            newData: { ...updated, roles: isChangingRole ? roleCodes : oldUser.roles },
            ipAddress,
            userAgent
        });

        return usersService.getUserDetail(targetUserId);
    },

    lockUser: async ({ actor, targetUserId, reason, actorId, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        if ((actorId || actor.userId || actor.id) === targetUserId) throw new Error('Cannot_Lock_Self');

        const oldUser = await usersRepository.findUserRawById(targetUserId);
        if (!oldUser) throw new Error('User_Not_Found');
        if (SYSTEM_ROLES.includes(oldUser.user_type) && !isSuperAdmin(actor)) {
            throw new Error('Super_Admin_Required');
        }

        const updated = await usersRepository.lockUser(targetUserId);
        await writeAuditLog({
            actorId: actorId || actor.userId || actor.id,
            action: 'admin.user_locked',
            entityType: 'users',
            entityId: targetUserId,
            oldData: { status: oldUser.status, token_version: oldUser.token_version },
            newData: { status: updated.status, token_version: updated.token_version },
            reason,
            ipAddress,
            userAgent
        });

        return usersService.getUserDetail(targetUserId);
    },

    unlockUser: async ({ actor, targetUserId, reason, actorId, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        const oldUser = await usersRepository.findUserRawById(targetUserId);
        if (!oldUser) throw new Error('User_Not_Found');
        if (SYSTEM_ROLES.includes(oldUser.user_type) && !isSuperAdmin(actor)) {
            throw new Error('Super_Admin_Required');
        }

        const updated = await usersRepository.unlockUser(targetUserId);
        await writeAuditLog({
            actorId: actorId || actor.userId || actor.id,
            action: 'admin.user_unlocked',
            entityType: 'users',
            entityId: targetUserId,
            oldData: { status: oldUser.status, token_version: oldUser.token_version },
            newData: { status: updated.status, token_version: updated.token_version },
            reason,
            ipAddress,
            userAgent
        });

        return usersService.getUserDetail(targetUserId);
    },

    resetUserPassword: async ({ actor, targetUserId, reason, actorId, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        const user = await usersRepository.findUserRawById(targetUserId);
        if (!user) throw new Error('User_Not_Found');
        if (SYSTEM_ROLES.includes(user.user_type) && !isSuperAdmin(actor)) {
            throw new Error('Super_Admin_Required');
        }

        const temporaryPassword = Math.floor(100000 + Math.random() * 900000).toString();
        const passwordHash = await bcrypt.hash(temporaryPassword, 10);
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h

        await withTransaction(async client => {
            const authRepository = require('../../auth/auth.repository');
            await authRepository.forceResetPassword(client, targetUserId, passwordHash, expiresAt);
            await authRepository.revokeAllUserRefreshTokens(client, targetUserId, ipAddress);
        });

        await writeAuditLog({
            actorType: 'USER',
            actorId: actorId || actor.userId || actor.id,
            action: 'admin.users.reset_password',
            entityType: 'users',
            entityId: targetUserId,
            metadata: { reason },
            ipAddress,
            userAgent
        });

        const userDetail = await usersService.getUserDetail(targetUserId);
        const smsService = require('../../../shared/services/sms.service');
        let smsResult = { sms_sent: false };

        if (userDetail.user_type === 'USER') {
            if (userDetail.phone) {
                const content = `${temporaryPassword} la ma xac minh dang ky Baotrixemay cua ban\nCam on quy khach da su dung dich vu cua chung toi. Chuc quy khach mot ngay tot lanh!`;
                const sms = await smsService.sendSms({ phone: userDetail.phone, content, requestId: `RESET_PWD_${targetUserId}` });
                smsResult.sms_sent = sms.success;
                if (sms.mocked !== undefined) smsResult.sms_mocked = sms.mocked;
                if (sms.provider) smsResult.sms_provider = sms.provider;
                if (sms.error_code) smsResult.sms_error_code = sms.error_code;
                if (sms.error_message) smsResult.sms_error_message = sms.error_message;
            } else {
                smsResult.sms_skipped_reason = 'NO_PHONE';
            }
        } else {
            smsResult.sms_skipped_reason = 'NOT_A_WALLET_USER';
        }

        return { ...userDetail, temporary_password: temporaryPassword, ...smsResult };
    },

    resendOnboardingEmail: async ({ actor, targetUserId, actorId, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        const user = await usersRepository.findUserRawById(targetUserId);
        if (!user) throw new Error('User_Not_Found');
        
        if (!user.email) {
            throw new Error('EMAIL_REQUIRED');
        }

        const cryptoStr = require('crypto');
        const rawPassword = cryptoStr.randomBytes(6).toString('hex');
        const passwordHash = await bcrypt.hash(rawPassword, 10);
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

        await withTransaction(async (client) => {
            const authRepository = require('../../auth/auth.repository');
            await authRepository.forceResetPassword(client, targetUserId, passwordHash, expiresAt);
        });

        await writeAuditLog({
            actorId: actorId || actor.userId || actor.id,
            action: 'admin.users.resend_onboarding_email',
            entityType: 'users',
            entityId: targetUserId,
            ipAddress,
            userAgent
        });

        let emailSent = false;
        
        if (user.roles && user.roles.includes('MERCHANT_OWNER')) {
            const mRes = await pool.query(`
                SELECT m.merchant_name 
                FROM merchants m
                WHERE m.user_id = $1
            `, [targetUserId]);
            const merchantName = mRes.rows[0]?.merchant_name || 'Đối tác';
            
            const emailService = require('../../../shared/services/email.service');
            emailSent = await emailService.sendOnboardingEmail(user.email, {
                merchantName,
                username: user.username,
                password: rawPassword
            });
        } else {
            const { sendStaffOnboardingEmail } = require('../../../shared/services/email.service');
            emailSent = await sendStaffOnboardingEmail(user.email, {
                fullName: user.full_name || user.username,
                username: user.username,
                password: rawPassword
            });
        }

        if (!emailSent) {
            throw new Error('EMAIL_SEND_FAILED');
        }

        return { email_sent: true };
    },

    getUserAuditLogs: async ({ userId, query }) => {
        await usersService.getUserDetail(userId);
        return auditLogService.listForUser({ userId, query });
    },

    getUserWallet: async (userId) => {
        const user = await usersService.getUserDetail(userId);
        if (!user.wallet) throw new Error('Wallet_Not_Found');
        return user.wallet;
    }
};

module.exports = usersService;
