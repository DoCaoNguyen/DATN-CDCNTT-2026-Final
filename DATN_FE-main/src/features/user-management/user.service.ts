import { axiosInstance } from '../../config/axios-instance';
import type { ApiResponse, UserDetail } from '../../types';

export const userService = {
  getUsers: async (search?: string, page: number = 1, limit: number = 10): Promise<ApiResponse<UserDetail[]>> => {
    const response = await axiosInstance.get<ApiResponse<UserDetail[]>>('/admin/users', {
      params: { search, page, limit }
    });
    return response.data;
  },

  createUser: async (payload: { full_name: string; phone: string; email?: string }) => {
    const response = await axiosInstance.post('/admin/users', payload);
    return response.data;
  },

  createStaff: async (payload: any) => {
    const response = await axiosInstance.post('/admin/staffs', payload);
    return response.data;
  },

  lockUser: async (userId: string, reason: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/users/${userId}/actions/lock`, { reason });
    return response.data;
  },

  // ĐÃ SỬA: Thêm tham số reason và truyền vào body của request POST
  unlockUser: async (userId: string, reason: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/users/${userId}/actions/unlock`, { reason });
    return response.data;
  },

  resetPassword: async (userId: string, payload: { new_password: string; confirm_new_password: string; reason: string }): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/users/${userId}/actions/reset-password`, payload);
    return response.data;
  },

  updateRoles: async (userId: string, roles: string[]): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.put<ApiResponse<any>>(`/admin/users/${userId}/roles`, { roles });
    return response.data;
  }
};
