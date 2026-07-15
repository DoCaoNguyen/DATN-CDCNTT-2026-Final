const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const authRepository = {
    withTransaction: async callback => {
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

    checkExists: async (email, phone, username = null) => {
        const result = await pool.query(`
            SELECT id
            FROM users
            WHERE ($1::text IS NOT NULL AND email = $1)
               OR ($2::text IS NOT NULL AND phone = $2)
            LIMIT 1
        `, [email || null, phone || null]);
        return result.rows.length > 0;
    },

    createUser: async (client, { fullName, username, email, phone, passwordHash }) => {
        const id = uuidv7();
        const result = await client.query(`
            INSERT INTO users
                (id, user_type, full_name, email, phone, password_hash, status)
            VALUES ($1, 'USER', $2, $3, $4, $5, 'ACTIVE')
            RETURNING id, username, full_name, email, phone, status, created_at
        `, [id, fullName, email || null, phone, passwordHash]);
        return result.rows[0];
    },

    assignRoleByCode: async (client, userId, roleCode = 'USER') => {
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

    createWallet: async (client, userId) => {
        const walletId = uuidv7();
        const walletResult = await client.query(`
            INSERT INTO wallets (id, user_id, wallet_type, status)
            VALUES ($1, $2, 'PERSONAL', 'ACTIVE')
            RETURNING id, status
        `, [walletId, userId]);
        await client.query(`
            INSERT INTO wallet_balances (wallet_id, currency, available_balance, locked_balance)
            VALUES ($1, 'VND', 0, 0)
        `, [walletId]);
        return {
            ...walletResult.rows[0],
            currency: 'VND',
            available_balance: 0,
            locked_balance: 0
        };
    },

    findByLoginId: async loginId => {
        const result = await pool.query(`
            SELECT id, user_type, full_name, email, phone, password_hash,
                   status, failed_login_attempts, locked_until, last_login_at,
                   is_kyc_verified, token_version, created_at, updated_at
            FROM users
            WHERE LOWER(email) = LOWER($1) OR phone = $1
            LIMIT 1
        `, [loginId]);
        return result.rows[0];
    },

    findById: async userId => {
        const result = await pool.query(`
            SELECT id, user_type, full_name, email, phone, password_hash,
                   status, failed_login_attempts, locked_until, last_login_at,
                   is_kyc_verified, token_version, created_at, updated_at
            FROM users
            WHERE id = $1
        `, [userId]);
        return result.rows[0];
    },

    getRolesAndPermissions: async userId => {
        const [rolesResult, permissionsResult] = await Promise.all([
            pool.query(`
                SELECT DISTINCT r.code, r.name
                FROM user_roles ur
                JOIN roles r ON r.id = ur.role_id
                WHERE ur.user_id = $1 AND r.is_active = true
                ORDER BY r.code
            `, [userId]),
            pool.query(`
                SELECT DISTINCT jsonb_array_elements_text(r.permissions) AS code
                FROM user_roles ur
                JOIN roles r ON r.id = ur.role_id
                WHERE ur.user_id = $1 AND r.is_active = true
            `, [userId])
        ]);
        return {
            roles: rolesResult.rows,
            permissions: permissionsResult.rows.map(row => row.code)
        };
    },

    updateFailedLogin: async (userId, attempts, lockMinutes = 0) => {
        await pool.query(`
            UPDATE users
            SET failed_login_attempts = $2,
                locked_until = CASE
                    WHEN $3::int > 0 THEN NOW() + ($3::text || ' minutes')::interval
                    ELSE locked_until
                END,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
        `, [userId, attempts, lockMinutes]);
    },

    markLoginSuccess: async userId => {
        await pool.query(`
            UPDATE users
            SET failed_login_attempts = 0,
                locked_until = NULL,
                last_login_at = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
        `, [userId]);
    },

    incrementTokenVersion: async userId => {
        const result = await pool.query(`
            UPDATE users
            SET token_version = token_version + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING token_version
        `, [userId]);
        return Number(result.rows[0]?.token_version || 0);
    },

    saveRefreshToken: async (client, data) => {
        const id = uuidv7();
        await client.query(`
            INSERT INTO refresh_tokens
                (id, user_id, token_hash, token_family_id, expires_at, created_by_ip, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `, [
            id,
            data.userId,
            data.tokenHash,
            data.tokenFamilyId,
            data.expiresAt,
            data.ipAddress || null,
            data.userAgent || null
        ]);
        return id;
    },

    findRefreshTokenForUpdate: async (client, tokenHash) => {
        const result = await client.query(`
            SELECT *
            FROM refresh_tokens
            WHERE token_hash = $1
            FOR UPDATE
        `, [tokenHash]);
        return result.rows[0];
    },

    markRefreshTokenUsed: async (client, tokenId, ipAddress) => {
        await client.query(`
            UPDATE refresh_tokens
            SET revoked_at = CURRENT_TIMESTAMP,
                revoked_by_ip = $2
            WHERE id = $1 AND revoked_at IS NULL
        `, [tokenId, ipAddress || null]);
    },

    markRefreshTokenReused: async (client, tokenId) => {
        await client.query(`
            UPDATE refresh_tokens
            SET reused_at = COALESCE(reused_at, CURRENT_TIMESTAMP)
            WHERE id = $1
        `, [tokenId]);
    },

    revokeRefreshTokenFamily: async (client, tokenFamilyId, ipAddress) => {
        await client.query(`
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $2)
            WHERE token_family_id = $1
        `, [tokenFamilyId, ipAddress || null]);
    },

    revokeOne: async (tokenHash, userId = null, ipAddress = null) => {
        const result = await pool.query(`
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $3)
            WHERE token_hash = $1
              AND ($2::uuid IS NULL OR user_id = $2)
            RETURNING id
        `, [tokenHash, userId || null, ipAddress || null]);
        return result.rowCount > 0;
    },

    revokeAllUserRefreshTokens: async (client, userId, ipAddress = null) => {
        await client.query(`
            UPDATE refresh_tokens
            SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                revoked_by_ip = COALESCE(revoked_by_ip, $2)
            WHERE user_id = $1
        `, [userId, ipAddress || null]);
    },

    createPasswordReset: async ({ userId, tokenHash, expiresAt, ipAddress, userAgent }) => {
        const id = uuidv7();
        await pool.query(`
            UPDATE password_resets
            SET used_at = COALESCE(used_at, CURRENT_TIMESTAMP)
            WHERE user_id = $1 AND used_at IS NULL
        `, [userId]);
        await pool.query(`
            INSERT INTO password_resets
                (id, user_id, reset_token_hash, expires_at, ip_address, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6)
        `, [id, userId, tokenHash, expiresAt, ipAddress || null, userAgent || null]);
    },

    findPasswordResetForUpdate: async (client, tokenHash) => {
        const result = await client.query(`
            SELECT *
            FROM password_resets
            WHERE reset_token_hash = $1
            FOR UPDATE
        `, [tokenHash]);
        return result.rows[0];
    },

    consumePasswordReset: async (client, resetId) => {
        await client.query(`
            UPDATE password_resets
            SET used_at = CURRENT_TIMESTAMP
            WHERE id = $1 AND used_at IS NULL
        `, [resetId]);
    },

    updatePassword: async (client, userId, passwordHash) => {
        await client.query(`
            UPDATE users
            SET password_hash = $2,
                token_version = token_version + 1,
                updated_at = CURRENT_TIMESTAMP,
                is_force_change_password = false,
                temporary_password_expires_at = NULL,
                password_changed_at = CURRENT_TIMESTAMP
            WHERE id = $1
        `, [userId, passwordHash]);
    },

    forceResetPassword: async (client, userId, passwordHash, expiresAt) => {
        await client.query(`
            UPDATE users
            SET password_hash = $2,
                token_version = token_version + 1,
                updated_at = CURRENT_TIMESTAMP,
                is_force_change_password = true,
                temporary_password_expires_at = $3
            WHERE id = $1
        `, [userId, passwordHash, expiresAt]);
    },

    updatePasswordAfterVerify: async (client, userId, phone, passwordHash) => {
        const result = await client.query(`
            UPDATE users
            SET password_hash = $1,
                status = 'ACTIVE',
                token_version = token_version + 1,
                password_changed_at = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP,
                is_force_change_password = false,
                temporary_password_expires_at = NULL
            WHERE id = $2 
              AND phone = $3 
              AND user_type = 'USER' 
              AND status = 'PENDING_VERIFY'
            RETURNING id
        `, [passwordHash, userId, phone]);
        return result.rowCount;
    }
};

module.exports = authRepository;
