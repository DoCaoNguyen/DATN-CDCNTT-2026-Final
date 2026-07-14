const adminNotificationService = require('./admin_notifications.service');
const { success, failure } = require('../../../utils/response.util');

const adminNotificationController = {
    getNotifications: async (req, res) => {
        try {
            const limit = parseInt(req.query.limit) || 50;
            const offset = parseInt(req.query.offset) || 0;

            const data = await adminNotificationService.getNotifications(limit, offset);

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách thông báo thành công',
                data: data
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    markAsRead: async (req, res) => {
        try {
            const { id } = req.params;
            const notification = await adminNotificationService.markAsRead(id);
            
            res.status(200).json({
                success: true,
                message: 'Đánh dấu đã đọc thành công',
                data: notification
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    },

    markAllAsRead: async (req, res) => {
        try {
            await adminNotificationService.markAllAsRead();
            
            res.status(200).json({
                success: true,
                message: 'Đánh dấu tất cả đã đọc thành công'
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, message: 'Lỗi hệ thống' });
        }
    }
};

module.exports = adminNotificationController;
