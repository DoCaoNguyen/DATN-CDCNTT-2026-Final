/**
 * Admin Users Controller
 * 
 * Di chuyển từ admin.controller.js:
 * - listUsers         (L62-69)
 * - createUser        (L71-82)
 * - getUserDetail     (L84-91)
 * - updateUser        (L93-105)
 * - getUserWallet     (L107-114)
 * - lockUser          (L116-128)
 * - unlockUser        (L130-142)
 * - resetUserPassword (L144-158)
 * - getUserAuditLogs  (L160-170)
 */
const usersService = require('./users.service');
const { getRequestMeta, success, handleAdminError } = require('../_shared/admin.helpers');

const usersController = {
    // TODO: Di chuyển logic từ admin.controller.js
};

module.exports = usersController;
