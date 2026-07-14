import { axiosInstance } from '../../config/axios-instance';

export const kycService = {
  getKycList: async (page: number = 1, limit: number = 10, status: string = '') => {
    const res = await axiosInstance.get('/admin/kyc', {
      params: { page, limit, status }
    });
    return res.data;
  },

  getKycDetails: async (id: string) => {
    const res = await axiosInstance.get(`/admin/kyc/${id}`);
    return res.data;
  },

  approveKyc: async (id: string) => {
    const res = await axiosInstance.put(`/admin/kyc/${id}/approve`);
    return res.data;
  },

  rejectKyc: async (id: string) => {
    const res = await axiosInstance.put(`/admin/kyc/${id}/reject`);
    return res.data;
  }
};
