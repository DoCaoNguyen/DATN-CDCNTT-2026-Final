import { axiosInstance } from '../../../api/axios-instance';
import type { Transaction, LedgerEntry, TransactionQueryParams } from '../types/transaction.type';

export const transactionService = {
  getTransactions: async (params?: TransactionQueryParams): Promise<Transaction[]> => {
    const response = await axiosInstance.get('/admin/transactions/ledger', { 
      params: { 
        q: params?.search, 
        type: params?.type, 
        status: params?.status 
      } 
    });
    const payload = response.data?.data || response.data;
    return Array.isArray(payload?.items) ? payload.items : (Array.isArray(payload) ? payload : []);
  },

  getTransactionEntries: async (transactionId: string): Promise<LedgerEntry[]> => {
    const response = await axiosInstance.get(`/admin/transactions/ledger/${transactionId}`);
    return response.data?.data?.entries || [];
  }
};
