const cron = require('node-cron');
const pool = require('../config/db');
const adminNotificationService = require('../modules/admin/notifications/admin_notifications.service');

// Chạy mỗi 1 phút để dễ test
cron.schedule('* * * * *', async () => {
    try {
        // Lấy tổng số giao dịch và số giao dịch lỗi trong ngày hôm nay
        const query = `
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) as failed
            FROM payment_transactions
            WHERE created_at >= CURRENT_DATE
        `;
        
        const result = await pool.query(query);
        const total = parseInt(result.rows[0].total, 10);
        const failed = parseInt(result.rows[0].failed, 10) || 0;

        if (total > 0) { // Đổi thành > 0 để dễ test
            const errorRate = (failed / total) * 100;
            
            if (errorRate > 20) {
                // Nếu tỷ lệ lỗi > 20%, bắn cảnh báo CRITICAL
                await adminNotificationService.createNotification(
                    'Cảnh báo: Tỷ lệ lỗi giao dịch cao',
                    `Tỷ lệ giao dịch thất bại trong 5 phút qua đã đạt ${errorRate.toFixed(2)}% (${failed}/${total} giao dịch). Vui lòng kiểm tra cổng thanh toán ngay lập tức!`,
                    'CRITICAL'
                );
                console.log(`[Cron] Cảnh báo tỷ lệ lỗi giao dịch được phát đi: ${errorRate.toFixed(2)}%`);
            }
        }
    } catch (error) {
        console.error('[Cron] Lỗi khi chạy Error Rate Monitor:', error);
    }
});
