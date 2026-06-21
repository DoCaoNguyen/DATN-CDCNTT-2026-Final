const { v7: uuidv7 } = require('uuid');

const pool = require('../../config/db');

const paymentRepository = {
    createOrder: async (client, merchantId, orderCode, amount, callbackUrl, description, expiredAt, merchantOrderId = null) => {
        const newId = uuidv7();
        const idempotencyKey = uuidv7();
        const merchantOrderId = 'M' + Date.now();
        const query = `
            INSERT INTO payment_orders (id, merchant_id, order_code, amount, callback_url, description, status, expired_at, merchant_order_id)
            VALUES ($1, $2, $3, $4, $5, $6, 'PENDING', $7, $8) 
            RETURNING id;
        `;
        const result = await client.query(query, [
            newId, merchantId, orderCode, amount, callbackUrl, description, expiredAt, merchantOrderId
        ]);
        return result.rows[0].id;
    },

    createQrCode: async (client, orderId, qrContent, qrToken, expiredAt) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO payment_qr_codes (id, payment_order_id, qr_payload, qr_token, expired_at)
            VALUES ($1, $2, $3, $4, $5) 
            RETURNING id;
        `;
        const result = await client.query(query, [newId, orderId, qrContent, qrToken, expiredAt]);
        return result.rows[0].id;
    },

    getSystemMerchantId: async (client) => {
        const query = `SELECT id FROM merchants LIMIT 1`;
        const result = await client.query(query);
        if (result.rows.length === 0) {
            // Default UUID if no merchant exists yet
            return '00000000-0000-0000-0000-000000000000';
        }
        return result.rows[0].id;
    },

    // Tạo đơn hàng nhận tiền cho người dùng thường (sử dụng System Merchant)
    createUserOrder: async (client, orderCode, amount, description, expiredAt) => {
        const newId = uuidv7();
        const idempotencyKey = uuidv7();
        const merchantOrderId = 'REQ' + Date.now();
        const merchantId = await paymentRepository.getSystemMerchantId(client);

        const query = `
            INSERT INTO payment_orders (id, merchant_id, payment_no, merchant_order_id, amount, description, status, idempotency_key, expired_at)
            VALUES ($1, $2, $3, $4, $5, $6, 'PENDING', $7, $8)
            RETURNING id;
        `;
        const result = await client.query(query, [newId, merchantId, orderCode, merchantOrderId, amount, description, idempotencyKey, expiredAt]);
        return result.rows[0].id;
    },

    lockAndGetOrder: async (client, qrToken) => {
        const query = `
            SELECT po.id AS order_id, po.amount, po.status, po.merchant_id, 
                   po.callback_url, po.merchant_order_id, po.order_code, pq.expired_at
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

    createPaymentTransaction: async (client, orderId, payerUserId, payerWalletId, amount, ledgerTxId) => {
        const newId = uuidv7();
        const idempotencyKey = uuidv7();
        const query = `
            INSERT INTO payment_transactions (id, payment_order_id, payer_user_id, payer_wallet_id, amount, ledger_transaction_id, status, idempotency_key, paid_at)
            VALUES ($1, $2, $3, $4, $5, $6, 'SUCCESS', $7, CURRENT_TIMESTAMP)
            RETURNING id;
        `;
        const result = await client.query(query, [newId, orderId, payerUserId, payerWalletId, amount, ledgerTxId, idempotencyKey]);
        return result.rows[0].id;
    },

    // ===== NEW: Preview đơn hàng từ QR Token (không lock) =====
    getOrderByQrToken: async (qrToken) => {
        const query = `
            SELECT po.id AS order_id, po.order_code, po.merchant_order_id,
                   po.amount, po.description, po.status, po.currency,
                   pq.expired_at, pq.qr_token,
                   m.merchant_name
            FROM payment_qr_codes pq
            JOIN payment_orders po ON pq.payment_order_id = po.id
            LEFT JOIN merchants m ON po.merchant_id = m.id
            WHERE pq.qr_token = $1;
        `;
        const result = await pool.query(query, [qrToken]);
        return result.rows[0];
    },

    // ===== NEW: Merchant tra cứu trạng thái order bằng order_code =====
    getOrderByCode: async (merchantId, orderCode) => {
        const query = `
            SELECT po.id AS order_id, po.order_code, po.merchant_order_id,
                   po.amount, po.description, po.status, po.currency,
                   po.expired_at, po.created_at,
                   pt.id AS payment_transaction_id, pt.status AS payment_status,
                   pt.paid_at
            FROM payment_orders po
            LEFT JOIN payment_transactions pt ON po.id = pt.payment_order_id
            WHERE po.merchant_id = $1 AND po.order_code = $2;
        `;
        const result = await pool.query(query, [merchantId, orderCode]);
        return result.rows[0];
    },

    // ===== NEW: Merchant tra cứu bằng merchant_order_id riêng =====
    getOrderByMerchantOrderId: async (merchantId, merchantOrderId) => {
        const query = `
            SELECT po.id AS order_id, po.order_code, po.merchant_order_id,
                   po.amount, po.description, po.status, po.currency,
                   po.expired_at, po.created_at,
                   pt.id AS payment_transaction_id, pt.status AS payment_status,
                   pt.paid_at
            FROM payment_orders po
            LEFT JOIN payment_transactions pt ON po.id = pt.payment_order_id
            WHERE po.merchant_id = $1 AND po.merchant_order_id = $2;
        `;
        const result = await pool.query(query, [merchantId, merchantOrderId]);
        return result.rows[0];
    },

    // ===== NEW: Lấy chi tiết payment transaction =====
    getPaymentTransactionById: async (merchantId, transactionId) => {
        const query = `
            SELECT pt.id, pt.payment_order_id, pt.amount, pt.status, pt.paid_at, pt.created_at,
                   po.order_code, po.merchant_order_id, po.description,
                   po.status AS order_status
            FROM payment_transactions pt
            JOIN payment_orders po ON pt.payment_order_id = po.id
            WHERE pt.id = $1 AND po.merchant_id = $2;
        `;
        const result = await pool.query(query, [transactionId, merchantId]);
        return result.rows[0];
    }
};

module.exports = paymentRepository;