const { v7: uuidv7 } = require('uuid');

const paymentRepository = {
    createOrder: async (client, merchantId, orderCode, amount, callbackUrl, description, expiredAt) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO payment_orders (id, merchant_id, order_code, amount, callback_url, description, status, expired_at)
            VALUES ($1, $2, $3, $4, $5, $6, 'PENDING', $7) 
            RETURNING id;
        `;
        const result = await client.query(query, [
            newId, merchantId, orderCode, amount, callbackUrl, description, expiredAt
        ]);
        return result.rows[0].id;
    },

    createQrCode: async (client, orderId, qrContent, qrToken, expiredAt) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO payment_qr_codes (id, payment_order_id, qr_content, qr_token, expired_at)
            VALUES ($1, $2, $3, $4, $5) 
            RETURNING id;
        `;
        const result = await client.query(query, [newId, orderId, qrContent, qrToken, expiredAt]);
        return result.rows[0].id;
    },

    // Tạo đơn hàng nhận tiền cho người dùng thường (không cần merchant_id)
    createUserOrder: async (client, orderCode, amount, description, expiredAt) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO payment_orders (id, order_code, amount, description, status, expired_at)
            VALUES ($1, $2, $3, $4, 'PENDING', $5)
            RETURNING id;
        `;
        const result = await client.query(query, [newId, orderCode, amount, description, expiredAt]);
        return result.rows[0].id;
    },

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
        const newId = uuidv7();
        const query = `
            INSERT INTO payment_transactions (id, payment_order_id, payer_wallet_id, amount, ledger_transaction_id, status, paid_at)
            VALUES ($1, $2, $3, $4, $5, 'SUCCESS', CURRENT_TIMESTAMP)
            RETURNING id;
        `;
        const result = await client.query(query, [newId, orderId, payerWalletId, amount, ledgerTxId]);
        return result.rows[0].id;
    }
};

module.exports = paymentRepository;