const pool = require('../../config/db');
const WebhookLog = require('./models/webhook_log.model');

const webhookService = {
    createLog: async (client, merchantId, transactionId, idempotencyKey, payload) => {
        // We use Mongoose for logs. We ignore the 'client' transaction parameter here since it's for Postgres.
        try {
            const newLog = await WebhookLog.create({
                merchant_id: merchantId,
                transaction_id: transactionId,
                idempotency_key: idempotencyKey,
                payload: payload,
                status: 'PENDING'
            });
            return newLog._id.toString();
        } catch (error) {
            console.error('[WebhookLog] Error creating log:', error);
            throw error;
        }
    },

    updateLogStatus: async (logId, status, lastError = null) => {
        try {
            await WebhookLog.findByIdAndUpdate(logId, {
                status: status,
                last_error: lastError
            });
        } catch (error) {
            console.error('[WebhookLog] Error updating log status:', error);
        }
    },

    incrementRetry: async (logId, lastError = null) => {
        try {
            const updatedLog = await WebhookLog.findByIdAndUpdate(
                logId,
                {
                    $inc: { retry_count: 1 },
                    last_error: lastError
                },
                { new: true } // Return the updated document
            );
            return {
                retry_count: updatedLog.retry_count,
                max_retries: updatedLog.max_retries
            };
        } catch (error) {
            console.error('[WebhookLog] Error incrementing retry:', error);
            throw error;
        }
    },

    getMerchantSecret: async (merchantId) => {
        const query = `SELECT secret_key, callback_url FROM merchants WHERE id = $1`;
        const result = await pool.query(query, [merchantId]);
        return result.rows[0];
    }
};

module.exports = webhookService;
