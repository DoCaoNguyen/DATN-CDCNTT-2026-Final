/**
 * Admin Webhooks Controller
 * 
 * Cần implement:
 * - listWebhooks
 * - getWebhookDetail
 * - retryWebhook
 * - runRetryDueJob
 */
const webhooksService = require('./webhooks.service');
const { getRequestMeta, success, handleAdminError } = require('../_shared/admin.helpers');

const webhooksController = {
    // TODO: Implement webhook management logic
};

module.exports = webhooksController;
