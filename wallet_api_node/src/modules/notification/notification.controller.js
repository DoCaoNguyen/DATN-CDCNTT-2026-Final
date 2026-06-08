const notificationRepo = require('./notification.repository');
const admin = require('../../config/firebase'); // Gọi file config Firebase của bạn

class NotificationController {
    // API: Đăng ký thiết bị (App gọi lên khi mở app hoặc login)
    async registerDevice(req, res, next) {
        try {
            const userId = req.user.id; // Giả định middleware auth của bạn đã gán user vào req
            const { fcm_token, device_type, device_name } = req.body;

            if (!fcm_token) {
                return res.status(400).json({ success: false, message: 'fcm_token là bắt buộc' });
            }

            const device = await notificationRepo.upsertDeviceToken(userId, fcm_token, device_type, device_name);

            return res.status(200).json({
                success: true,
                message: 'Đăng ký thiết bị nhận thông báo thành công',
                data: device
            });
        } catch (error) {
            next(error);
        }
    }

    // Hàm nội bộ (Internal Helper): Dùng để gọi ở các module khác (ví dụ module wallet/transaction khi nạp/chuyển tiền thành công)
    async pushBalanceNotification(userId, amount, note, transactionId) {
        try {
            const tokens = await notificationRepo.getActiveTokensByUserId(userId);

            const formattedAmount = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
            const title = "Biến động số dư!";
            const body = `Tài khoản của bạn vừa thay đổi ${formattedAmount}. Nội dung: ${note}`;

            // 1. Lưu vào ví In-app trước
            await notificationRepo.createInAppNotification(userId, title, body, 'BALANCE_UPDATE', transactionId);

            if (tokens.length === 0) return;

            // 2. Cấu hình payload FCM
            const message = {
                tokens: tokens,
                notification: { title, body },
                data: {
                    type: 'BALANCE_UPDATE',
                    reference_id: String(transactionId)
                },
                android: { priority: 'high' },
                apns: { payload: { aps: { sound: 'default', badge: 1 } } }
            };

            // 3. Bắn thông báo qua Firebase
            const response = await admin.messaging().sendEachForMulticast(message);

            // Xử lý dọn dẹp các token lỗi/bị hủy đăng ký
            if (response.failureCount > 0) {
                response.responses.forEach(async (resp, idx) => {
                    if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
                        await notificationRepo.deactivateToken(tokens[idx]);
                    }
                });
            }
        } catch (error) {
            console.error("Lỗi khi xử lý push notification tự động:", error);
        }
    }
}

module.exports = new NotificationController();