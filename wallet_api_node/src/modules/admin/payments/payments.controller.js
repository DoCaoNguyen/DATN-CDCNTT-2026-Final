/**
 * Admin Payments Controller
 * 
 * Cần implement:
 * - listPaymentOrders, getPaymentOrderDetail
 * - getPaymentTimeline, getPaymentLedger, getPaymentCallbacks
 * - listQrPayments, getQrPaymentDetail
 * - runExpireJob
 */
const paymentsService = require('./payments.service');
const { getRequestMeta, success, handleAdminError } = require('../_shared/admin.helpers');

const paymentsController = {
    // TODO: Implement payment management logic
};

module.exports = paymentsController;
