const pool = require('../../config/db');

const notificationRepository = {
    /**
     * Get all active FCM tokens for a user
     * @param {string} userId - User UUID
     * @returns {Promise<Array<string>>} List of FCM tokens
     */
    getActiveTokensByUserId: async (userId) => {
        const query = `
            SELECT fcm_token 
            FROM user_devices 
            WHERE user_id = $1
        `;
        const result = await pool.query(query, [userId]);
        return result.rows.map(row => row.fcm_token);
    },

    /**
     * Upsert user's device token
     * @param {string} userId - User UUID
     * @param {string} fcmToken - Firebase registration token
     * @param {string} deviceName - Name of device
     * @param {string} deviceType - ANDROID, IOS, or WEB
     */
    upsertDeviceToken: async (userId, fcmToken, deviceName, deviceType) => {
        const query = `
            INSERT INTO user_devices (user_id, fcm_token, device_name, device_type, updated_at)
            VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
            ON CONFLICT (fcm_token) 
            DO UPDATE SET 
                user_id = EXCLUDED.user_id,
                device_name = COALESCE(EXCLUDED.device_name, user_devices.device_name),
                device_type = COALESCE(EXCLUDED.device_type, user_devices.device_type),
                updated_at = CURRENT_TIMESTAMP
            RETURNING *
        `;
        const result = await pool.query(query, [userId, fcmToken, deviceName, deviceType]);
        return result.rows[0];
    },

    /**
     * Delete invalid or expired token
     * @param {string} fcmToken - Token to delete
     */
    deleteDeviceToken: async (fcmToken) => {
        const query = `
            DELETE FROM user_devices 
            WHERE fcm_token = $1
        `;
        const result = await pool.query(query, [fcmToken]);
        return result.rowCount;
    },

    /**
     * Create an in-app notification record
     */
    createNotification: async (userId, title, content, notificationType, referenceId = null) => {
        const query = `
            INSERT INTO notifications (user_id, title, content, notification_type, reference_id, status, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, 'UNREAD', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING *
        `;
        const result = await pool.query(query, [
            userId, 
            title, 
            content, 
            notificationType, 
            referenceId
        ]);
        return result.rows[0];
    }
};

module.exports = notificationRepository;
