import { axiosInstance } from '../../config/axios-instance';
import type { ApiResponse, MerchantDetail, CreateMerchantPayload, ConfigCallbackPayload } from '../../types';

export const merchantService = {
  getMerchants: async (search?: string, page?: number, limit?: number): Promise<ApiResponse<MerchantDetail[]>> => {
    const response = await axiosInstance.get<ApiResponse<MerchantDetail[]>>('/admin/merchants', { params: { search, page, limit } });
    return response.data;
  },

  getMerchantById: async (id: string): Promise<ApiResponse<MerchantDetail>> => {
    const response = await axiosInstance.get<ApiResponse<MerchantDetail>>(`/admin/merchants/${id}`);
    return response.data;
  },
  
  // 1. Đăng ký Merchant mới
  createMerchant: async (payload: CreateMerchantPayload): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>('/admin/merchants', payload);
    return response.data;
  },

  // 2. Cấp API Key (Tạo mới)
  generateApiKey: async (id: string, payload: { key_name: string; environment: string }): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/merchants/${id}/api-keys`, payload);
    return response.data;
  },

  getApiKeys: async (id: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.get<ApiResponse<any>>(`/admin/merchants/${id}/api-keys`);
    return response.data;
  },

  rotateApiKey: async (id: string, keyId: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/merchants/${id}/api-keys/${keyId}/actions/rotate`);
    return response.data;
  },

  revokeApiKey: async (id: string, keyId: string, reason: string = 'Admin thu hồi'): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/merchants/${id}/api-keys/${keyId}/actions/revoke`, { reason });
    return response.data;
  },

  // 3. Cấu hình Callback URL
  configCallback: async (id: string, payload: ConfigCallbackPayload): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.patch<ApiResponse<any>>(`/admin/merchants/${id}`, { callback: payload });
    return response.data;
  },

  approve: async (id: string, reason: string = 'Duyệt Merchant'): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/merchants/${id}/actions/approve`, { reason });
    return response.data;
  },
  
  reject: async (id: string, reason: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/merchants/${id}/actions/reject`, { reason });
    return response.data;
  },

  suspend: async (id: string, reason: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/merchants/${id}/actions/suspend`, { reason });
    return response.data;
  },
  
  activate: async (id: string, reason: string = 'Khôi phục Merchant'): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/merchants/${id}/actions/activate`, { reason });
    return response.data;
  },

  resendOnboardingEmail: async (userId: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/users/${userId}/actions/resend-onboarding`);
    return response.data;
  }
};
