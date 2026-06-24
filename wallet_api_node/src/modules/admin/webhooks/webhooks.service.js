/**
 * Admin Webhooks Service
 * 
 * Cần implement:
 * - listWebhooks
 * - getWebhookDetail
 * - retryWebhook
 * - runRetryDueJob
 */
const webhooksRepository = require('./webhooks.repository');
const { ensureWriteAccess, ensureUuid } = require('../_shared/admin.validators');

const webhooksService = {
    // TODO: Implement webhook service logic
};

module.exports = webhooksService;
