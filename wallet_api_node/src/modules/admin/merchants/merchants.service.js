/**
 * Admin Merchants Service
 * 
 * Cần implement:
 * - listMerchants
 * - getMerchantDetail
 * - approveMerchant
 * - rejectMerchant
 * - suspendMerchant
 * - activateMerchant
 * - getMerchantApiKeys
 */
const merchantsRepository = require('./merchants.repository');
const { ensureWriteAccess, ensureUuid } = require('../_shared/admin.validators');

const merchantsService = {
    // TODO: Implement merchant service logic
};

module.exports = merchantsService;
