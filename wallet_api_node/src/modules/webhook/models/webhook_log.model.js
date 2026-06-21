const mongoose = require('mongoose');

const webhookLogSchema = new mongoose.Schema({
    merchant_id: { type: String, required: true },
    transaction_id: { type: String, required: true },
    idempotency_key: { type: String, required: true },
    payload: { type: mongoose.Schema.Types.Mixed, required: true },
    status: { type: String, enum: ['PENDING', 'SUCCESS', 'FAILED'], default: 'PENDING' },
    retry_count: { type: Number, default: 0 },
    max_retries: { type: Number, default: 5 },
    last_error: { type: String, default: null },
    created_at: { type: Date, default: Date.now },
    updated_at: { type: Date, default: Date.now }
});

// Middleware to update updated_at on save/update
webhookLogSchema.pre('save', function() {
    this.updated_at = Date.now();
});

webhookLogSchema.pre('findOneAndUpdate', function() {
    this.set({ updated_at: Date.now() });
});

// Indexes for fast querying
webhookLogSchema.index({ created_at: -1 });
webhookLogSchema.index({ merchant_id: 1, created_at: -1 });
webhookLogSchema.index({ status: 1 });
webhookLogSchema.index({ transaction_id: 1 });

const WebhookLog = mongoose.model('WebhookLog', webhookLogSchema);

module.exports = WebhookLog;
