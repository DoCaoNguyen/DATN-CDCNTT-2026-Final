const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const auditLogRepository = {
    create: async ({
        client = pool,
        traceId,
        actorType = 'SYSTEM',
        actorId,
        action,
        entityType,
        entityId,
        oldData,
        newData,
        metadata,
        reason,
        ipAddress,
        userAgent
    }) => {
        const query = `
            INSERT INTO audit_logs
                (trace_id, actor_type, actor_id, action, entity_type, entity_id,
                 old_data, new_data, metadata, reason, ip_address, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        `;

        await client.query(query, [
            traceId || `trace-${uuidv7()}`,
            actorType,
            actorId || null,
            action,
            entityType,
            entityId || null,
            oldData ? JSON.stringify(oldData) : null,
            newData ? JSON.stringify(newData) : null,
            metadata ? JSON.stringify(metadata) : null,
            reason || null,
            ipAddress || null,
            userAgent || null
        ]);
    },

    writeAuditLog: (actorId, action, entityType, entityId, oldData, newData, ipAddress) => {
        auditLogRepository.create({
            actorType: actorId ? 'USER' : 'SYSTEM',
            actorId,
            action,
            entityType: entityType || 'system',
            entityId,
            oldData,
            newData,
            ipAddress
        }).catch(err => {
            console.error('[AUDIT_LOG_ERROR] Loi khi ghi Audit Log vao database:', err);
        });
    },

    listByEntity: async ({
        entityType,
        entityId,
        action,
        from,
        to,
        page = 1,
        pageSize = 20
    }) => {
        const safePage = Math.max(Number(page) || 1, 1);
        const safePageSize = Math.min(Math.max(Number(pageSize) || 20, 1), 100);
        const params = [entityType, entityId];
        const where = ['entity_type = $1', 'entity_id = $2'];

        if (action) {
            params.push(action);
            where.push(`action = $${params.length}`);
        }
        if (from) {
            params.push(from);
            where.push(`created_at >= $${params.length}::timestamptz`);
        }
        if (to) {
            params.push(to);
            where.push(`created_at <= $${params.length}::timestamptz`);
        }

        const whereSql = where.join(' AND ');
        const countResult = await pool.query(
            `SELECT COUNT(*)::int AS total FROM audit_logs WHERE ${whereSql}`,
            params
        );

        params.push(safePageSize, (safePage - 1) * safePageSize);
        const result = await pool.query(`
            SELECT id, trace_id, actor_type, actor_id, action, entity_type, entity_id,
                   old_data, new_data, metadata, reason, ip_address, user_agent, created_at
            FROM audit_logs
            WHERE ${whereSql}
            ORDER BY created_at DESC, id DESC
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `, params);

        return {
            items: result.rows,
            pagination: {
                page: safePage,
                page_size: safePageSize,
                total: countResult.rows[0].total
            }
        };
    }
};

module.exports = auditLogRepository;
