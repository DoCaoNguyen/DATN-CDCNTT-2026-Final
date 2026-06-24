/**
 * Admin Users Repository
 * 
 * Di chuyển từ admin.repository.js:
 * - mapUserRow()           (L14-45)
 * - withTransaction()      (L81-94)
 * - listUsers()            (L96-146)
 * - findUserById()         (L148-167)
 * - findUserRawById()      (L169-172)
 * - checkUserConflict()    (L174-184)
 * - createUser()           (L186-203)
 * - assignRoleByCode()     (L205-215)
 * - updateUser()           (L217-245)
 * - lockUser()             (L247-258)
 * - unlockUser()           (L260-272)
 * - resetPasswordByAdmin() (L302-312)
 * - writeAuditLog()        (L413-431)
 */
const pool = require('../../../config/db');
const { buildPagination } = require('../_shared/admin.pagination');

const usersRepository = {
    // TODO: Di chuyển logic từ admin.repository.js
};

module.exports = usersRepository;
