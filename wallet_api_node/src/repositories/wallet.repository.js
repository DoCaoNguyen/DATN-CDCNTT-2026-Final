const walletRepository = {
    // Nhận 'client' từ Service truyền xuống
    create: async (client, userId) => {
        const query = `INSERT INTO wallets (user_id) VALUES ($1)`;
        await client.query(query, [userId]);
    }
};

module.exports = walletRepository;