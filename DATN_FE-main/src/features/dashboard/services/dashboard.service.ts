import { axiosInstance } from '../../../api/axios-instance';
import type { DashboardKpis } from '../types/dashboard.type';

export const dashboardService = {
  getKpis: async (): Promise<DashboardKpis> => {
    // Gọi đến API dashboard cũ
    const response = await axiosInstance.get('/admin/dashboard/kpis');
    // Backend trả về data lồng nhau (response.data.data hoặc response.data)
    return response.data?.data || response.data;
  },
};
