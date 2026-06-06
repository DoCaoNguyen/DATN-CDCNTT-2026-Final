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
            
            
            
            const qrContent = `vipayment://pay?token=${qrToken}`;

            
            await paymentRepoRepo.createQrCode(client, orderId, qrContent, qrToken, expiredAt);

            await client.query('COMMIT');

            return {
                order_code: orderCode,
                amount: amount,
                qr_content: qrContent,
                qr_token: qrToken,
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
                client, 'PAYMENT', order.order_id, 'Thanh toán đơn hàng QR'
            );

            
            
            await txRepo.createLedgerEntry(
                client, ledgerTxId, wallet.id, 'DEBIT', order.amount, balanceBefore, balanceAfter
            );

            
            await paymentRepo.createPaymentTransaction(
                client, order.order_id, wallet.id, order.amount, ledgerTxId
            );

            await client.query('COMMIT'); 

            

            return {
                order_id: order.order_id,
                amount_paid: order.amount,
                balance_remaining: balanceAfter
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