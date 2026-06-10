const notificationRepository = require('./notification.repository');

const notificationController = {
    /**
     * Register or update a device token for the authenticated user
     */
    registerDeviceToken: async (req, res) => {
        try {
            const userId = req.user.userId || req.user.id; // From verifyToken middleware
            const { fcmToken, deviceName, deviceType } = req.body;

            if (!fcmToken) {
                return res.status(400).json({ error: 'FCM Token là bắt buộc' });
            }

            const device = await notificationRepository.upsertDeviceToken(
                userId,
                fcmToken,
                deviceName || null,
                deviceType || 'ANDROID'
            );

            return res.status(200).json({
                message: 'Đăng ký thiết bị nhận thông báo thành công',
                data: device
            });
        } catch (error) {
            console.error('Lỗi khi đăng ký thiết bị nhận thông báo:', error);
            return res.status(500).json({ error: 'Lỗi máy chủ nội bộ khi đăng ký thiết bị' });
        }
    }
};

module.exports = notificationController;
