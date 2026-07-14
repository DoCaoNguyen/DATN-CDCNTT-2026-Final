const pool = require('../../../config/db');
const { v7: uuidv7 } = require('uuid');

const adminNotificationRepository = {
    /**
     * Tạo thông báo mới cho Admin
     */
    createNotification: async (title, message, type = 'INFO', link = null) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO admin_notifications (id, title, message, type, link)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
        `;
        const result = await pool.query(query, [newId, title, message, type, link]);
        return result.rows[0];
    },

    /**
     * Lấy danh sách thông báo
     */
    getNotifications: async (limit = 50, offset = 0) => {
        const query = `
            SELECT *
            FROM admin_notifications
            ORDER BY created_at DESC
            LIMIT $1 OFFSET $2
        `;
        const result = await pool.query(query, [limit, offset]);
        return result.rows;
    },

    /**
     * Lấy số lượng thông báo chưa đọc
     */
    getUnreadCount: async () => {
        const query = `
            SELECT COUNT(*) 
            FROM admin_notifications
            WHERE is_read = false
        `;
        const result = await pool.query(query);
        return parseInt(result.rows[0].count, 10);
    },

    /**
     * Đánh dấu 1 thông báo là đã đọc
     */
    markAsRead: async (id) => {
        const query = `
            UPDATE admin_notifications
            SET is_read = true
            WHERE id = $1
            RETURNING *
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0];
    },

    /**
     * Đánh dấu tất cả thông báo là đã đọc
     */
    markAllAsRead: async () => {
        const query = `
            UPDATE admin_notifications
            SET is_read = true
            WHERE is_read = false
        `;
        const result = await pool.query(query);
        return result.rowCount;
    }
};

module.exports = adminNotificationRepository;
