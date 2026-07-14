import { axiosInstance } from '../../config/axios-instance';

export const walletService = {
  getWallets: async (search?: string, page: number = 1, limit: number = 1000) => {
    const response = await axiosInstance.get('/admin/wallets', { params: { search, page, limit } });
    return response.data;
  },

  lockWallet: async (walletId: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/wallets/${walletId}/actions/lock`, { reason });
    return response.data;
  },

  unlockWallet: async (walletId: string) => {
    const response = await axiosInstance.post(`/admin/wallets/${walletId}/actions/unlock`);
    return response.data;
  },

  // THÊM: API Lấy tổng quan dòng tiền của 1 ví
  getWalletSummary: async (walletId: string) => {
    const response = await axiosInstance.get(`/admin/wallets/${walletId}/summary`);
    return response.data;
  },

  // THÊM: API Lấy sổ cái (sao kê) của 1 ví
  getWalletLedger: async (walletId: string, page: number = 1, limit: number = 50) => {
    const response = await axiosInstance.get(`/admin/wallets/${walletId}/ledger`, { params: { page, limit } });
    return response.data;
  }
};
