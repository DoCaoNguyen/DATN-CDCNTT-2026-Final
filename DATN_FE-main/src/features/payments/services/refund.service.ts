import { axiosInstance } from '../../../api/axios-instance';

export const refundService = {
  getRefunds: async (params: any) => {
    const response = await axiosInstance.get('/admin/payments/refunds', { params });
    return response.data;
  },
  
  getRefundDetail: async (id: string) => {
    const response = await axiosInstance.get(`/admin/payments/refunds/${id}`);
    return response.data;
  }
};
