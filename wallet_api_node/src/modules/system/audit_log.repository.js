const pool = require('../../config/db');

const auditLogRepository = {
    writeAuditLog: (actorId, action, entityType, entityId, oldData, newData, ipAddress) => {
        const query = `
            INSERT INTO audit_logs
                (trace_id, actor_type, actor_id, action, entity_type, entity_id, old_data, new_data, ip_address)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        `;

        pool.query(query, [
            `trace-audit-${Date.now()}`,
            actorId ? 'USER' : 'SYSTEM',
            actorId || null,
            action,
            entityType || 'system',
            entityId || null,
            oldData ? JSON.stringify(oldData) : null,
            newData ? JSON.stringify(newData) : null,
            ipAddress || null
        ]).catch(err => {
            console.error('[AUDIT_LOG_ERROR] Loi khi ghi Audit Log vao database:', err);
        });
    }
};

module.exports = auditLogRepository;
