const crypto = require('crypto');
const merchantRepository = require('./merchant.repository');
const { writeAuditLog } = require('../admin/_shared');
const { encryptApiSecret } = require('../../shared/utils/api-secret.util');

const generateApiKeySandbox = () => `pk_test_${crypto.randomBytes(12).toString('hex')}`;
const generateApiSecretSandbox = () => `sk_test_${crypto.randomBytes(24).toString('hex')}`;
const generateApiSecretLive = () => `sk_live_${crypto.randomBytes(24).toString('hex')}`;

const merchantService = {
    createApiKey: async (merchantId, keyName, userId, ipAddress, userAgent) => {
        const rawApiKey = generateApiKeySandbox();
        const rawSecret = generateApiSecretSandbox();
        const secretEncrypted = encryptApiSecret(rawSecret);

        const newKey = await merchantRepository.createApiKey(merchantId, keyName, rawApiKey, secretEncrypted, 'SANDBOX');

        await writeAuditLog({
            actorId: userId,
            action: 'merchant.api_key.create',
            entityType: 'MERCHANT_API_KEY',
            entityId: newKey.id,
            oldData: null,
            newData: { merchant_id: merchantId, key_name: keyName, environment: 'SANDBOX' },
            ipAddress,
            userAgent
        }).catch(err => console.error("Audit log error:", err));

        return {
            ...newKey,
            raw_secret: rawSecret
        };
    },

    rotateApiKey: async (merchantId, keyId, userId, ipAddress, userAgent) => {
        const oldKey = await merchantRepository.getApiKeyByIdAndMerchant(keyId, merchantId);
        if (!oldKey) throw new Error('Api_Key_Not_Found');
        if (oldKey.status === 'REVOKED') throw new Error('Api_Key_Already_Revoked');

        const isLive = oldKey.environment === 'LIVE';
        const rawSecret = isLive
            ? generateApiSecretLive()
            : generateApiSecretSandbox();

        const secretEncrypted = encryptApiSecret(rawSecret);
        const updatedKey = await merchantRepository.updateApiSecretHash(keyId, secretEncrypted);

        await writeAuditLog({
            actorId: userId,
            action: 'merchant.api_key.rotate',
            entityType: 'MERCHANT_API_KEY',
            entityId: keyId,
            oldData: { status: oldKey.status },
            newData: { rotated: true },
            ipAddress,
            userAgent
        }).catch(err => console.error("Audit log error:", err));

        return {
            ...updatedKey,
            raw_secret: rawSecret
        };
    },

    revokeApiKey: async (merchantId, keyId, reason, userId, ipAddress, userAgent) => {
        const oldKey = await merchantRepository.getApiKeyByIdAndMerchant(keyId, merchantId);
        if (!oldKey) throw new Error('Api_Key_Not_Found');
        if (oldKey.status === 'REVOKED') throw new Error('Api_Key_Already_Revoked');

        await merchantRepository.revokeApiKey(keyId);

        await writeAuditLog({
            actorId: userId,
            action: 'merchant.api_key.revoke',
            entityType: 'MERCHANT_API_KEY',
            entityId: keyId,
            oldData: { status: oldKey.status },
            newData: { status: 'REVOKED', reason: reason || null },
            ipAddress,
            userAgent
        }).catch(err => console.error("Audit log error:", err));

        return true;
    }
};

module.exports = merchantService;
