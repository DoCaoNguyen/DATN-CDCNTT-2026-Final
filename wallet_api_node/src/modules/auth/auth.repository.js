const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const authRepository = {
    checkExists: async (email, phone) => {
        const query = 'SELECT id FROM users WHERE ($1::text IS NOT NULL AND email = $1) OR phone = $2';
        const result = await pool.query(query, [email || null, phone]);
        return result.rows.length > 0;
    },

    create: async (client, email, phone, passwordHash, fullName, username = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO users (id, email, phone, password_hash, full_name, username, user_type, status)
            VALUES ($1, $2, $3, $4, $5, $6, 'USER', 'ACTIVE')
            RETURNING id
        `;
        const result = await client.query(query, [newId, email, phone, passwordHash, fullName || phone, username]);
        return result.rows[0].id;
    },

    assignRoleByCode: async (client, userId, roleCode = 'USER') => {
        const query = `
            INSERT INTO user_roles (user_id, role_id)
            SELECT $1, id FROM roles WHERE code = $2
            ON CONFLICT DO NOTHING
        `;
        await client.query(query, [userId, roleCode]);
    },

    findByLoginId: async (loginId) => {
        const query = `
            SELECT id, user_type, full_name, username, email, phone, password_hash, status,
                   failed_login_attempts, locked_until, last_login_at,
                   is_kyc_verified, token_version, created_at, updated_at
            FROM users
            WHERE username = $1 OR email = $1 OR phone = $1
        `;
        const result = await pool.query(query, [loginId]);
        return result.rows[0];
    },

    findByEmailOrPhone: async (identifier) => {
        return authRepository.findByLoginId(identifier);
    },

    findUserContextById: async (userId) => {
        const query = `
            SELECT id, user_type, full_name, username, email, phone, status,
                   is_kyc_verified, last_login_at, token_version, created_at, updated_at
            FROM users
            WHERE id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getRolesAndPermissions: async (userId) => {
        const rolesQuery = `
            SELECT DISTINCT r.code
            FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = $1 AND r.is_active = true
            ORDER BY r.code
        `;
        const permissionsQuery = `
            SELECT DISTINCT p.code
            FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            JOIN role_permissions rp ON rp.role_id = r.id
            JOIN permissions p ON p.id = rp.permission_id
            WHERE ur.user_id = $1 AND r.is_active = true
            ORDER BY p.code
        `;

        const [rolesResult, permissionsResult] = await Promise.all([
            pool.query(rolesQuery, [userId]),
            pool.query(permissionsQuery, [userId])
        ]);

        return {
            roles: rolesResult.rows.map(row => row.code),
            permissions: permissionsResult.rows.map(row => row.code)
        };
    },

    getMerchantContext: async (userId) => {
        const query = `
            SELECT mu.merchant_id, mu.role_code, mu.is_owner, m.status AS merchant_status
            FROM merchant_users mu
            JOIN merchants m ON m.id = mu.merchant_id
            WHERE mu.user_id = $1 AND mu.is_active = true
            ORDER BY mu.is_owner DESC, mu.created_at ASC
            LIMIT 1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0] || null;
    },

    updateFailedLogin: async (userId, attempts, lockMinutes = 0) => {
        if (lockMinutes > 0) {
            const query = `
                UPDATE users
                SET failed_login_attempts = $1,
                    locked_until = NOW() + ($2 || ' minutes')::interval,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = $3
            `;
            await pool.query(query, [attempts, lockMinutes, userId]);
            return;
        }

        const query = `
            UPDATE users
            SET failed_login_attempts = $1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $2
        `;
        await pool.query(query, [attempts, userId]);
    },

    resetFailedLogin: async (userId) => {
        const query = `
            UPDATE users
            SET failed_login_attempts = 0,
                locked_until = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
        `;
        await pool.query(query, [userId]);
    },

    markLoginSuccess: async (userId) => {
        const query = `
            UPDATE users
            SET failed_login_attempts = 0,
                locked_until = NULL,
                last_login_at = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
        `;
        await pool.query(query, [userId]);
    },

    updatePasswordHash: async (client, userId, passwordHash) => {
        const query = `
            UPDATE users
            SET password_hash = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2
        `;
        await client.query(query, [passwordHash, userId]);
    },

    incrementTokenVersion: async (userId) => {
        const query = `
            UPDATE users
            SET token_version = token_version + 1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING token_version
        `;
        const result = await pool.query(query, [userId]);
        return result.rows[0].token_version;
    },

    incrementTokenVersionWithClient: async (client, userId) => {
        const result = await client.query(`
            UPDATE users
            SET token_version = token_version + 1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING token_version
        `, [userId]);
        return result.rows[0]?.token_version;
    },

    createRefreshToken: async ({ userId, tokenHash, tokenFamilyId, expiresAt, ipAddress, userAgent }) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO refresh_tokens
                (id, user_id, token_hash, token_family_id, expires_at, created_by_ip, user_agent)
            VALUES ($1, $2, $3, COALESCE($4, gen_random_uuid()), $5, $6, $7)
            RETURNING id, token_family_id, expires_at
        `;
        const result = await pool.query(query, [
            newId,
            userId,
            tokenHash,
            tokenFamilyId || null,
            expiresAt,
            ipAddress || null,
            userAgent || null
        ]);
        return result.rows[0];
    },

    findRefreshTokenByHash: async (tokenHash) => {
        const query = `
            SELECT rt.*, u.status AS user_status
            FROM refresh_tokens rt
            JOIN users u ON u.id = rt.user_id
            WHERE rt.token_hash = $1
        `;
        const result = await pool.query(query, [tokenHash]);
        return result.rows[0];
    },

    revokeRefreshToken: async (tokenId, ipAddress) => {
        const query = `
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $2)
            WHERE id = $1
        `;
        await pool.query(query, [tokenId, ipAddress || null]);
    },

    revokeRefreshTokenByHash: async (userId, tokenHash, ipAddress) => {
        const query = `
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $3)
            WHERE user_id = $1 AND token_hash = $2
            RETURNING id
        `;
        const result = await pool.query(query, [userId, tokenHash, ipAddress || null]);
        return result.rows[0];
    },

    revokeRefreshTokenFamily: async (tokenFamilyId, ipAddress) => {
        const query = `
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $2)
            WHERE token_family_id = $1
        `;
        await pool.query(query, [tokenFamilyId, ipAddress || null]);
    },

    markRefreshTokenReused: async (tokenId) => {
        const query = `
            UPDATE refresh_tokens
            SET reused_at = COALESCE(reused_at, CURRENT_TIMESTAMP)
            WHERE id = $1
        `;
        await pool.query(query, [tokenId]);
    },

    revokeAllRefreshTokensForUser: async (userId, ipAddress) => {
        const query = `
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $2)
            WHERE user_id = $1 AND revoked_at IS NULL
        `;
        await pool.query(query, [userId, ipAddress || null]);
    },

    revokeAllRefreshTokensForUserWithClient: async (client, userId, ipAddress) => {
        await client.query(`
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $2)
            WHERE user_id = $1 AND revoked_at IS NULL
        `, [userId, ipAddress || null]);
    },

    revokeUnusedPasswordResetsWithClient: async (client, userId) => {
        await client.query(`
            UPDATE password_resets
            SET used_at = COALESCE(used_at, CURRENT_TIMESTAMP)
            WHERE user_id = $1 AND used_at IS NULL
        `, [userId]);
    },

    recordLoginAttempt: async ({ loginId, userId, success, failureReason, ipAddress, userAgent }) => {
        const query = `
            INSERT INTO auth_login_attempts
                (login_id, user_id, success, failure_reason, ip_address, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6)
        `;
        await pool.query(query, [
            loginId,
            userId || null,
            Boolean(success),
            failureReason || null,
            ipAddress || null,
            userAgent || null
        ]);
    },

    createPasswordReset: async ({ userId, tokenHash, expiresAt, ipAddress, userAgent }) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO password_resets
                (id, user_id, reset_token_hash, expires_at, ip_address, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, expires_at
        `;
        const result = await pool.query(query, [
            newId,
            userId,
            tokenHash,
            expiresAt,
            ipAddress || null,
            userAgent || null
        ]);
        return result.rows[0];
    },

    revokeUnusedPasswordResets: async (userId) => {
        const query = `
            UPDATE password_resets
            SET used_at = COALESCE(used_at, CURRENT_TIMESTAMP)
            WHERE user_id = $1 AND used_at IS NULL
        `;
        await pool.query(query, [userId]);
    },

    findPasswordResetByHash: async (tokenHash) => {
        const query = `
            SELECT pr.*, u.status AS user_status
            FROM password_resets pr
            JOIN users u ON u.id = pr.user_id
            WHERE pr.reset_token_hash = $1
        `;
        const result = await pool.query(query, [tokenHash]);
        return result.rows[0];
    },

    markPasswordResetUsed: async (client, resetId) => {
        const query = `
            UPDATE password_resets
            SET used_at = CURRENT_TIMESTAMP
            WHERE id = $1
        `;
        await client.query(query, [resetId]);
    },

    writeAuthAuditLog: async ({ actorType, actorId, action, entityId, metadata, ipAddress, userAgent }) => {
        const query = `
            INSERT INTO audit_logs
                (trace_id, actor_type, actor_id, action, entity_type, entity_id, metadata, ip_address, user_agent)
            VALUES ($1, $2, $3, $4, 'users', $5, $6, $7, $8)
        `;
        await pool.query(query, [
            `trace-auth-${Date.now()}`,
            actorType || 'SYSTEM',
            actorId || null,
            action,
            entityId || actorId || null,
            metadata ? JSON.stringify(metadata) : null,
            ipAddress || null,
            userAgent || null
        ]);
    },

    writeSecurityLog: async ({ event, message, context, entityId }) => {
        const query = `
            INSERT INTO system_logs (trace_id, level, module, event, message, context, entity_type, entity_id)
            VALUES ($1, 'WARN', 'AUTH', $2, $3, $4, 'users', $5)
        `;
        await pool.query(query, [
            `trace-auth-${Date.now()}`,
            event,
            message,
            context ? JSON.stringify(context) : null,
            entityId || null
        ]);
    }
};

module.exports = authRepository;
