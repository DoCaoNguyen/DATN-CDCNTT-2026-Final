/**
 * Admin Shared Validators
 * 
 * Di chuyển từ admin.service.js:
 * - normalizeOptional(value)
 * - isSuperAdmin(actor)
 * - hasWriteAccess(actor)
 * - ensureWriteAccess(actor)
 * - sanitizeUserInput(payload)
 * - ensureUuid(value, errorCode)
 */

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

module.exports = {
    SYSTEM_ROLES,
    UUID_REGEX,
    normalizeOptional,
    isSuperAdmin,
    hasWriteAccess,
    ensureWriteAccess,
    sanitizeUserInput,
    ensureUuid
};
