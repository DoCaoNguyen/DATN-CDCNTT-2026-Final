import { axiosInstance } from '../../config/axios-instance';
import type { ApiResponse, LoginPayload, LoginResponseData } from '../../types';

export const authService = {
  // Hàm gọi API /auth/login
  login: async (payload: LoginPayload): Promise<ApiResponse<LoginResponseData>> => {
    const response = await axiosInstance.post<ApiResponse<LoginResponseData>>('/auth/login', payload);
    return response.data; // Trả thẳng data đã định dạng về cho giao diện
  },

  // Đổi mật khẩu
  changePassword: async (payload: any) => {
    const response = await axiosInstance.post('/auth/change-password', payload);
    return response.data;
  },
};
