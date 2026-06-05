const walletRepository = require('../repositories/wallet.repository');

const walletService = {
    getWalletInfo: async (userId) => {
        const wallet = await walletRepository.getBalanceByUserId(userId);
        
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }

        // Chuyển BigInt thành String để tránh lỗi khi res.json trả về
        return {
            wallet_code: wallet.wallet_code,
            currency: wallet.currency,
            status: wallet.status,
            available_balance: wallet.available_balance ? wallet.available_balance.toString() : "0",
            locked_balance: wallet.locked_balance ? wallet.locked_balance.toString() : "0"
        };
    }
};

module.exports = walletService;