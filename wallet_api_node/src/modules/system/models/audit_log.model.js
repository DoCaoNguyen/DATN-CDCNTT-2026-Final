const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
    actor_id: { type: String, default: null }, // Có thể là UUID
    action: { type: String, required: true },
    entity_type: { type: String, default: null },
    entity_id: { type: String, default: null },
    old_data: { type: mongoose.Schema.Types.Mixed, default: null },
    new_data: { type: mongoose.Schema.Types.Mixed, default: null },
    ip_address: { type: String, default: null },
    created_at: { type: Date, default: Date.now }
});

// Indexes for fast querying
auditLogSchema.index({ created_at: -1 });
auditLogSchema.index({ actor_id: 1, created_at: -1 });
auditLogSchema.index({ entity_type: 1, entity_id: 1 });
auditLogSchema.index({ action: 1 });

const AuditLog = mongoose.model('AuditLog', auditLogSchema);

module.exports = AuditLog;
