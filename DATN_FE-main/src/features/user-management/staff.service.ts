import { axiosInstance } from '../../config/axios-instance';

// Service riêng cho Staff/Admin — không dùng chung userService
// Backend không có GET /admin/staffs riêng, dùng GET /admin/users với filter user_type
export const staffService = {
  getStaffs: async (search?: string, page = 1, limit = 10, type?: string) => {
    // Lấy tất cả loại staff từ endpoint users với lọc theo user_type (CSV)
    // Repository BE hỗ trợ tách CSV thành mảng và dùng = ANY(::user_type[])
    const user_type = type || 'SUPPORT_STAFF,ADMIN,SUPER_ADMIN';
    const res = await axiosInstance.get('/admin/users', {
      params: { q: search, page, limit, user_type },
    });
    return res.data?.data || res.data;
  },

  getStaffDetail: async (id: string) => {
    const res = await axiosInstance.get(`/admin/users/${id}`);
    return res.data?.data || res.data;
  },

  createStaff: async (payload: {
    username: string;
    full_name: string;
    email?: string;
    phone?: string;
    role_codes: string[];
  }) => {
    const response = await axiosInstance.post('/admin/staffs', payload);
    return response.data;
  },

  lockStaff: async (id: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/users/${id}/actions/lock`, { reason });
    return response.data;
  },

  unlockStaff: async (id: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/users/${id}/actions/unlock`, { reason });
    return response.data;
  },

  // Reset mật khẩu admin (staff dùng username/password)
  resetStaffPassword: async (id: string, payload: {
    new_password: string;
    confirm_new_password: string;
    reason: string;
  }) => {
    const response = await axiosInstance.post(`/admin/users/${id}/actions/reset-password`, payload);
    return response.data;
  },

  updateStaff: async (id: string, payload: {
    full_name?: string;
    username?: string;
    email?: string;
    phone?: string;
  }) => {
    const response = await axiosInstance.patch(`/admin/users/${id}`, payload);
    return response.data;
  },

  resendOnboardingEmail: async (id: string) => {
    const response = await axiosInstance.post(`/admin/users/${id}/actions/resend-onboarding`);
    return response.data;
  }
};
