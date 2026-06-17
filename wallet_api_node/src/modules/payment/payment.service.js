const crypto = require('crypto');
const pool = require('../../config/db');
const paymentRepo = require('./payment.repository');
const txRepo = require('../transaction/transaction.repository');

const paymentService = {
    createDynamicQR: async (merchantId, amount, callbackUrl, description) => {
        const client = await pool.connect();
        
        try {
            await client.query('BEGIN');

            
            const orderCode = 'ORD' + Date.now() + Math.floor(Math.random() * 1000);
            const expiredAt = new Date(Date.now() + 15 * 60 * 1000); 
            
            
            const orderId = await paymentRepo.createOrder(
                client, merchantId, orderCode, amount, callbackUrl, description, expiredAt
            );

            
            const qrToken = crypto.randomBytes(32).toString('hex');
            
            
            
            const qrContent = `vipayment://pay?token=${qrToken}&amount=${amount}&description=${encodeURIComponent(description || '')}`;
            const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=400x400&ecc=L&data=${encodeURIComponent(qrContent)}`;

            // Lưu thông tin mã QR
            await paymentRepo.createQrCode(client, orderId, qrContent, qrToken, expiredAt);

            await client.query('COMMIT');

            return {
                order_code: orderCode,
                amount: amount,
                description: description || null,
                qr_content: qrContent,
                qr_token: qrToken,
                qr_image_url: qrImageUrl,
                expired_at: expiredAt
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    processQrPayment: async (userId, qrToken) => {
        const client = await pool.connect();

        try {
            await client.query('BEGIN'); 

            
            const order = await paymentRepo.lockAndGetOrder(client, qrToken);
            
            if (!order) throw new Error('Order_Not_Found');
            if (new Date() > new Date(order.expired_at)) throw new Error('QR_Expired');
            if (order.status !== 'PENDING') throw new Error('Order_Already_Processed');

            
            const wallet = await txRepo.getWalletByUserId(userId);
            if (!wallet) throw new Error('Wallet_Not_Found');

            
            const balanceBefore = await txRepo.lockAndGetBalance(client, wallet.id);
            if (balanceBefore < order.amount) throw new Error('Insufficient_Balance');

            
            const balanceAfter = await txRepo.subtractBalance(client, wallet.id, order.amount);

            
            await paymentRepo.updateOrderStatus(client, order.order_id, 'SUCCESS');

            
            const ledgerTxId = await txRepo.createLedgerTransaction(
                client, 'PAYMENT', order.order_id, 'Thanh toán đơn hàng QR', order.amount
            );

            
            
            await txRepo.createLedgerEntry(
                client, ledgerTxId, wallet.id, 'DEBIT', order.amount, balanceBefore, balanceAfter
            );

            
            const paymentTxId = await paymentRepo.createPaymentTransaction(
                client, order.order_id, userId, wallet.id, order.amount, ledgerTxId
            );

            await client.query('COMMIT'); 

            // ==========================================
            // 🚀 BẮT ĐẦU BACKGROUND JOBS SAU KHI ĐÃ COMMIT
            // ==========================================

            // 1. Tích điểm Loyalty ngầm (Không await)
            const LoyaltyIntegrationService = require('./LoyaltyIntegrationService');
            LoyaltyIntegrationService.syncPointsAfterPayment(userId, paymentTxId, order.amount)
                .catch(err => console.error('[LOYALTY_BACKGROUND_JOB_ERROR]', err.message));

            // 2. Webhook gọi về cho Merchant (chạy nền)
            if (order.callback_url) {
                const axios = require('axios');
                axios.post(order.callback_url, {
                    order_id: order.order_id,
                    status: 'success',
                    amount: order.amount ? order.amount.toString() : '0'
                }).then(res => {
                    console.log(`[WEBHOOK_SUCCESS] Webhook gửi thành công tới ${order.callback_url}, Status Code:`, res.status);
                }).catch(err => {
                    console.error(`[WEBHOOK_ERROR] Lỗi gửi Webhook tới ${order.callback_url}:`, err.message);
                });
            }

            return {
                order_id: order.order_id,
                amount_paid: order.amount ? order.amount.toString() : '0',
                balance_remaining: balanceAfter ? balanceAfter.toString() : '0'
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    // Tạo mã QR "nhận tiền" cho người dùng thường (không cần merchant key)
    createUserQR: async (amount, description, userPhone, userName) => {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const orderCode = 'REQ' + Date.now() + Math.floor(Math.random() * 1000);
            const expiredAt = new Date(Date.now() + 15 * 60 * 1000); // 15 phút

            const orderId = await paymentRepo.createUserOrder(
                client, orderCode, amount, description, expiredAt
            );

            const qrToken = crypto.randomBytes(32).toString('hex');
            const qrContent = `vipayment://pay?token=${qrToken}&amount=${amount}&description=${encodeURIComponent(description || '')}&phone=${encodeURIComponent(userPhone || '')}&name=${encodeURIComponent(userName || '')}`;
            const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=400x400&ecc=L&data=${encodeURIComponent(qrContent)}`;

            await paymentRepo.createQrCode(client, orderId, qrContent, qrToken, expiredAt);

            await client.query('COMMIT');

            return {
                order_code: orderCode,
                amount: amount,
                description: description || null,
                qr_content: qrContent,
                qr_token: qrToken,
                qr_image_url: qrImageUrl,
                expired_at: expiredAt
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }
};

module.exports = paymentService;