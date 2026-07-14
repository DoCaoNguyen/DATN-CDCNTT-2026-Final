import { axiosInstance } from '../../../api/axios-instance';

export const ledgerService = {
  getLedgerTransactions: async (params: any) => {
    const response = await axiosInstance.get('/admin/transactions/ledger', { params });
    return response.data;
  },
  getLedgerTransactionDetail: async (id: string) => {
    const response = await axiosInstance.get(`/admin/transactions/ledger/${id}`);
    return response.data;
  }
};
