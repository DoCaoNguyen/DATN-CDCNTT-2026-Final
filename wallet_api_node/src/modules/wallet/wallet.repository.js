
const pool = require('../../config/db');
const { v7: uuidv7 } = require('uuid');

const walletRepository = {
    
    create: async (client, userId) => {
        const newId = uuidv7();
        const walletNo = `WAL${Date.now().toString().slice(-9)}`;
        const query = `
            INSERT INTO wallets (id, user_id, wallet_no, wallet_code)
            VALUES ($1, $2, $3, $4)
        `;
        await client.query(query, [newId, userId, walletNo, walletNo]);
        await client.query(
            `INSERT INTO wallet_balances (wallet_id, available_balance, locked_balance)
             VALUES ($1, 0, 0)
             ON CONFLICT (wallet_id) DO NOTHING`,
            [newId]
        );
        return newId;
    },

    findByUserId: async (userId) => {
        
        const query = `SELECT id FROM wallets WHERE user_id = $1`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getBalanceByUserId: async (userId) => {
        const query = `
            SELECT 
                w.id AS wallet_id,
                w.wallet_no,
                COALESCE(w.wallet_code, u.phone) AS wallet_code, 
                w.currency, 
                w.status, 
                wb.available_balance, 
                wb.locked_balance,
                wb.updated_at,
                u.phone,
                u.pin_hash
            FROM wallets w
            LEFT JOIN wallet_balances wb ON w.id = wb.wallet_id
            LEFT JOIN users u ON w.user_id = u.id
            WHERE w.user_id = $1
        `;
        
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    updatePinHash: async (userId, pinHash) => {
        const query = `
            UPDATE users 
            SET pin_hash = $1 
            WHERE id = $2 
            RETURNING pin_hash;
        `;
        const result = await pool.query(query, [pinHash, userId]);
        return result.rows[0];
    },

    updateWalletCode: async (userId, walletCode) => {
        const query = `
            UPDATE wallets 
            SET wallet_code = $1 
            WHERE user_id = $2 
            RETURNING wallet_code;
        `;
        const result = await pool.query(query, [walletCode, userId]);
        return result.rows[0]; 
    },

    getUserInfoForQR: async (userId) => {
        const query = `SELECT full_name, phone FROM users WHERE id = $1`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getLinkedBanks: async (walletId) => {
        const query = `
            SELECT id, bank_name, bank_code, card_number, card_holder_name, status, created_at
            FROM wallet_linked_banks
            WHERE wallet_id = $1 AND status = 'ACTIVE'
            ORDER BY created_at DESC
        `;
        const result = await pool.query(query, [walletId]);
        return result.rows;
    },

    linkBank: async (walletId, bankName, bankCode, cardNumber, cardHolderName) => {
        const newId = uuidv7();
        const query = `
            INSERT INTO wallet_linked_banks (id, wallet_id, bank_name, bank_code, card_number, card_holder_name, status)
            VALUES ($1, $2, $3, $4, $5, $6, 'ACTIVE')
            RETURNING id, bank_name, bank_code, card_number, card_holder_name, status
        `;
        const result = await pool.query(query, [newId, walletId, bankName, bankCode, cardNumber, cardHolderName]);
        return result.rows[0];
    }
};

module.exports = walletRepository;
