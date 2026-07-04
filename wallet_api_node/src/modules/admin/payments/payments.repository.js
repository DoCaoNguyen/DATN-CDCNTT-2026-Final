/**
 * Admin Payments Repository
 * 
 * Cần implement:
 * - listPaymentOrders(), findPaymentOrderById()
 * - getPaymentTimeline(), getPaymentLedger(), getPaymentCallbacks()
 * - listQrPayments(), findQrPaymentById()
 * - expireQrPayments()
 */
const pool = require('../../../config/db');

const paymentsRepository = {
    listPaymentOrders: async (page, limit, status, merchantId) => {
        let query = `
            SELECT po.id, po.payment_no, po.amount, po.status, po.currency, 
                   po.created_at, po.expired_at, m.merchant_name,
                   po.merchant_order_id
            FROM payment_orders po
            LEFT JOIN merchants m ON po.merchant_id = m.id
            WHERE 1=1
        `;
        const params = [];
        let paramCount = 1;

        if (status) {
            query += ` AND po.status = $${paramCount++}`;
            params.push(status);
        }

        if (merchantId) {
            query += ` AND po.merchant_id = $${paramCount++}`;
            params.push(merchantId);
        }

        query += ` ORDER BY po.created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount++}`;
        params.push(limit);
        params.push((page - 1) * limit);

        const countQuery = `
            SELECT COUNT(*) FROM payment_orders po
            WHERE 1=1
            ${status ? `AND po.status = '${status}'` : ''}
            ${merchantId ? `AND po.merchant_id = '${merchantId}'` : ''}
        `;

        const [itemsResult, countResult] = await Promise.all([
            pool.query(query, params),
            pool.query(countQuery)
        ]);

        return {
            items: itemsResult.rows,
            total: parseInt(countResult.rows[0].count, 10)
        };
    },

    getPaymentOrderDetail: async (id) => {
        const query = `
            SELECT po.*, m.merchant_name 
            FROM payment_orders po
            LEFT JOIN merchants m ON po.merchant_id = m.id
            WHERE po.id = $1
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0];
    },

    getPaymentTimeline: async (id) => {
        const query = `
            SELECT 'ORDER_CREATED' as event, created_at as time, status::text as status, null::numeric as amount FROM payment_orders WHERE id = $1
            UNION ALL
            SELECT 'PAYMENT_TRANSACTION' as event, paid_at as time, status::text as status, amount::numeric as amount FROM payment_transactions WHERE payment_order_id = $1
            UNION ALL
            SELECT 'REFUND' as event, refunded_at as time, status::text as status, amount::numeric as amount FROM refund_transactions WHERE payment_order_id = $1
            ORDER BY time DESC
        `;
        const result = await pool.query(query, [id]);
        return result.rows;
    },

    getPaymentLedger: async (id) => {
        const query = `
            SELECT lt.* 
            FROM ledger_transactions lt
            JOIN payment_transactions pt ON lt.source_id = pt.id
            WHERE pt.payment_order_id = $1
            UNION ALL
            SELECT lt.* 
            FROM ledger_transactions lt
            JOIN refund_transactions rt ON lt.source_id = rt.id
            WHERE rt.payment_order_id = $1
        `;
        const result = await pool.query(query, [id]);
        return result.rows;
    },

    getPaymentCallbacks: async (id) => {
        // Since webhook_attempt_logs stores payment_order_id directly, we don't need the PG lookup anymore
        const WebhookAttemptLog = require('../../webhook/models/webhook_attempt_log.model');
        const callbacks = await WebhookAttemptLog.find({
            payment_order_id: id
        }).lean();
        return callbacks;
    },

    listRefunds: async (page, limit, status, merchantId) => {
        let query = `
            SELECT rt.id, rt.refund_no, rt.amount, rt.status, rt.currency, 
                   rt.created_at, rt.refunded_at, m.merchant_name,
                   po.payment_no
            FROM refund_transactions rt
            LEFT JOIN merchants m ON rt.merchant_id = m.id
            LEFT JOIN payment_orders po ON rt.payment_order_id = po.id
            WHERE 1=1
        `;
        const params = [];
        let paramCount = 1;

        if (status) {
            query += ` AND rt.status = $${paramCount++}`;
            params.push(status);
        }

        if (merchantId) {
            query += ` AND rt.merchant_id = $${paramCount++}`;
            params.push(merchantId);
        }

        query += ` ORDER BY rt.created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount++}`;
        params.push(limit);
        params.push((page - 1) * limit);

        const countQuery = `
            SELECT COUNT(*) FROM refund_transactions rt
            WHERE 1=1
            ${status ? `AND rt.status = '${status}'` : ''}
            ${merchantId ? `AND rt.merchant_id = '${merchantId}'` : ''}
        `;

        const [itemsResult, countResult] = await Promise.all([
            pool.query(query, params),
            pool.query(countQuery)
        ]);

        return {
            items: itemsResult.rows,
            total: parseInt(countResult.rows[0].count, 10)
        };
    },

    getRefundDetail: async (id) => {
        const query = `
            SELECT rt.*, m.merchant_name, po.payment_no 
            FROM refund_transactions rt
            LEFT JOIN merchants m ON rt.merchant_id = m.id
            LEFT JOIN payment_orders po ON rt.payment_order_id = po.id
            WHERE rt.id = $1
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0];
    },

    listQrPayments: async (page, limit) => {
        const offset = (page - 1) * limit;
        const query = `
            SELECT pq.id, pq.qr_token, pq.status as qr_status, pq.expired_at, pq.created_at, pq.used_at,
                   po.payment_no, po.amount, po.status as order_status, m.merchant_name
            FROM payment_qr_codes pq
            LEFT JOIN payment_orders po ON pq.payment_order_id = po.id
            LEFT JOIN merchants m ON po.merchant_id = m.id
            ORDER BY pq.created_at DESC
            LIMIT $1 OFFSET $2
        `;
        const countQuery = `SELECT COUNT(*) FROM payment_qr_codes`;

        const [itemsResult, countResult] = await Promise.all([
            pool.query(query, [limit, offset]),
            pool.query(countQuery)
        ]);

        return {
            items: itemsResult.rows,
            total: parseInt(countResult.rows[0].count, 10)
        };
    },

    getQrPaymentDetail: async (id) => {
        const query = `
            SELECT pq.*, po.payment_no, po.amount, po.status as order_status, po.merchant_id, m.merchant_name
            FROM payment_qr_codes pq
            LEFT JOIN payment_orders po ON pq.payment_order_id = po.id
            LEFT JOIN merchants m ON po.merchant_id = m.id
            WHERE pq.id = $1
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0];
    },

    expireQrPayments: async () => {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            // 1. Expire QR Codes that are ACTIVE, used_at is null and expired_at < NOW
            const expireQrQuery = `
                UPDATE payment_qr_codes
                SET status = 'EXPIRED', updated_at = NOW()
                WHERE status = 'ACTIVE' 
                  AND used_at IS NULL 
                  AND expired_at < NOW()
                RETURNING id, payment_order_id
            `;
            const qrResult = await client.query(expireQrQuery);
            const expiredQRs = qrResult.rows;

            let expiredOrdersCount = 0;

            if (expiredQRs.length > 0) {
                const orderIds = expiredQRs.map(qr => qr.payment_order_id).filter(id => id != null);
                
                if (orderIds.length > 0) {
                    // 2. Update payment_orders if they are still PENDING
                    const expireOrderQuery = `
                        UPDATE payment_orders
                        SET status = 'EXPIRED', updated_at = NOW()
                        WHERE id = ANY($1::uuid[]) AND status = 'PENDING'
                        RETURNING id
                    `;
                    const orderResult = await client.query(expireOrderQuery, [orderIds]);
                    expiredOrdersCount = orderResult.rowCount;
                }
            }

            await client.query('COMMIT');
            return {
                expired_qrs: expiredQRs.length,
                expired_orders: expiredOrdersCount
            };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }
};

module.exports = paymentsRepository;
