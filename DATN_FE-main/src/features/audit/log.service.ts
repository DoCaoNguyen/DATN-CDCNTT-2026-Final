import { axiosInstance } from '../../config/axios-instance';

export const logService = {
  // Lấy danh sách Audit Logs
  getAuditLogs: async (search?: string) => {
    const response = await axiosInstance.get('/admin/logs/api', { params: { search } });
    return response.data;
  },

  // Lấy danh sách System Logs
  getSystemLogs: async (search?: string) => {
    const response = await axiosInstance.get('/admin/logs/system', { params: { search } });
    return response.data;
  }
};
