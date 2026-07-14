require('dotenv').config();
const adminNotificationService = require('./src/modules/admin/notifications/admin_notifications.service');
const pool = require('./src/config/db');

async function testAllNotifications() {
    console.log('Bắt đầu bắn thông báo test...');

    try {
        // 1. Thông báo Tạo Người Dùng
        await adminNotificationService.createNotification(
            'Tạo người dùng ví',
            'Người dùng ví mới "Test User" (test_user) đã được tạo.',
            'INFO',
            '/admin/users'
        );
        console.log('✅ Đã bắn thông báo: Tạo người dùng ví');

        // 2. Thông báo Tạo Nhân Viên
        await adminNotificationService.createNotification(
            'Tạo nhân viên mới',
            'Nhân viên mới "Test Staff" (test_staff) đã được tạo.',
            'INFO',
            '/admin/staffs'
        );
        console.log('✅ Đã bắn thông báo: Tạo nhân viên mới');

        // 3. Thông báo Tạo Merchant
        await adminNotificationService.createNotification(
            'Merchant Mới Đăng Ký',
            'Merchant mới "Test Merchant" vừa được tạo thành công trên hệ thống.',
            'SUCCESS',
            '/admin/merchants'
        );
        console.log('✅ Đã bắn thông báo: Tạo Merchant');

        // 4. Thông báo Cảnh Báo Lỗi (Error Rate)
        await adminNotificationService.createNotification(
            'Cảnh Báo Lỗi Giao Dịch',
            'Tỷ lệ lỗi giao dịch (Error Rate) tăng đột biến vượt mức 20%. Đề nghị kiểm tra hệ thống!',
            'CRITICAL',
            '/admin/reports'
        );
        console.log('✅ Đã bắn thông báo: Tỷ lệ lỗi giao dịch');

        // 5. Thông báo Hồ sơ KYC
        await adminNotificationService.createNotification(
            'Hồ sơ KYC Cần Duyệt',
            'Có 1 hồ sơ KYC mới đang chờ duyệt thủ công.',
            'WARNING',
            '/admin/kyc'
        );
        console.log('✅ Đã bắn thông báo: Hồ sơ KYC');

        // 6. Thông báo Xuất Báo Cáo
        await adminNotificationService.createNotification(
            'Xuất Báo Cáo Thành Công',
            'Báo cáo "Giao dịch tháng 7" đã được xuất thành công.',
            'SUCCESS',
            '/admin/reports'
        );
        console.log('✅ Đã bắn thông báo: Xuất Báo Cáo');

        console.log('\n🎉 Hoàn tất! Vui lòng kiểm tra trên góc phải màn hình Frontend Admin của bạn (cái chuông).');
    } catch (err) {
        console.error('❌ Lỗi khi bắn thông báo test:', err);
    } finally {
        pool.end();
        process.exit(0);
    }
}

testAllNotifications();
