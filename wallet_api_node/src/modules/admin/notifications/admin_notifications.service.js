const adminNotificationRepository = require('./admin_notifications.repository');
const { broadcastToAdminDashboard } = require('../../../utils/socket');

const adminNotificationService = {
    /**
     * Tạo thông báo và bắn socket cho admin
     */
    createNotification: async (title, message, type = 'INFO', link = null) => {
        try {
            // Lưu vào DB
            const notification = await adminNotificationRepository.createNotification(title, message, type, link);
            
            // Lấy lại số lượng chưa đọc
            const unreadCount = await adminNotificationRepository.getUnreadCount();

            // Phát sự kiện qua Socket.io đến room 'admin_dashboard'
            broadcastToAdminDashboard('new_admin_notification', {
                notification,
                unreadCount
            });

            return notification;
        } catch (error) {
            console.error('[AdminNotificationService] Error creating notification:', error);
            // Không throw error để không làm gián đoạn luồng chính của app
        }
    },

    getNotifications: async (limit, offset) => {
        const notifications = await adminNotificationRepository.getNotifications(limit, offset);
        const unreadCount = await adminNotificationRepository.getUnreadCount();
        return { notifications, unreadCount };
    },

    markAsRead: async (id) => {
        return await adminNotificationRepository.markAsRead(id);
    },

    markAllAsRead: async () => {
        return await adminNotificationRepository.markAllAsRead();
    }
};

module.exports = adminNotificationService;
