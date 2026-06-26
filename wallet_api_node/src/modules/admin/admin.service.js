const bcrypt = require('bcrypt');
const adminRepository = require('./admin.repository');
const walletRepository = require('../wallet/wallet.repository');
const authService = require('../auth/auth.service');
const walletService = require('../wallet/wallet.service');
const auditLogService = require('../system/audit_log.service');

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



    // ==========================================
    // DASHBOARD SERVICE
    // ==========================================
    getDashboardKPIs: async () => {
        return adminRepository.getDashboardStats();
    }
};

module.exports = adminService;
