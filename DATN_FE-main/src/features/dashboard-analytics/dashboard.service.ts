import { axiosInstance } from '../../config/axios-instance';
import type { ApiResponse, DashboardKpis } from '../../types';

export const dashboardService = {
  // Lấy chỉ số KPI tổng quan[cite: 9, 10, 11]
  getKpis: async (): Promise<ApiResponse<DashboardKpis>> => {
    const response = await axiosInstance.get<ApiResponse<DashboardKpis>>('/admin/dashboard/kpis');
    return response.data;
  },
};
