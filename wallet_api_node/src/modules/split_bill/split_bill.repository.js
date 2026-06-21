const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const splitBillRepository = {
    createBill: async (creatorId, totalAmount, splitAmount, note, client) => {
        const id = uuidv7();
        const query = `
            INSERT INTO split_bills (id, creator_id, total_amount, split_amount, note)
            VALUES ($1, $2, $3, $4, $5) RETURNING id
        `;
        const res = await client.query(query, [id, creatorId, totalAmount, splitAmount, note]);
        return res.rows[0].id;
    },

    createMember: async (billId, userId, amount, status, paidAt, client) => {
        const id = uuidv7();
        const query = `
            INSERT INTO split_bill_members (id, split_bill_id, user_id, amount, status, paid_at)
            VALUES ($1, $2, $3, $4, $5, $6)
        `;
        await client.query(query, [id, billId, userId, amount, status, paidAt]);
    },

    getReceivablesByCreatorId: async (userId) => {
        const query = `
            SELECT sb.id, sb.total_amount, sb.split_amount, sb.note, sb.status, sb.created_at,
                COALESCE(
                    json_agg(
                        json_build_object(
                            'id', sbm.id,
                            'user_id', sbm.user_id,
                            'name', u.full_name,
                            'phone', u.phone,
                            'avatar', NULL,
                            'amount', sbm.amount,
                            'status', sbm.status,
                            'paid_at', sbm.paid_at
                        )
                    ) FILTER (WHERE sbm.id IS NOT NULL), '[]'
                ) as members
            FROM split_bills sb
            LEFT JOIN split_bill_members sbm ON sb.id = sbm.split_bill_id
            LEFT JOIN users u ON sbm.user_id = u.id
            WHERE sb.creator_id = $1 AND sb.status != 'CANCELLED'
            GROUP BY sb.id
            ORDER BY sb.created_at DESC
        `;
        const res = await pool.query(query, [userId]);
        return res.rows;
    },

    getPayablesByUserId: async (userId) => {
        const query = `
            SELECT sb.id as split_bill_id, sb.total_amount, sb.split_amount, sb.note, sb.created_at,
                   sbm.id as member_record_id, sbm.amount as my_amount, sbm.status as my_status,
                   c.id as creator_id, c.full_name as creator_name, c.phone as creator_phone, NULL as creator_avatar
            FROM split_bills sb
            JOIN split_bill_members sbm ON sb.id = sbm.split_bill_id
            JOIN users c ON sb.creator_id = c.id
            WHERE sbm.user_id = $1 AND sb.creator_id != $1 AND sbm.status != 'CANCELLED' AND sb.status != 'CANCELLED'
            ORDER BY sb.created_at DESC
        `;
        const res = await pool.query(query, [userId]);
        return res.rows;
    },

    getMemberRecordWithCreatorInfo: async (memberRecordId, userId) => {
        const query = `
            SELECT sbm.*, sb.creator_id, c.phone as creator_phone
            FROM split_bill_members sbm
            JOIN split_bills sb ON sbm.split_bill_id = sb.id
            JOIN users c ON sb.creator_id = c.id
            WHERE sbm.id = $1 AND sbm.user_id = $2
        `;
        const res = await pool.query(query, [memberRecordId, userId]);
        return res.rows[0];
    },

    updateMemberStatusToPaid: async (memberRecordId) => {
        await pool.query(
            `UPDATE split_bill_members SET status = 'PAID', paid_at = CURRENT_TIMESTAMP WHERE id = $1`,
            [memberRecordId]
        );
    },

    checkPendingMembersAndCompleteBill: async (billId) => {
        const checkQuery = `
            SELECT COUNT(*) as pending_count 
            FROM split_bill_members 
            WHERE split_bill_id = $1 AND status != 'PAID'
        `;
        const checkRes = await pool.query(checkQuery, [billId]);
        if (parseInt(checkRes.rows[0].pending_count) === 0) {
            await pool.query(`UPDATE split_bills SET status = 'COMPLETED' WHERE id = $1`, [billId]);
        }
    },

    cancelBill: async (billId, creatorId) => {
        const query = `
            UPDATE split_bills SET status = 'CANCELLED' 
            WHERE id = $1 AND creator_id = $2
        `;
        const res = await pool.query(query, [billId, creatorId]);
        if (res.rowCount > 0) {
            const query2 = `
                UPDATE split_bill_members SET status = 'CANCELLED'
                WHERE split_bill_id = $1 AND status = 'PENDING'
            `;
            await pool.query(query2, [billId]);
        }
    },

    getPendingMembers: async (billId, creatorId) => {
        const q1 = await pool.query('SELECT id, total_amount, split_amount FROM split_bills WHERE id=$1 AND creator_id=$2', [billId, creatorId]);
        if (q1.rows.length === 0) return [];
        
        const q2 = await pool.query('SELECT user_id, amount FROM split_bill_members WHERE split_bill_id = $1 AND status = $2', [billId, 'PENDING']);
        return q2.rows;
    }
};

module.exports = splitBillRepository;
