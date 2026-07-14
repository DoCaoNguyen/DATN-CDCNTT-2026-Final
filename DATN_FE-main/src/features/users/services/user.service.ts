import { axiosInstance } from '../../../api/axios-instance';
import type { User, UserQueryParams } from '../types/user.type';
import type { CreateUserFormValues, ResetPasswordFormValues } from '../schemas/user.schema';

export const userService = {
  getUsers: async (params?: UserQueryParams): Promise<{ items: User[], total: number }> => {
    // Ép Backend trả về toàn bộ danh sách (để limit 1000) giống code cũ để xử lý phân trang client
    const response = await axiosInstance.get('/admin/users', { 
      params: { 
        search: params?.search, 
        page: 1, 
        limit: 1000 
      } 
    });
    const payload = response.data?.data || response.data;
    const rawData = Array.isArray(payload?.items) ? payload.items : (Array.isArray(payload) ? payload : []);
    
    // LỌC: Bỏ hết Admin/Merchant, chỉ giữ lại Khách hàng (USER)
    const allCustomers = rawData.filter((u: any) => u.user_type === 'USER' || u.roles?.includes('USER'));
    
    // Phân trang ở client
    // TODO: Chuyển sang server-side pagination/filter khi backend hỗ trợ api phân trang thực sự cho user
    const page = params?.page || 1;
    const limit = params?.limit || 10;
    const startIndex = (page - 1) * limit;
    const paginatedCustomers = allCustomers.slice(startIndex, startIndex + limit);

    return { 
      items: paginatedCustomers, 
      total: allCustomers.length 
    };
  },

  createWalletUser: async (payload: CreateUserFormValues) => {
    // Lưu ý: Endpoint cũ là /admin/customers. Cần kiểm tra lại backend nếu có thay đổi.
    const response = await axiosInstance.post('/admin/customers', payload);
    return response.data;
  },

  lockUser: async (userId: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/users/${userId}/actions/lock`, { reason });
    return response.data;
  },

  unlockUser: async (userId: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/users/${userId}/actions/unlock`, { reason });
    return response.data;
  },

  resetPassword: async (userId: string, payload: ResetPasswordFormValues) => {
    const response = await axiosInstance.post(`/admin/users/${userId}/actions/reset-password`, payload);
    return response.data;
  }
};
