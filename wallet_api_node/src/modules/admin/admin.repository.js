const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

function buildPagination(page = 1, limit = 20) {
    const safePage = Math.max(Number(page) || 1, 1);
    const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
    return {
        page: safePage,
        limit: safeLimit,
        offset: (safePage - 1) * safeLimit
    };
}





const adminRepository = {
    withTransaction: async (callback) => {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const result = await callback(client);
            await client.query('COMMIT');
            return result;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },





    writeAuditLog: async ({ actorId, action, entityType, entityId, oldData, newData, metadata, reason, ipAddress, userAgent }) => {
        await pool.query(`
            INSERT INTO audit_logs
                (trace_id, actor_type, actor_id, action, entity_type, entity_id, old_data, new_data, metadata, reason, ip_address, user_agent)
            VALUES ($1, 'ADMIN', $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        `, [
            `trace-admin-${Date.now()}`,
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
};

module.exports = adminRepository;
