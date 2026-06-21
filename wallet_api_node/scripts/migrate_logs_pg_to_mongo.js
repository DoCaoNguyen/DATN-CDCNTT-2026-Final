require('dotenv').config();
const { Pool } = require('pg');
const mongoose = require('mongoose');

const SystemLog = require('../src/modules/system/models/system_log.model');
const AuditLog = require('../src/modules/system/models/audit_log.model');
const WebhookLog = require('../src/modules/webhook/models/webhook_log.model');

// Postgres Pool
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function migrateLogs() {
    try {
        console.log('--- Bắt đầu migrate dữ liệu log từ PostgreSQL sang MongoDB ---');
        
        // Connect MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('[MongoDB] Connected successfully.');

        // 1. System Logs
        console.log('Migrating system_logs...');
        const systemLogsResult = await pool.query('SELECT * FROM system_logs');
        const systemLogsData = systemLogsResult.rows.map(row => ({
            service_name: row.service_name,
            log_level: row.log_level,
            message: row.message,
            metadata: typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata,
            created_at: row.created_at
        }));
        if (systemLogsData.length > 0) {
            await SystemLog.insertMany(systemLogsData);
            console.log(`Đã migrate thành công ${systemLogsData.length} records system_logs.`);
        } else {
            console.log('Không có dữ liệu system_logs để migrate.');
        }

        // 2. Audit Logs
        console.log('Migrating audit_logs...');
        const auditLogsResult = await pool.query('SELECT * FROM audit_logs');
        const auditLogsData = auditLogsResult.rows.map(row => ({
            actor_id: row.actor_id,
            action: row.action,
            entity_type: row.entity_type,
            entity_id: row.entity_id,
            old_data: typeof row.old_data === 'string' ? JSON.parse(row.old_data) : row.old_data,
            new_data: typeof row.new_data === 'string' ? JSON.parse(row.new_data) : row.new_data,
            ip_address: row.ip_address,
            created_at: row.created_at
        }));
        if (auditLogsData.length > 0) {
            await AuditLog.insertMany(auditLogsData);
            console.log(`Đã migrate thành công ${auditLogsData.length} records audit_logs.`);
        } else {
            console.log('Không có dữ liệu audit_logs để migrate.');
        }

        // 3. Webhook Logs
        // Wait, what if table doesn't exist? We will catch the error.
        console.log('Migrating webhook_logs...');
        try {
            const webhookLogsResult = await pool.query('SELECT * FROM webhook_logs');
            const webhookLogsData = webhookLogsResult.rows.map(row => ({
                merchant_id: row.merchant_id,
                transaction_id: row.transaction_id,
                idempotency_key: row.idempotency_key,
                payload: typeof row.payload === 'string' ? JSON.parse(row.payload) : row.payload,
                status: row.status,
                retry_count: row.retry_count,
                max_retries: row.max_retries,
                last_error: row.last_error,
                created_at: row.created_at,
                updated_at: row.updated_at
            }));
            if (webhookLogsData.length > 0) {
                await WebhookLog.insertMany(webhookLogsData);
                console.log(`Đã migrate thành công ${webhookLogsData.length} records webhook_logs.`);
            } else {
                console.log('Không có dữ liệu webhook_logs để migrate.');
            }
        } catch (e) {
            console.error('Lỗi khi migrate webhook_logs (có thể bảng không tồn tại):', e.message);
        }

        console.log('--- Hoàn tất migrate ---');
    } catch (error) {
        console.error('Lỗi trong quá trình migrate:', error);
    } finally {
        await pool.end();
        await mongoose.disconnect();
    }
}

migrateLogs();
