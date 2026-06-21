const AuditLog = require('./models/audit_log.model');

const auditLogRepository = {
    /**
     * Ghi log thay đổi dữ liệu (Audit Log) bất đồng bộ (chạy nền)
     */
    writeAuditLog: (actorId, action, entityType, entityId, oldData, newData, ipAddress) => {
        // Thực hiện bất đồng bộ (không await) để không làm chậm luồng API chính
        AuditLog.create({
            actor_id: actorId || null,
            action: action,
            entity_type: entityType || null,
            entity_id: entityId || null,
            old_data: oldData || null,
            new_data: newData || null,
            ip_address: ipAddress || null
        }).catch(err => {
            console.error('[AUDIT_LOG_ERROR] Lỗi khi ghi Audit Log vào MongoDB:', err);
        });
    }
};

module.exports = auditLogRepository;
