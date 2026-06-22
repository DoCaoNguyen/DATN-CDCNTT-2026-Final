const axios = require('axios');
const { v7: uuidv7 } = require('uuid');
const pool = require('../../config/db');
const notificationRepository = require('../notification/notification.repository');
const admin = require('../../config/firebase');
const LoyaltySyncLog = require('./models/loyalty_sync_log.model');

// Mock URL for Loyalty API, fallback to a mock domain if not set
const LOYALTY_API_URL = process.env.LOYALTY_API_URL || 'https://mock-loyalty-api.com/api/points/sync';

const LoyaltyIntegrationService = {
    /**
     * Đồng bộ điểm Loyalty sau khi thanh toán thành công
     * Chạy ngầm (Background Job)
     */
    syncPointsAfterPayment: async (userId, paymentTransactionId, amount) => {
        // Khởi tạo log PENDING trong MongoDB
        const logId = uuidv7();
        try {
            await LoyaltySyncLog.create({
                _id: logId,
                payment_transaction_id: paymentTransactionId,
                amount: amount,
                status: 'PENDING'
            });
        } catch (error) {
            console.error('[LOYALTY_SYNC] Error inserting initial log:', error.message);
            return; // Lỗi DB khi ghi log thì dừng lại
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
            const userRes = await client.query('SELECT loyalty_member_id FROM users WHERE id = $1', [userId]);
            const loyaltyMemberId = userRes.rows[0]?.loyalty_member_id || userId; // Dùng userId nếu chưa có

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
            await LoyaltySyncLog.updateOne(
                { _id: logId },
                { $set: { status: 'SUCCESS', earned_points: earnedPoints } }
            );

            // Bắn Push Notification
            await LoyaltyIntegrationService.sendPointsNotification(userId, earnedPoints, paymentTransactionId);

        } catch (error) {
            console.error('[LOYALTY_SYNC] Error syncing points:', error.message);
            
            // Cập nhật trạng thái FAILED
            await LoyaltySyncLog.updateOne(
                { _id: logId },
                { 
                    $set: { status: 'FAILED' },
                    $inc: { retry_count: isRetry ? 1 : 0 }
                }
            );
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
            // Lấy các log FAILED và thử lại < 3 lần từ MongoDB
            const failedLogs = await LoyaltySyncLog.find({
                status: 'FAILED',
                retry_count: { $lt: 3 }
            }).limit(50);

            if (failedLogs.length > 0) {
                console.log(`[LOYALTY_SYNC_CRON] Found ${failedLogs.length} failed logs. Retrying...`);
            }

            if (failedLogs.length > 0) {
                client = await pool.connect();
            }

            for (const log of failedLogs) {
                // Lấy userId từ bảng payment_transactions dựa trên payment_transaction_id
                const txRes = await client.query(`
                    SELECT wallet_id FROM payment_transactions WHERE id = $1
                `, [log.payment_transaction_id]);

                if (txRes.rows.length === 0) continue;
                
                const walletId = txRes.rows[0].wallet_id;
                // Lấy userId từ wallet
                const walletRes = await client.query(`SELECT user_id FROM wallets WHERE id = $1`, [walletId]);
                if (walletRes.rows.length === 0) continue;
                
                const userId = walletRes.rows[0].user_id;

                // Gọi lại tích điểm
                await LoyaltyIntegrationService.executeLoyaltyApiCall(
                    userId, 
                    log.payment_transaction_id, 
                    log.amount, 
                    log._id, 
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
