const axios = require('axios');
const { v7: uuidv7 } = require('uuid');
const pool = require('../../config/db');
const notificationRepository = require('../notification/notification.repository');
const admin = require('../../config/firebase');

// Mock URL for Loyalty API, fallback to a mock domain if not set
const LOYALTY_API_URL = process.env.LOYALTY_API_URL || 'https://mock-loyalty-api.com/api/points/sync';

const LoyaltyIntegrationService = {
    /**
     * Đồng bộ điểm Loyalty sau khi thanh toán thành công
     * Chạy ngầm (Background Job)
     */
    syncPointsAfterPayment: async (userId, paymentTransactionId, amount) => {
        // Khởi tạo log PENDING
        const logId = uuidv7();
        let client;
        try {
            client = await pool.connect();
            await client.query(`
                INSERT INTO loyalty_sync_logs (id, payment_transaction_id, amount, status, retry_count, created_at)
                VALUES ($1, $2, $3, 'PENDING', 0, CURRENT_TIMESTAMP)
            `, [logId, paymentTransactionId, amount]);
        } catch (error) {
            console.error('[LOYALTY_SYNC] Error inserting initial log:', error.message);
            if (client) client.release();
            return; // Lỗi DB khi ghi log thì dừng lại
        } finally {
            if (client) client.release();
        }

        await LoyaltyIntegrationService.executeLoyaltyApiCall(userId, paymentTransactionId, amount, logId);
    },

    /**
     * Gửi request lên Loyalty API và cập nhật trạng thái
     */
    executeLoyaltyApiCall: async (userId, paymentTransactionId, amount, logId, isRetry = false) => {
        let client;
        try {
            // Lấy loyalty_member_id của user
            client = await pool.connect();
            const loyaltyMemberId = userId; // Fallback to userId as loyalty_member_id is not in DB

            // Gọi API Loyalty
            // Giả lập axios request
            let earnedPoints = 0;
            
            // NOTE: Đây là đoạn Mock API Call do chưa có hệ thống Loyalty thật
            // Nếu có URL thật, thay bằng axios.post(LOYALTY_API_URL, payload);
            try {
                // const response = await axios.post(LOYALTY_API_URL, {
                //     member_id: loyaltyMemberId,
                //     transaction_id: paymentTransactionId,
                //     amount: amount
                // });
                // earnedPoints = response.data.earned_points;

                // Giả lập trả về thành công sau 1 giây
                await new Promise(resolve => setTimeout(resolve, 1000));
                // Giả lập tỷ lệ 1000 VND = 1 điểm
                earnedPoints = Math.floor(amount / 1000); 
            } catch (apiError) {
                throw new Error('Loyalty API failed');
            }

            // Thành công -> Cập nhật log
            await client.query(`
                UPDATE loyalty_sync_logs 
                SET status = 'SUCCESS', earned_points = $1
                WHERE id = $2
            `, [earnedPoints, logId]);

            // Bắn Push Notification
            await LoyaltyIntegrationService.sendPointsNotification(userId, earnedPoints, paymentTransactionId);

        } catch (error) {
            console.error('[LOYALTY_SYNC] Error syncing points:', error.message);
            
            // Cập nhật trạng thái FAILED
            if (client) {
                await client.query(`
                    UPDATE loyalty_sync_logs 
                    SET status = 'FAILED', 
                        retry_count = retry_count + $1
                    WHERE id = $2
                `, [isRetry ? 1 : 0, logId]);
            }
        } finally {
            if (client) client.release();
        }
    },

    /**
     * Bắn push notification khi được cộng điểm
     */
    sendPointsNotification: async (userId, earnedPoints, paymentTransactionId) => {
        if (earnedPoints <= 0) return;

        const title = 'Tích điểm thành công!';
        const body = `Bạn đã được cộng ${earnedPoints} điểm từ giao dịch vừa rồi!`;

        try {
            // 1. Lưu thông báo vào bảng notifications
            await notificationRepository.createNotification(
                userId,
                title,
                body,
                'LOYALTY_POINTS',
                paymentTransactionId
            );

            // 2. Lấy danh sách thiết bị
            const activeTokens = await notificationRepository.getActiveTokensByUserId(userId);
            if (!activeTokens || activeTokens.length === 0) {
                return;
            }

            // 3. Gửi FCM
            const fcmPayload = {
                tokens: activeTokens,
                data: {
                    title: title,
                    body: body,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    type: 'LOYALTY_POINTS',
                    earned_points: String(earnedPoints),
                    timestamp: String(Date.now()),
                },
                android: {
                    priority: 'high',
                },
                apns: {
                    headers: {
                        'apns-priority': '10',
                    },
                    payload: {
                        aps: {
                            contentAvailable: true,
                            sound: 'default'
                        }
                    }
                }
            };

            await admin.messaging().sendEachForMulticast(fcmPayload);
        } catch (error) {
            console.error('[LOYALTY_SYNC] Push notification error:', error.message);
        }
    },

    /**
     * Cronjob: Gọi lại các log FAILED
     */
    retryFailedSyncs: async () => {
        let client;
        try {
            client = await pool.connect();
            // Lấy các log FAILED và thử lại < 3 lần
            const res = await client.query(`
                SELECT * FROM loyalty_sync_logs 
                WHERE status = 'FAILED' AND retry_count < 3
                LIMIT 50
            `);

            const failedLogs = res.rows;
            if (failedLogs.length > 0) {
                console.log(`[LOYALTY_SYNC_CRON] Found ${failedLogs.length} failed logs. Retrying...`);
            }

            for (const log of failedLogs) {
                // Lấy userId từ bảng wallets và payment_transactions dựa trên payment_transaction_id bằng 1 câu JOIN
                const txRes = await client.query(`
                    SELECT payer_user_id as user_id 
                    FROM payment_transactions 
                    WHERE id = $1
                `, [log.payment_transaction_id]);

                if (txRes.rows.length === 0) continue;
                
                const userId = txRes.rows[0].user_id;

                // Gọi lại tích điểm
                await LoyaltyIntegrationService.executeLoyaltyApiCall(
                    userId, 
                    log.payment_transaction_id, 
                    log.amount, 
                    log.id, 
                    true // isRetry
                );
            }
        } catch (error) {
            console.error('[LOYALTY_SYNC_CRON] Error:', error.message);
        } finally {
            if (client) client.release();
        }
    }
};

module.exports = LoyaltyIntegrationService;
