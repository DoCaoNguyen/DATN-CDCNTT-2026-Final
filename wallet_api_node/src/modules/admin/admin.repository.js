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

function mapUserRow(row) {
    if (!row) return null;
    return {
        id: row.id,
        user_type: row.user_type,
        full_name: row.full_name,
        username: row.username,
        email: row.email,
        phone: row.phone,
        status: row.status,
        failed_login_attempts: row.failed_login_attempts,
        locked_until: row.locked_until,
        last_login_at: row.last_login_at,
        is_kyc_verified: row.is_kyc_verified,
        token_version: row.token_version,
        roles: row.roles || [],
        wallet: row.wallet_id ? {
            id: row.wallet_id,
            wallet_no: row.wallet_no,
            wallet_code: row.wallet_code,
            wallet_type: row.wallet_type,
            currency: row.currency,
            status: row.wallet_status,
            available_balance: Number(row.available_balance || 0),
            locked_balance: Number(row.locked_balance || 0),
            total_balance: Number(row.available_balance || 0) + Number(row.locked_balance || 0),
            updated_at: row.balance_updated_at
        } : null,
        created_at: row.created_at,
        updated_at: row.updated_at
    };
}

function mapWalletRow(row) {
    if (!row) return null;
    return {
        id: row.id,
        user_id: row.user_id,
        wallet_no: row.wallet_no,
        wallet_code: row.wallet_code,
        wallet_type: row.wallet_type,
        currency: row.currency,
        status: row.status,
        lock_reason: row.lock_reason,
        locked_at: row.locked_at,
        locked_by: row.locked_by,
        pin_failed_attempts: row.pin_failed_attempts,
        pin_locked_until: row.pin_locked_until,
        available_balance: Number(row.available_balance || 0),
        locked_balance: Number(row.locked_balance || 0),
        total_balance: Number(row.available_balance || 0) + Number(row.locked_balance || 0),
        balance_updated_at: row.balance_updated_at,
        user: {
            id: row.user_id,
            full_name: row.full_name,
            username: row.username,
            email: row.email,
            phone: row.phone,
            user_type: row.user_type,
            status: row.user_status
        },
        created_at: row.created_at,
        updated_at: row.updated_at
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

    listUsers: async ({ page, limit, q, status, userType }) => {
        const pagination = buildPagination(page, limit);
        const params = [];
        const where = [];

        if (q) {
            params.push(`%${q.trim()}%`);
            where.push(`(u.full_name ILIKE $${params.length} OR u.username ILIKE $${params.length} OR u.email ILIKE $${params.length} OR u.phone ILIKE $${params.length})`);
        }
        if (status) {
            params.push(status);
            where.push(`u.status = $${params.length}::user_status`);
        }
        if (userType) {
            params.push(userType);
            where.push(`u.user_type = $${params.length}::user_type`);
        }

        const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
        const countResult = await pool.query(`SELECT COUNT(*)::int AS total FROM users u ${whereSql}`, params);

        params.push(pagination.limit, pagination.offset);
        const result = await pool.query(`
            SELECT
                u.id, u.user_type, u.full_name, u.username, u.email, u.phone, u.status,
                u.failed_login_attempts, u.locked_until, u.last_login_at,
                u.is_kyc_verified, u.token_version, u.created_at, u.updated_at,
                COALESCE(ARRAY_AGG(DISTINCT r.code) FILTER (WHERE r.code IS NOT NULL), '{}') AS roles,
                w.id AS wallet_id, w.wallet_no, w.wallet_code, w.wallet_type, w.currency,
                w.status AS wallet_status, wb.available_balance, wb.locked_balance,
                wb.updated_at AS balance_updated_at
            FROM users u
            LEFT JOIN user_roles ur ON ur.user_id = u.id
            LEFT JOIN roles r ON r.id = ur.role_id
            LEFT JOIN wallets w ON w.user_id = u.id
            LEFT JOIN wallet_balances wb ON wb.wallet_id = w.id
            ${whereSql}
            GROUP BY u.id, w.id, wb.wallet_id
            ORDER BY u.created_at DESC
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `, params);

        return {
            items: result.rows.map(mapUserRow),
            pagination: {
                page: pagination.page,
                limit: pagination.limit,
                total: countResult.rows[0].total
            }
        };
    },

    findUserById: async (userId) => {
        const result = await pool.query(`
            SELECT
                u.id, u.user_type, u.full_name, u.username, u.email, u.phone, u.status,
                u.failed_login_attempts, u.locked_until, u.last_login_at,
                u.is_kyc_verified, u.token_version, u.created_at, u.updated_at,
                COALESCE(ARRAY_AGG(DISTINCT r.code) FILTER (WHERE r.code IS NOT NULL), '{}') AS roles,
                w.id AS wallet_id, w.wallet_no, w.wallet_code, w.wallet_type, w.currency,
                w.status AS wallet_status, wb.available_balance, wb.locked_balance,
                wb.updated_at AS balance_updated_at
            FROM users u
            LEFT JOIN user_roles ur ON ur.user_id = u.id
            LEFT JOIN roles r ON r.id = ur.role_id
            LEFT JOIN wallets w ON w.user_id = u.id
            LEFT JOIN wallet_balances wb ON wb.wallet_id = w.id
            WHERE u.id = $1
            GROUP BY u.id, w.id, wb.wallet_id
        `, [userId]);
        return mapUserRow(result.rows[0]);
    },

    findUserRawById: async (userId) => {
        const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
        return result.rows[0];
    },

    checkUserConflict: async ({ username, email, phone, excludeUserId }) => {
        const result = await pool.query(`
            SELECT id, username, email, phone
            FROM users
            WHERE ($1::text IS NOT NULL AND username = $1)
               OR ($2::text IS NOT NULL AND email = $2)
               OR ($3::text IS NOT NULL AND phone = $3)
        `, [username || null, email || null, phone || null]);

        return result.rows.find(row => row.id !== excludeUserId) || null;
    },

    createUser: async (client, { fullName, username, email, phone, passwordHash, userType, status }) => {
        const id = uuidv7();
        const result = await client.query(`
            INSERT INTO users (id, user_type, full_name, username, email, phone, password_hash, status)
            VALUES ($1, $2::user_type, $3, $4, $5, $6, $7, $8::user_status)
            RETURNING id
        `, [
            id,
            userType,
            fullName,
            username || null,
            email || null,
            phone || null,
            passwordHash,
            status || 'ACTIVE'
        ]);
        return result.rows[0].id;
    },

    assignRoleByCode: async (client, userId, roleCode) => {
        const result = await client.query(`
            INSERT INTO user_roles (user_id, role_id)
            SELECT $1, id
            FROM roles
            WHERE code = $2 AND is_active = true
            ON CONFLICT DO NOTHING
            RETURNING role_id
        `, [userId, roleCode]);
        return result.rowCount > 0;
    },

    updateUser: async (userId, updates) => {
        const fields = [];
        const params = [];
        const allowed = {
            full_name: 'full_name',
            username: 'username',
            email: 'email',
            phone: 'phone',
            is_kyc_verified: 'is_kyc_verified'
        };

        Object.entries(allowed).forEach(([inputKey, column]) => {
            if (Object.prototype.hasOwnProperty.call(updates, inputKey)) {
                params.push(updates[inputKey]);
                fields.push(`${column} = $${params.length}`);
            }
        });

        if (fields.length === 0) return null;
        params.push(userId);

        const result = await pool.query(`
            UPDATE users
            SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP
            WHERE id = $${params.length}
            RETURNING *
        `, params);
        return result.rows[0];
    },

    lockUser: async (userId) => {
        const result = await pool.query(`
            UPDATE users
            SET status = 'LOCKED',
                locked_until = NULL,
                token_version = token_version + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING *
        `, [userId]);
        return result.rows[0];
    },

    unlockUser: async (userId) => {
        const result = await pool.query(`
            UPDATE users
            SET status = 'ACTIVE',
                failed_login_attempts = 0,
                locked_until = NULL,
                token_version = token_version + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING *
        `, [userId]);
        return result.rows[0];
    },

    lockWalletByAdmin: async (client, walletId, actorId, reason) => {
        const result = await client.query(`
            UPDATE wallets
            SET status = 'LOCKED',
                lock_reason = $2,
                locked_at = CURRENT_TIMESTAMP,
                locked_by = $3,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING *
        `, [walletId, reason, actorId]);
        return result.rows[0];
    },

    unlockWalletByAdmin: async (client, walletId) => {
        const result = await client.query(`
            UPDATE wallets
            SET status = 'ACTIVE',
                lock_reason = NULL,
                locked_at = NULL,
                locked_by = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING *
        `, [walletId]);
        return result.rows[0];
    },
    
    resetPasswordByAdmin: async (client, userId, passwordHash) => {
        const result = await client.query(`
            UPDATE users
            SET password_hash = $2,
                token_version = token_version + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING *
        `, [userId, passwordHash]);
        return result.rows[0];
    },

    listWallets: async ({ page, limit, q, status, userId }) => {
        const pagination = buildPagination(page, limit);
        const params = [];
        const where = [];

        if (q) {
            params.push(`%${q.trim()}%`);
            where.push(`(w.wallet_no ILIKE $${params.length} OR w.wallet_code ILIKE $${params.length} OR u.full_name ILIKE $${params.length} OR u.phone ILIKE $${params.length} OR u.email ILIKE $${params.length})`);
        }
        if (status) {
            params.push(status);
            where.push(`w.status = $${params.length}::wallet_status`);
        }
        if (userId) {
            params.push(userId);
            where.push(`w.user_id = $${params.length}`);
        }

        const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
        const countResult = await pool.query(`
            SELECT COUNT(*)::int AS total
            FROM wallets w
            JOIN users u ON u.id = w.user_id
            ${whereSql}
        `, params);

        params.push(pagination.limit, pagination.offset);
        const result = await pool.query(`
            SELECT
                w.id, w.user_id, w.wallet_no, w.wallet_code, w.wallet_type, w.currency,
                w.status, w.lock_reason, w.locked_at, w.locked_by, w.pin_failed_attempts,
                w.pin_locked_until, w.created_at, w.updated_at,
                wb.available_balance, wb.locked_balance, wb.updated_at AS balance_updated_at,
                u.full_name, u.username, u.email, u.phone, u.user_type, u.status AS user_status
            FROM wallets w
            JOIN users u ON u.id = w.user_id
            LEFT JOIN wallet_balances wb ON wb.wallet_id = w.id
            ${whereSql}
            ORDER BY w.created_at DESC
            LIMIT $${params.length - 1} OFFSET $${params.length}
        `, params);

        return {
            items: result.rows.map(mapWalletRow),
            pagination: {
                page: pagination.page,
                limit: pagination.limit,
                total: countResult.rows[0].total
            }
        };
    },

    findWalletById: async (walletId) => {
        const result = await pool.query(`
            SELECT
                w.id, w.user_id, w.wallet_no, w.wallet_code, w.wallet_type, w.currency,
                w.status, w.lock_reason, w.locked_at, w.locked_by, w.pin_failed_attempts,
                w.pin_locked_until, w.created_at, w.updated_at,
                wb.available_balance, wb.locked_balance, wb.updated_at AS balance_updated_at,
                u.full_name, u.username, u.email, u.phone, u.user_type, u.status AS user_status
            FROM wallets w
            JOIN users u ON u.id = w.user_id
            LEFT JOIN wallet_balances wb ON wb.wallet_id = w.id
            WHERE w.id = $1
        `, [walletId]);
        return mapWalletRow(result.rows[0]);
    },

    listWalletLedger: async ({ walletId, page, limit }) => {
        const pagination = buildPagination(page, limit);
        const countResult = await pool.query(`
            SELECT COUNT(*)::int AS total
            FROM ledger_entries
            WHERE wallet_id = $1
        `, [walletId]);

        const result = await pool.query(`
            SELECT
                le.id, le.entry_type, le.amount, le.balance_before, le.balance_after,
                le.description, le.created_at,
                lt.id AS ledger_transaction_id, lt.transaction_no, lt.transaction_type,
                lt.status, lt.source_type, lt.source_id, lt.completed_at
            FROM ledger_entries le
            JOIN ledger_transactions lt ON lt.id = le.ledger_transaction_id
            WHERE le.wallet_id = $1
            ORDER BY le.created_at DESC
            LIMIT $2 OFFSET $3
        `, [walletId, pagination.limit, pagination.offset]);

        return {
            items: result.rows,
            pagination: {
                page: pagination.page,
                limit: pagination.limit,
                total: countResult.rows[0].total
            }
        };
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
    // ==========================================
    // DASHBOARD REPOSITORY (Theo DB Mới)
    // ==========================================
    getDashboardStats: async () => {
        // 1. Tính Tổng giao dịch, Tổng tiền (Thành công) và Tổng giao dịch Lỗi
        const txQuery = `
            SELECT 
                COUNT(id) AS total_tx, 
                COALESCE(SUM(amount) FILTER (WHERE status = 'SUCCESS'), 0) AS total_amount,
                COUNT(id) FILTER (WHERE status = 'FAILED') AS failed_tx
            FROM ledger_transactions 
        `;
        
        const userQuery = `SELECT COUNT(id) AS total_users FROM users WHERE user_type = 'USER'`;
        const merchantQuery = `SELECT COUNT(id) AS total_merchants FROM merchants`;
        const chartQuery = `
            SELECT TO_CHAR(DATE_TRUNC('day', completed_at), 'DD/MM') AS time, COALESCE(SUM(amount), 0) AS amount
            FROM ledger_transactions WHERE status = 'SUCCESS' AND completed_at IS NOT NULL AND completed_at >= NOW() - INTERVAL '7 days'
            GROUP BY DATE_TRUNC('day', completed_at) ORDER BY DATE_TRUNC('day', completed_at) ASC
        `;
        const recentQuery = `
            SELECT transaction_no, transaction_type, amount, currency, status, created_at
            FROM ledger_transactions ORDER BY created_at DESC LIMIT 5
        `;

        const [txRes, userRes, merchantRes, chartRes, recentRes] = await Promise.all([
            pool.query(txQuery), pool.query(userQuery), pool.query(merchantQuery), pool.query(chartQuery), pool.query(recentQuery)
        ]);

        // Tính toán Tỷ lệ lỗi (Error Rate)
        const totalTx = parseInt(txRes.rows[0].total_tx, 10) || 0;
        const failedTx = parseInt(txRes.rows[0].failed_tx, 10) || 0;
        const errorRate = totalTx > 0 ? ((failedTx / totalTx) * 100).toFixed(2) : 0;

        return {
            total_transactions: totalTx,
            total_amount: parseInt(txRes.rows[0].total_amount, 10) || 0,
            error_rate: parseFloat(errorRate), // Đẩy tỷ lệ lỗi ra cho Frontend
            total_users: parseInt(userRes.rows[0].total_users, 10) || 0,
            total_merchants: parseInt(merchantRes.rows[0].total_merchants, 10) || 0,
            chart_data: chartRes.rows.map(r => ({ time: r.time, amount: parseInt(r.amount, 10) || 0 })),
            recent_transactions: recentRes.rows
        };
    }
};

module.exports = adminRepository;
