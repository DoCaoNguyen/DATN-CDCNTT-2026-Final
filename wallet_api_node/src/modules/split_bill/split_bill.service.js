const pool = require('../../config/db');
const splitBillRepository = require('./split_bill.repository');
const txService = require('../transaction/transaction.service');

const splitBillService = {
    createBill: async (creatorId, totalAmount, splitAmount, note, members, includeMe) => {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            
            const billId = await splitBillRepository.createBill(creatorId, totalAmount, splitAmount, note, client);

            for (const member of members) {
                await splitBillRepository.createMember(billId, member.user_id, member.amount, 'PENDING', null, client);
            }
            
            if (includeMe) {
                await splitBillRepository.createMember(billId, creatorId, splitAmount, 'PAID', new Date(), client);
            }

            await client.query('COMMIT');
            return billId;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    },

    getBillsForUser: async (userId) => {
        const receivables = await splitBillRepository.getReceivablesByCreatorId(userId);
        const payables = await splitBillRepository.getPayablesByUserId(userId);
        return { receivables, payables };
    },

    payBill: async (userId, memberRecordId, pin) => {
        const record = await splitBillRepository.getMemberRecordWithCreatorInfo(memberRecordId, userId);
        if (!record) {
            throw new Error('Split bill record not found');
        }

        if (record.status === 'PAID') {
            throw new Error('Already paid');
        }

        let amountBigInt;
        try {
            amountBigInt = BigInt(Math.floor(record.amount));
        } catch (e) {
            throw new Error('Invalid amount format');
        }

        await txService.transfer(
            userId,
            record.creator_phone, // receiver_identifier
            amountBigInt,
            "Thanh toán khoản chia tiền",
            null,
            pin
        );

        await splitBillRepository.updateMemberStatusToPaid(memberRecordId);
        await splitBillRepository.checkPendingMembersAndCompleteBill(record.split_bill_id);
    }
};

module.exports = splitBillService;
