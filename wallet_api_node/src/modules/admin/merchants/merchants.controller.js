/**
 * Admin Merchants Controller
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
const merchantsService = require('./merchants.service');
const { getRequestMeta, success, handleAdminError } = require('../_shared/admin.helpers');

const merchantsController = {
    // TODO: Implement merchant management logic
};

module.exports = merchantsController;
