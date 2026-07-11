const crypto = require('crypto');
const merchantsRepository = require('./merchants.repository');
const { ensureUuid, writeAuditLog, ensureWriteAccess } = require('../_shared');
const emailService = require('../../../shared/services/email.service');
const { encryptApiSecret } = require('../../../shared/utils/api-secret.util');

const generateApiKey = (env) => env === 'SANDBOX' ? `pk_test_${crypto.randomBytes(12).toString('hex')}` : `pk_live_${crypto.randomBytes(12).toString('hex')}`;
const generateApiSecret = (env) => env === 'SANDBOX' ? `sk_test_${crypto.randomBytes(24).toString('hex')}` : `sk_live_${crypto.randomBytes(24).toString('hex')}`;

const merchantsService = {
    createMerchant: async (data, actor) => {
        ensureWriteAccess(actor);
        
        // Validation Utilities
        const { normalizeMerchantName, normalizeTaxCode, normalizeVietnamPhone, normalizeEmail, normalizeFullName, normalizeUsername } = require('../_shared/validation.util');

        // Normalize Merchant Data
        data.merchant_name = normalizeMerchantName(data.merchant_name);
        data.email = normalizeEmail(data.email) || null;
        data.phone = normalizeVietnamPhone(data.phone) || null;
        data.tax_code = normalizeTaxCode(data.tax_code) || null;
        data.representative_name = data.representative_name ? String(data.representative_name).trim() || null : null;
        data.address = data.address ? String(data.address).trim() || null : null;

        // Check Merchant Conflicts (Only Email for Merchant)
        const merchantConflicts = await merchantsRepository.checkConflicts(data.email);
        const allErrors = [...merchantConflicts];

        // Normalize & Check Owner Conflicts
        if (data.owner_info) {
            data.owner_info.full_name = normalizeFullName(data.owner_info.full_name);
            data.owner_info.username = normalizeUsername(data.owner_info.username);
            data.owner_info.email = normalizeEmail(data.owner_info.email);
            data.owner_info.phone = normalizeVietnamPhone(data.owner_info.phone) || null;

            const usersRepository = require('../users/users.repository');
            const ownerConflict = await usersRepository.checkUserConflict({
                username: data.owner_info.username,
                email: data.owner_info.email,
                phone: data.owner_info.phone
            });
            
            if (ownerConflict) {
                if (ownerConflict.phone === data.owner_info.phone) {
                    allErrors.push({ field: 'owner.phone', code: 'PHONE_ALREADY_EXISTS', message: 'Số điện thoại này đã được sử dụng.' });
                }
                if (ownerConflict.email && ownerConflict.email === data.owner_info.email) {
                    allErrors.push({ field: 'owner.email', code: 'EMAIL_ALREADY_EXISTS', message: 'Email này đã được sử dụng.' });
                }
                if (ownerConflict.username === data.owner_info.username) {
                    allErrors.push({ field: 'owner.username', code: 'USERNAME_ALREADY_EXISTS', message: 'Tên đăng nhập đã được sử dụng.' });
                }
            }
        }

        if (allErrors.length > 0) {
            const error = new Error('Resource Conflict');
            error.statusCode = 409;
            error.code = 'RESOURCE_CONFLICT';
            error.errors = allErrors;
            throw error;
        }

        const MAX_RETRIES = 3;
        let attempt = 0;

        while (attempt < MAX_RETRIES) {
            attempt++;
            const pool = merchantsRepository.getPool();
            const client = await pool.connect();
            try {
                await client.query('BEGIN');
                
                // 1. Tự sinh merchant_code
                data.merchant_code = await merchantsRepository.generateNextMerchantCode(client);

                // 2. Tạo merchant
                const merchant = await merchantsRepository.createMerchant(data, client);

                // 3. Tạo Merchant Owner user (nếu có yêu cầu)
                let rawPassword = null;
                let userId = null;
                if (data.owner_info) {
                    const usersRepository = require('../users/users.repository');
                    const bcrypt = require('bcrypt');
                    const cryptoStr = require('crypto');
                    
                    rawPassword = cryptoStr.randomBytes(6).toString('hex');
                    const passwordHash = await bcrypt.hash(rawPassword, 10);
                    
                    userId = await usersRepository.createUser(client, {
                        fullName: data.owner_info.full_name,
                        username: data.owner_info.username,
                        email: data.owner_info.email,
                        phone: data.owner_info.phone,
                        passwordHash,
                        userType: 'MERCHANT_USER',
                        status: 'ACTIVE',
                        isForceChangePassword: true
                    });

                    await usersRepository.replaceRolesByCodes(client, userId, ['MERCHANT_OWNER']);
                    
                    const crypto = require('crypto');
                    await client.query(`
                        INSERT INTO merchant_users (id, merchant_id, user_id, role_code, is_owner)
                        VALUES ($1, $2, $3, $4, $5)
                    `, [crypto.randomUUID(), merchant.id, userId, 'MERCHANT_OWNER', true]);
                }
                
                // 4. Nếu có data callback thì tạo config
                let callbackConfig = null;
                const hasCallback = data.callback && (data.callback.default_callback_url || data.callback.default_redirect_url);
                
                if (hasCallback) {
                    callbackConfig = await merchantsRepository.createCallbackConfig(merchant.id, data.callback, client);
                }

                // 5. Tạo merchant_balances = 0
                await merchantsRepository.createMerchantBalance(merchant.id, client);

                const sanitizeCallbackConfig = (config) => {
                    if (!config) return null;
                    const { webhook_secret_hash, ...rest } = config;
                    return rest;
                };

                await writeAuditLog({
                    actorId: actor.userId,
                    action: 'merchant.create',
                    entityType: 'MERCHANT',
                    entityId: merchant.id,
                    oldData: null,
                    newData: { merchant_code: merchant.merchant_code, merchant_name: merchant.merchant_name },
                    ipAddress: actor.ipAddress,
                    userAgent: actor.userAgent
                });

                await client.query('COMMIT');

                // 6. Gửi email onboarding sau khi commit xong
                let emailSent = false;
                if (data.owner_info && data.owner_info.email) {
                    emailSent = await emailService.sendOnboardingEmail(data.owner_info.email, {
                        merchantName: merchant.merchant_name,
                        username: data.owner_info.username,
                        password: rawPassword
                    });
                }

                const responseData = {
                    ...merchant,
                    callback_config: sanitizeCallbackConfig(callbackConfig),
                    email_sent: emailSent,
                    owner_user_id: userId
                };

                return responseData;
            } catch (error) {
                await client.query('ROLLBACK');
                
                // Lỗi duplicate key trên merchant_code (23505)
                if (error.code === '23505' && error.constraint === 'merchants_merchant_code_key') {
                    if (attempt < MAX_RETRIES) {
                        console.warn(`Duplicate merchant_code generated, retrying... (Attempt ${attempt}/${MAX_RETRIES})`);
                        client.release();
                        continue;
                    } else {
                        client.release();
                        throw new Error('Failed to generate unique merchant_code after multiple attempts');
                    }
                }
                
                // Lỗi duplicate email (23505)
                if (error.code === '23505' && error.constraint === 'merchants_email_unique') {
                    client.release();
                    const conflictErr = new Error('Resource Conflict');
                    conflictErr.statusCode = 409;
                    conflictErr.code = 'RESOURCE_CONFLICT';
                    conflictErr.errors = [{ field: 'email', code: 'EMAIL_ALREADY_EXISTS', message: 'Email này đã được sử dụng cho một Merchant khác.' }];
                    throw conflictErr;
                }

                client.release();
                throw error;
            } finally {
                // Ensure release only if not released in catch
                if (client && typeof client.release === 'function' && !client._ending && !client._ended) {
                    try { client.release(); } catch(e){}
                }
            }
        }
    },

    updateMerchant: async (id, data, actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');
        
        const pool = merchantsRepository.getPool();
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            
            const merchant = await merchantsRepository.findMerchantById(id);
            if (!merchant) throw new Error('Merchant_Not_Found');

            const oldCallbackConfig = await merchantsRepository.findCallbackConfig(id, client);

            const updatedMerchant = await merchantsRepository.updateMerchantInfo(id, data.profile || data, client);
            
            let updatedCallback = null;
            if (data.callback) {
                if (oldCallbackConfig) {
                    updatedCallback = await merchantsRepository.updateCallbackConfig(oldCallbackConfig.id, data.callback, client);
                } else {
                    updatedCallback = await merchantsRepository.createCallbackConfig(id, data.callback, client);
                }
            }

            const sanitizeCallbackConfig = (config) => {
                if (!config) return null;
                const { webhook_secret_hash, ...rest } = config;
                return rest;
            };

            await writeAuditLog({
                actorId: actor.userId,
                action: 'merchant.update',
                entityType: 'MERCHANT',
                entityId: id,
                oldData: { merchant, callback_config: sanitizeCallbackConfig(oldCallbackConfig) },
                newData: { merchant: updatedMerchant, callback_config: sanitizeCallbackConfig(updatedCallback) },
                ipAddress: actor.ipAddress,
                userAgent: actor.userAgent
            });

            await client.query('COMMIT');
            return {
                merchant: updatedMerchant || merchant,
                callback_config: sanitizeCallbackConfig(updatedCallback || oldCallbackConfig)
            };
        } catch (error) {
            await client.query('ROLLBACK');
            
            // Lỗi duplicate email (23505)
            if (error.code === '23505' && error.constraint === 'merchants_email_unique') {
                const conflictErr = new Error('Resource Conflict');
                conflictErr.statusCode = 409;
                conflictErr.code = 'RESOURCE_CONFLICT';
                conflictErr.errors = [{ field: 'email', code: 'EMAIL_ALREADY_EXISTS', message: 'Email này đã được sử dụng cho một Merchant khác.' }];
                throw conflictErr;
            }
            
            throw error;
        } finally {
            client.release();
        }
    },

    createApiKey: async (id, data, actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');

        const pool = merchantsRepository.getPool();
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const merchant = await merchantsRepository.findMerchantById(id);
            if (!merchant) throw new Error('Merchant_Not_Found');
            if (merchant.status !== 'ACTIVE') throw new Error('Merchant_Not_Active');

            const existingKeys = await merchantsRepository.getMerchantApiKeys(id);
            const hasActiveKey = existingKeys.some(k => k.environment === data.environment && k.status === 'ACTIVE');
            if (hasActiveKey) throw new Error(`Merchant already has an ACTIVE API Key for ${data.environment}`);

            const rawApiKey = generateApiKey(data.environment);
            const rawSecret = generateApiSecret(data.environment);
            const secretEncrypted = encryptApiSecret(rawSecret);

            const newKey = await merchantsRepository.createApiKey(id, data.key_name, rawApiKey, secretEncrypted, data.environment, client);

            await writeAuditLog({
                actorId: actor.userId,
                action: 'merchant_api_key.create',
                entityType: 'MERCHANT_API_KEY',
                entityId: newKey.id,
                oldData: null,
                newData: { merchant_id: id, key_name: data.key_name, environment: data.environment },
                ipAddress: actor.ipAddress,
                userAgent: actor.userAgent
            });

            await client.query('COMMIT');
            
            // Trả về duy nhất 1 lần
            return {
                ...newKey,
                raw_secret: rawSecret
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    rotateApiKey: async (id, keyId, actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');
        ensureUuid(keyId, 'Invalid_Key_Id');

        const pool = merchantsRepository.getPool();
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const merchant = await merchantsRepository.findMerchantById(id, client);
            if (!merchant) throw new Error('Merchant_Not_Found');
            if (merchant.status !== 'ACTIVE') throw new Error('Merchant_Not_Active');

            const oldKey = await merchantsRepository.findApiKeyById(keyId, client);
            if (!oldKey || oldKey.merchant_id !== id) throw new Error('Api_Key_Not_Found');
            if (oldKey.status === 'REVOKED') throw new Error('Api_Key_Already_Revoked');

            // Thu hồi key cũ
            await merchantsRepository.updateApiKeyStatus(keyId, 'REVOKED', client);

            // Tạo key mới
            const rawApiKey = generateApiKey(oldKey.environment);
            const rawSecret = generateApiSecret(oldKey.environment);
            const secretEncrypted = encryptApiSecret(rawSecret);

            const newKey = await merchantsRepository.createApiKey(id, oldKey.key_name, rawApiKey, secretEncrypted, oldKey.environment, client);

            await writeAuditLog({
                actorId: actor.userId,
                action: 'merchant_api_key.rotate',
                entityType: 'MERCHANT_API_KEY',
                entityId: newKey.id,
                oldData: { old_key_id: oldKey.id, status: oldKey.status },
                newData: { new_key_id: newKey.id },
                ipAddress: actor.ipAddress,
                userAgent: actor.userAgent
            });

            await client.query('COMMIT');
            return {
                ...newKey,
                raw_secret: rawSecret
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    revokeApiKey: async (id, keyId, reason = 'Admin thu hồi', actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');
        ensureUuid(keyId, 'Invalid_Key_Id');
        const finalReason = reason && reason.trim() !== '' ? reason : 'Admin thu hồi';

        const oldKey = await merchantsRepository.findApiKeyById(keyId);
        if (!oldKey || oldKey.merchant_id !== id) throw new Error('Api_Key_Not_Found');
        if (oldKey.status === 'REVOKED') throw new Error('Api_Key_Already_Revoked');

        const revokedKey = await merchantsRepository.updateApiKeyStatus(keyId, 'REVOKED');

        await writeAuditLog({
            actorId: actor.userId,
            action: 'merchant_api_key.revoke',
            entityType: 'MERCHANT_API_KEY',
            entityId: keyId,
            oldData: { status: oldKey.status },
            newData: { status: 'REVOKED', reason },
            ipAddress: actor.ipAddress,
            userAgent: actor.userAgent
        });

        return revokedKey;
    },

    listMerchants: async (page, limit, search) => {
        return await merchantsRepository.listMerchants(page, limit, search);
    },

    getMerchantDetail: async (id) => {
        ensureUuid(id, 'Invalid_Merchant_Id');
        const merchant = await merchantsRepository.findMerchantById(id);
        if (!merchant) throw new Error('Merchant_Not_Found');

        const callbackConfig = await merchantsRepository.findCallbackConfig(id);
        if (callbackConfig) delete callbackConfig.webhook_secret_hash; // Không trả về secret hash ra ngoài

        return {
            merchant,
            callback_config: callbackConfig || null
        };
    },

    approveMerchant: async (id, reason, actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');
        
        const merchant = await merchantsRepository.findMerchantById(id);
        if (!merchant) throw new Error('Merchant_Not_Found');
        if (merchant.status === 'ACTIVE') throw new Error('Merchant_Already_Active');

        const updated = await merchantsRepository.updateMerchantStatus(id, 'ACTIVE', reason);

        await writeAuditLog({
            actorId: actor.userId,
            action: 'merchant.approve',
            entityType: 'MERCHANT',
            entityId: id,
            oldData: { status: merchant.status },
            newData: { status: 'ACTIVE', risk_note: reason || merchant.risk_note },
            ipAddress: actor.ipAddress,
            userAgent: actor.userAgent
        });

        return updated;
    },

    rejectMerchant: async (id, reason, actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');
        if (!reason || reason.trim() === '') throw new Error('Reason_Required');

        const merchant = await merchantsRepository.findMerchantById(id);
        if (!merchant) throw new Error('Merchant_Not_Found');
        if (merchant.status === 'REJECTED') throw new Error('Merchant_Already_Rejected');

        const updated = await merchantsRepository.updateMerchantStatus(id, 'REJECTED', reason);

        await writeAuditLog({
            actorId: actor.userId,
            action: 'merchant.reject',
            entityType: 'MERCHANT',
            entityId: id,
            oldData: { status: merchant.status },
            newData: { status: 'REJECTED', risk_note: reason },
            ipAddress: actor.ipAddress,
            userAgent: actor.userAgent
        });

        return updated;
    },

    suspendMerchant: async (id, reason, actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');
        if (!reason || reason.trim() === '') throw new Error('Reason_Required');

        const merchant = await merchantsRepository.findMerchantById(id);
        if (!merchant) throw new Error('Merchant_Not_Found');
        if (merchant.status === 'SUSPENDED') throw new Error('Merchant_Already_Suspended');

        const updated = await merchantsRepository.updateMerchantStatus(id, 'SUSPENDED', reason);

        await writeAuditLog({
            actorId: actor.userId,
            action: 'merchant.suspend',
            entityType: 'MERCHANT',
            entityId: id,
            oldData: { status: merchant.status },
            newData: { status: 'SUSPENDED', risk_note: reason },
            ipAddress: actor.ipAddress,
            userAgent: actor.userAgent
        });

        return updated;
    },

    activateMerchant: async (id, reason, actor) => {
        ensureWriteAccess(actor);
        ensureUuid(id, 'Invalid_Merchant_Id');

        const merchant = await merchantsRepository.findMerchantById(id);
        if (!merchant) throw new Error('Merchant_Not_Found');
        if (merchant.status === 'ACTIVE') throw new Error('Merchant_Already_Active');

        const updated = await merchantsRepository.updateMerchantStatus(id, 'ACTIVE', reason);

        await writeAuditLog({
            actorId: actor.userId,
            action: 'merchant.activate',
            entityType: 'MERCHANT',
            entityId: id,
            oldData: { status: merchant.status },
            newData: { status: 'ACTIVE', risk_note: reason || merchant.risk_note },
            ipAddress: actor.ipAddress,
            userAgent: actor.userAgent
        });

        return updated;
    },

    getMerchantApiKeys: async (id) => {
        ensureUuid(id, 'Invalid_Merchant_Id');
        const merchant = await merchantsRepository.findMerchantById(id);
        if (!merchant) throw new Error('Merchant_Not_Found');

        return await merchantsRepository.getMerchantApiKeys(id);
    }
};

module.exports = merchantsService;
