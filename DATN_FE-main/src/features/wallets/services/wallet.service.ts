import { axiosInstance } from '../../../api/axios-instance';
import type { WalletQueryParams, Wallet, WalletSummary, WalletLedgerEntry } from '../types/wallet.type';

export const walletService = {
  getWallets: async (params?: WalletQueryParams): Promise<{ items: Wallet[], total: number }> => {
    const response = await axiosInstance.get('/admin/wallets', { 
      params: { 
        search: params?.search, 
        page: params?.page || 1, 
        limit: params?.limit || 1000 
      } 
    });
    const payload = response.data?.data || response.data;
    const items = Array.isArray(payload?.items) ? payload.items : (Array.isArray(payload) ? payload : []);
    
    // Fallback filter out valid wallets as old code did
    const validWallets = items.filter((w: any) => w.wallet_no);
    return { items: validWallets, total: payload?.total || validWallets.length };
  },

  getWalletSummary: async (walletId: string): Promise<WalletSummary> => {
    const response = await axiosInstance.get(`/admin/wallets/${walletId}/summary`);
    return response.data?.data || response.data;
  },

  getWalletLedger: async (walletId: string, page: number = 1, limit: number = 50): Promise<WalletLedgerEntry[]> => {
    const response = await axiosInstance.get(`/admin/wallets/${walletId}/ledger`, { params: { page, limit } });
    const payload = response.data?.data || response.data;
    return Array.isArray(payload?.items) ? payload.items : (Array.isArray(payload) ? payload : []);
  },

  lockWallet: async (walletId: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/wallets/${walletId}/actions/lock`, { reason });
    return response.data;
  },

  unlockWallet: async (walletId: string) => {
    const response = await axiosInstance.post(`/admin/wallets/${walletId}/actions/unlock`);
    return response.data;
  }
};
