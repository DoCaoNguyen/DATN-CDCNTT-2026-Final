
const pool = require('../../config/db');

const walletRepository = {
    
    create: async (client, userId) => {
        const query = `INSERT INTO wallets (user_id) VALUES ($1)`;
        await client.query(query, [userId]);
    },

    findByUserId: async (userId) => {
        
        const query = `SELECT id FROM wallets WHERE user_id = $1`;
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    },

    getBalanceByUserId: async (userId) => {
        const query = `
            SELECT 
                w.wallet_code, 
                w.currency, 
                w.status, 
                wb.available_balance, 
                wb.locked_balance 
            FROM wallets w
            LEFT JOIN wallet_balances wb ON w.id = wb.wallet_id
            WHERE w.user_id = $1
        `;
        
        const result = await pool.query(query, [userId]);
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
    }
    
};

module.exports = walletRepository;