const pool = require('../../config/db');
const splitBillRepository = require('./split_bill.repository');
const txService = require('../transaction/transaction.service');
const notificationService = require('../notification/notification.service');

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
    },

    remindBill: async (creatorId, billId) => {
        const members = await splitBillRepository.getPendingMembers(billId, creatorId);
        if (!members || members.length === 0) return;
        
        for (const member of members) {
             if (member.user_id) {
                 await notificationService.sendBalanceChangeNotification(
                     member.user_id,
                     member.amount,
                     'TRANSFER_RECEIVE', // Dùng tạm TRANSFER_RECEIVE để mượn Push Notif có chuông hoặc tạo Type mới
                     null,
                     'Yêu cầu thanh toán khoản tiền chia'
                 ).catch(console.error);
             }
        }
    },

    cancelBill: async (creatorId, billId) => {
        await splitBillRepository.cancelBill(billId, creatorId);
    }
};

module.exports = splitBillService;
