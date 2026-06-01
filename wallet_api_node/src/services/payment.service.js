const crypto = require('crypto');
const pool = require('../config/db');
const paymentRepo = require('../repositories/payment.repository');
const txRepo = require('../repositories/transaction.repository');

const paymentService = {
    createDynamicQR: async (merchantId, amount, callbackUrl, description) => {
        const client = await pool.connect();
        
        try {
            await client.query('BEGIN');

            // 1. Khởi tạo dữ liệu ngẫu nhiên và thời gian hết hạn (ví dụ: 15 phút)
            const orderCode = 'ORD' + Date.now() + Math.floor(Math.random() * 1000);
            const expiredAt = new Date(Date.now() + 15 * 60 * 1000); 
            
            // 2. Tạo Payment Order
            const orderId = await paymentRepo.createOrder(
                client, merchantId, orderCode, amount, callbackUrl, description, expiredAt
            );

            // 3. Sinh Dynamic QR Token (Chuỗi 32 byte mã hóa Hex)
            const qrToken = crypto.randomBytes(32).toString('hex');
            
            // Nội dung QR thực tế thường là một Deeplink để Mobile App bắt được khi quét
            // App sẽ bóc tách URL này để lấy cái "token" ở đuôi và gọi lên Backend thanh toán
            const qrContent = `vipayment://pay?token=${qrToken}`;

            // 4. Tạo bản ghi QR Code
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
            await client.query('BEGIN'); // BẮT ĐẦU TRANSACTION

            // 1. Lấy thông tin đơn hàng và KHÓA dòng đơn hàng
            const order = await paymentRepo.lockAndGetOrder(client, qrToken);
            
            if (!order) throw new Error('Order_Not_Found');
            if (new Date() > new Date(order.expired_at)) throw new Error('QR_Expired');
            if (order.status !== 'PENDING') throw new Error('Order_Already_Processed');

            // 2. Lấy thông tin Ví của người quét mã
            const wallet = await txRepo.getWalletByUserId(userId);
            if (!wallet) throw new Error('Wallet_Not_Found');

            // 3. Khóa dòng Ví và lấy số dư hiện tại
            const balanceBefore = await txRepo.lockAndGetBalance(client, wallet.id);
            if (balanceBefore < order.amount) throw new Error('Insufficient_Balance');

            // 4. Trừ tiền Ví người trả
            const balanceAfter = await txRepo.subtractBalance(client, wallet.id, order.amount);

            // 5. Cập nhật trạng thái đơn hàng thành SUCCESS
            await paymentRepo.updateOrderStatus(client, order.order_id, 'SUCCESS');

            // 6. Ghi Sổ cái (Ledger)
            const ledgerTxId = await txRepo.createLedgerTransaction(
                client, 'PAYMENT', order.order_id, 'Thanh toán đơn hàng QR'
            );

            // 7. Ghi bút toán (Chỉ có dòng DEBIT trừ tiền ví user)
            // (Thực tế nếu hệ thống có ví trung gian của merchant thì sẽ có thêm dòng CREDIT)
            await txRepo.createLedgerEntry(
                client, ledgerTxId, wallet.id, 'DEBIT', order.amount, balanceBefore, balanceAfter
            );

            // 8. Ghi log Payment Transaction
            await paymentRepo.createPaymentTransaction(
                client, order.order_id, wallet.id, order.amount, ledgerTxId
            );

            await client.query('COMMIT'); // KẾT THÚC TRANSACTION AN TOÀN

            // (Sau này bạn có thể viết thêm logic gọi Webhook báo cho Merchant ở chỗ này)

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