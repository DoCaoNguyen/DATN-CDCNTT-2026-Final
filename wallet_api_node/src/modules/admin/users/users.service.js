/**
 * Admin Users Service
 * 
 * Di chuyển từ admin.service.js:
 * - listUsers            (L53-61)
 * - getUserDetail        (L63-68)
 * - createUser           (L70-126)
 * - updateUser           (L128-168)
 * - lockUser             (L170-196)
 * - unlockUser           (L198-222)
 * - resetUserPassword    (L224-252)
 * - getUserAuditLogs     (L254-257)
 * - getUserWallet        (L291-295)
 */
const usersRepository = require('./users.repository');
const { ensureWriteAccess, ensureUuid, sanitizeUserInput, normalizeOptional, isSuperAdmin, SYSTEM_ROLES } = require('../_shared/admin.validators');

const usersService = {
    // TODO: Di chuyển logic từ admin.service.js
};

module.exports = usersService;
