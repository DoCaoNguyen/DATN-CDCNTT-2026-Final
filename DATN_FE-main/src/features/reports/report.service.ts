import { axiosInstance } from '../../config/axios-instance';

export const reportService = {
  getTopups: async (params: any) => {
    const res = await axiosInstance.get('/admin/reports/topups', { params });
    return res.data;
  },
  getTransfers: async (params: any) => {
    const res = await axiosInstance.get('/admin/reports/transfers', { params });
    return res.data;
  },
  getPayments: async (params: any) => {
    const res = await axiosInstance.get('/admin/reports/payments', { params });
    return res.data;
  },
  getRefunds: async (params: any) => {
    const res = await axiosInstance.get('/admin/reports/refunds', { params });
    return res.data;
  },
  getMerchants: async (params: any) => {
    const res = await axiosInstance.get('/admin/reports/merchants', { params });
    return res.data;
  },
  getFees: async (params: any) => {
    const res = await axiosInstance.get('/admin/reports/fees', { params });
    return res.data;
  },
  exportData: async (params: any) => {
    const res = await axiosInstance.get('/admin/reports/export', {
      params,
      responseType: 'blob'
    });
    return res.data;
  }
};
