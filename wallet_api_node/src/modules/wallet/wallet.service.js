const walletRepository = require('./wallet.repository');

const walletService = {
    getWalletInfo: async (userId) => {
        const wallet = await walletRepository.getBalanceByUserId(userId);
        
        if (!wallet) {
            throw new Error('Wallet_Not_Found');
        }

        return {
            wallet_code: wallet.wallet_code,
            currency: wallet.currency,
            status: wallet.status,
            available_balance: wallet.available_balance ? wallet.available_balance.toString() : "0",
            locked_balance: wallet.locked_balance ? wallet.locked_balance.toString() : "0"
        };
    },

    setWalletCode: async (userId, walletCode) => {
        
        const formattedCode = walletCode.trim().toLowerCase();

        try {
            
            const result = await walletRepository.updateWalletCode(userId, formattedCode);
            
            if (!result) {
                throw new Error('Wallet_Not_Found');
            }
            
            return result.wallet_code;

        } catch (error) {
            
            if (error.code === '23505') {
                throw new Error('Wallet_Code_Exists');
            }
            throw error; 
        }
    },

    checkWalletCodeInfo: async (walletCode) => {
        const cleanCode = walletCode.trim();

        const walletInfo = await walletRepository.checkByWalletCode(cleanCode);
        
        if (!walletInfo) {
            throw new Error('Wallet_Code_Not_Found');
        }

        return {
            wallet_code: walletInfo.wallet_code,
            full_name: walletInfo.full_name,
            status: walletInfo.status
        };
    }
};

module.exports = walletService;