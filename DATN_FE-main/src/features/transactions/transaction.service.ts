import { axiosInstance } from '../../config/axios-instance';


export const transactionService = {
  // Lấy danh sách toàn bộ giao dịch (Ledger Transactions)
  getTransactions: async (search?: string, type?: string, status?: string) => {
    const response = await axiosInstance.get('/admin/transactions/ledger', { 
      params: { q: search, type, status } 
    });
    return response.data;
  },

  // Tra cứu chi tiết dòng tiền (Debit/Credit) của 1 giao dịch
  getTransactionEntries: async (transactionId: string) => {
    // API chi tiết trả về luôn entries bên trong
    const response = await axiosInstance.get(`/admin/transactions/ledger/${transactionId}`);
    // Trả về mảng entries
    return response.data?.data?.entries || [];
  }
};
