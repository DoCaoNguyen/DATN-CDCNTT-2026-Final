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

    getPersonalQR: async (userId, amount, note) => {
        const user = await walletRepository.getUserInfoForQR(userId);
        if (!user) {
            throw new Error('User_Not_Found');
        }

        let qrContent = `viwallet://transfer?phone=${encodeURIComponent(user.phone || '')}&name=${encodeURIComponent(user.full_name || '')}`;
        if (amount) {
            qrContent += `&amount=${amount}`;
        }
        if (note) {
            qrContent += `&note=${encodeURIComponent(note)}`;
        }

        const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=400x400&ecc=L&data=${encodeURIComponent(qrContent)}`;

        return {
            phone: user.phone,
            full_name: user.full_name,
            amount: amount ? amount.toString() : null,
            note: note || null,
            qr_content: qrContent,
            qr_image_url: qrImageUrl
        };
    }
};

module.exports = walletService;