const paymentRepository = {
    createOrder: async (client, merchantId, orderCode, amount, callbackUrl, description, expiredAt) => {
        const query = `
            INSERT INTO payment_orders (merchant_id, order_code, amount, callback_url, description, status, expired_at)
            VALUES ($1, $2, $3, $4, $5, 'PENDING', $6) 
            RETURNING id;
        `;
        const result = await client.query(query, [
            merchantId, orderCode, amount, callbackUrl, description, expiredAt
        ]);
        return result.rows[0].id;
    },

    createQrCode: async (client, orderId, qrContent, qrToken, expiredAt) => {
        const query = `
            INSERT INTO payment_qr_codes (payment_order_id, qr_content, qr_token, expired_at)
            VALUES ($1, $2, $3, $4) 
            RETURNING id;
        `;
        const result = await client.query(query, [orderId, qrContent, qrToken, expiredAt]);
        return result.rows[0].id;
    },

    // (Giữ nguyên các hàm createOrder, createQrCode ở trên...)

    // Lấy thông tin đơn hàng và KHÓA DÒNG để chống Double Payment
    lockAndGetOrder: async (client, qrToken) => {
        const query = `
            SELECT po.id AS order_id, po.amount, po.status, po.merchant_id, 
                   po.callback_url, pq.expired_at
            FROM payment_qr_codes pq
            JOIN payment_orders po ON pq.payment_order_id = po.id
            WHERE pq.qr_token = $1
            FOR UPDATE; -- Khóa dòng đơn hàng này lại trong Transaction
        `;
        const result = await client.query(query, [qrToken]);
        return result.rows[0];
    },

    updateOrderStatus: async (client, orderId, status) => {
        const query = `UPDATE payment_orders SET status = $1 WHERE id = $2`;
        await client.query(query, [status, orderId]);
    },

    createPaymentTransaction: async (client, orderId, payerWalletId, amount, ledgerTxId) => {
        const query = `
            INSERT INTO payment_transactions (payment_order_id, payer_wallet_id, amount, ledger_transaction_id, status, paid_at)
            VALUES ($1, $2, $3, $4, 'SUCCESS', CURRENT_TIMESTAMP)
            RETURNING id;
        `;
        const result = await client.query(query, [orderId, payerWalletId, amount, ledgerTxId]);
        return result.rows[0].id;
    }
};

module.exports = paymentRepository;