/**
 * Admin Merchants Repository
 * 
 * Cần implement:
 * - listMerchants()
 * - findMerchantById()
 * - approveMerchant()
 * - rejectMerchant()
 * - suspendMerchant()
 * - activateMerchant()
 * - getMerchantApiKeys()
 */
const pool = require('../../../config/db');
const { buildPagination } = require('../_shared/admin.pagination');

const merchantsRepository = {
    // TODO: Implement merchant repository queries
};

module.exports = merchantsRepository;
