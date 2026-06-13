const pool = require('../../config/db');

const auditLogRepository = {
    /**
     * Ghi log thay đổi dữ liệu (Audit Log) bất đồng bộ (chạy nền)
     */
    writeAuditLog: (actorId, action, entityType, entityId, oldData, newData, ipAddress) => {
        const query = `
            INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, old_data, new_data, ip_address)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `;
        // Thực hiện bất đồng bộ (không await) để không làm chậm luồng API chính
        pool.query(query, [
            actorId || null,
            action,
            entityType || null,
            entityId || null,
            oldData ? JSON.stringify(oldData) : null,
            newData ? JSON.stringify(newData) : null,
            ipAddress || null
        ]).catch(err => {
            console.error('[AUDIT_LOG_ERROR] Lỗi khi ghi Audit Log vào database:', err);
        });
    }
};

module.exports = auditLogRepository;
