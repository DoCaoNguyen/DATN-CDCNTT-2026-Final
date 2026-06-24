/**
 * Admin Payments Service
 * 
 * Cần implement:
 * - listPaymentOrders, getPaymentOrderDetail
 * - getPaymentTimeline, getPaymentLedger, getPaymentCallbacks
 * - listQrPayments, getQrPaymentDetail
 * - runExpireJob
 */
const paymentsRepository = require('./payments.repository');
const { ensureWriteAccess, ensureUuid } = require('../_shared/admin.validators');

const paymentsService = {
    // TODO: Implement payment service logic
};

module.exports = paymentsService;
