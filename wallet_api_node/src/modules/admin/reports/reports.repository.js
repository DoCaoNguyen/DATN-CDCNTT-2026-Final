/**
 * Admin Reports Repository
 * 
 * Cần implement:
 * - getTopupReportData()
 * - getTransferReportData()
 * - getPaymentReportData()
 * - getRefundReportData()
 * - getMerchantReportData()
 * - getWebhookReportData()
 * - getLedgerReportData()
 * - exportReportData()
 */
const pool = require('../../../config/db');
const { buildPagination } = require('../_shared/admin.pagination');

const reportsRepository = {
    // TODO: Implement report repository queries
};

module.exports = reportsRepository;
