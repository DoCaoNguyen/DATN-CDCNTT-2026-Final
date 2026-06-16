const bcrypt = require('bcrypt');
const adminRepository = require('./admin.repository');
const walletRepository = require('../wallet/wallet.repository');

const SYSTEM_ROLES = ['ADMIN', 'SUPER_ADMIN', 'SUPPORT_STAFF'];
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function normalizeOptional(value) {
    if (value === undefined || value === null) return null;
    const trimmed = String(value).trim();
    return trimmed || null;
}

function isSuperAdmin(actor) {
    return (actor.roles || []).includes('SUPER_ADMIN');
}

function hasWriteAccess(actor) {
    const roles = actor.roles || [];
    return roles.includes('ADMIN') || roles.includes('SUPER_ADMIN');
}

function ensureWriteAccess(actor) {
    if (!hasWriteAccess(actor)) {
        throw new Error('Admin_Write_Forbidden');
    }
}

function sanitizeUserInput(payload = {}) {
    return {
        fullName: normalizeOptional(payload.full_name),
        username: normalizeOptional(payload.username),
        email: normalizeOptional(payload.email),
        phone: normalizeOptional(payload.phone),
        password: payload.password,
        userType: 'USER',
        status: 'ACTIVE',
        roleCode: 'USER',
        createWallet: true
    };
}

function ensureUuid(value, errorCode = 'Invalid_Id') {
    if (!UUID_REGEX.test(String(value || ''))) {
        throw new Error(errorCode);
    }
}

const adminService = {
    listUsers: async (query) => {
        return adminRepository.listUsers({
            page: query.page,
            limit: query.limit,
            q: query.q || query.search,
            status: query.status,
            userType: query.user_type
        });
    },

    getUserDetail: async (userId) => {
        ensureUuid(userId, 'Invalid_User_Id');
        const user = await adminRepository.findUserById(userId);
        if (!user) throw new Error('User_Not_Found');
        return user;
    },

    createUser: async ({ actor, payload, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        const data = sanitizeUserInput(payload);

        if (!data.fullName || !data.password || (!data.email && !data.phone && !data.username)) {
            throw new Error('Validation_Error');
        }
        if (data.password.length < 8) throw new Error('Password_Policy_Invalid');

        const conflict = await adminRepository.checkUserConflict({
            username: data.username,
            email: data.email,
            phone: data.phone
        });
        if (conflict) throw new Error('User_Conflict');

        const passwordHash = await bcrypt.hash(data.password, 10);

        const created = await adminRepository.withTransaction(async (client) => {
            const userId = await adminRepository.createUser(client, {
                fullName: data.fullName,
                username: data.username,
                email: data.email,
                phone: data.phone,
                passwordHash,
                userType: data.userType,
                status: data.status
            });

            const roleAssigned = await adminRepository.assignRoleByCode(client, userId, data.roleCode);
            if (!roleAssigned) throw new Error('Role_Not_Found');

            let walletId = null;
            if (data.createWallet) {
                walletId = await walletRepository.create(client, userId);
            }

            return { userId, walletId };
        });

        await adminRepository.writeAuditLog({
            actorId: actor.userId || actor.id,
            action: 'admin.user_created',
            entityType: 'users',
            entityId: created.userId,
            newData: {
                user_type: data.userType,
                status: data.status,
                role_code: data.roleCode,
                wallet_id: created.walletId
            },
            ipAddress,
            userAgent
        });

        return adminService.getUserDetail(created.userId);
    },

    updateUser: async ({ actor, userId, payload, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        ensureUuid(userId, 'Invalid_User_Id');
        const oldUser = await adminRepository.findUserRawById(userId);
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

        if (Object.keys(updates).length === 0) throw new Error('No_Update_Field');

        const conflict = await adminRepository.checkUserConflict({
            username: updates.username,
            email: updates.email,
            phone: updates.phone,
            excludeUserId: userId
        });
        if (conflict) throw new Error('User_Conflict');

        const updated = await adminRepository.updateUser(userId, updates);

        await adminRepository.writeAuditLog({
            actorId: actor.userId || actor.id,
            action: 'admin.user_updated',
            entityType: 'users',
            entityId: userId,
            oldData: oldUser,
            newData: updated,
            ipAddress,
            userAgent
        });

        return adminService.getUserDetail(userId);
    },

    lockUser: async ({ actor, userId, reason, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        ensureUuid(userId, 'Invalid_User_Id');
        if (!normalizeOptional(reason)) throw new Error('Reason_Required');
        if ((actor.userId || actor.id) === userId) throw new Error('Cannot_Lock_Self');

        const oldUser = await adminRepository.findUserRawById(userId);
        if (!oldUser) throw new Error('User_Not_Found');
        if (SYSTEM_ROLES.includes(oldUser.user_type) && !isSuperAdmin(actor)) {
            throw new Error('Super_Admin_Required');
        }

        const updated = await adminRepository.lockUser(userId);
        await adminRepository.writeAuditLog({
            actorId: actor.userId || actor.id,
            action: 'admin.user_locked',
            entityType: 'users',
            entityId: userId,
            oldData: { status: oldUser.status, token_version: oldUser.token_version },
            newData: { status: updated.status, token_version: updated.token_version },
            reason,
            ipAddress,
            userAgent
        });

        return adminService.getUserDetail(userId);
    },

    unlockUser: async ({ actor, userId, reason, ipAddress, userAgent }) => {
        ensureWriteAccess(actor);
        ensureUuid(userId, 'Invalid_User_Id');
        if (!normalizeOptional(reason)) throw new Error('Reason_Required');
        const oldUser = await adminRepository.findUserRawById(userId);
        if (!oldUser) throw new Error('User_Not_Found');
        if (SYSTEM_ROLES.includes(oldUser.user_type) && !isSuperAdmin(actor)) {
            throw new Error('Super_Admin_Required');
        }

        const updated = await adminRepository.unlockUser(userId);
        await adminRepository.writeAuditLog({
            actorId: actor.userId || actor.id,
            action: 'admin.user_unlocked',
            entityType: 'users',
            entityId: userId,
            oldData: { status: oldUser.status, token_version: oldUser.token_version },
            newData: { status: updated.status, token_version: updated.token_version },
            reason,
            ipAddress,
            userAgent
        });

        return adminService.getUserDetail(userId);
    },

    listWallets: async (query) => {
        return adminRepository.listWallets({
            page: query.page,
            limit: query.limit,
            q: query.q || query.search,
            status: query.status,
            userId: query.user_id
        });
    },

    getWalletDetail: async (walletId) => {
        ensureUuid(walletId, 'Invalid_Wallet_Id');
        const wallet = await adminRepository.findWalletById(walletId);
        if (!wallet) throw new Error('Wallet_Not_Found');
        return wallet;
    },

    getWalletSummary: async (walletId) => {
        const wallet = await adminService.getWalletDetail(walletId);
        return {
            wallet_id: wallet.id,
            wallet_no: wallet.wallet_no,
            currency: wallet.currency,
            status: wallet.status,
            owner: wallet.user,
            available_balance: wallet.available_balance,
            locked_balance: wallet.locked_balance,
            total_balance: wallet.total_balance,
            balance_updated_at: wallet.balance_updated_at
        };
    },

    getUserWallet: async (userId) => {
        const user = await adminService.getUserDetail(userId);
        if (!user.wallet) throw new Error('Wallet_Not_Found');
        return user.wallet;
    },

    getWalletLedger: async ({ walletId, query }) => {
        await adminService.getWalletDetail(walletId);
        return adminRepository.listWalletLedger({
            walletId,
            page: query.page,
            limit: query.limit
        });
    }
};

module.exports = adminService;
