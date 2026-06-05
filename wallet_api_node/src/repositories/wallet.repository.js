// --- THÊM DÒNG NÀY ĐỂ KHAI BÁO POOL ---
const pool = require('../config/db');

const walletRepository = {
    // Nhận 'client' từ Service truyền xuống
    create: async (client, userId) => {
        const query = `INSERT INTO wallets (user_id) VALUES ($1)`;
        await client.query(query, [userId]);
    },

    findByUserId: async (userId) => {
        // Bây giờ đã có biến pool được khai báo ở trên
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
        // Bây giờ đã có biến pool được khai báo ở trên
        const result = await pool.query(query, [userId]);
        return result.rows[0];
    }
};

module.exports = walletRepository;