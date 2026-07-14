import { axiosInstance } from '../../../api/axios-instance';
import type { Merchant, MerchantQueryParams } from '../types/merchant.type';
import type { CreateMerchantFormValues, ConfigWebhookFormValues } from '../schemas/merchant.schema';

export const merchantService = {
  getMerchants: async (params?: MerchantQueryParams): Promise<{ items: Merchant[], total: number }> => {
    // Frontend pagination similar to users if backend doesn't support it yet
    const response = await axiosInstance.get('/admin/merchants', { 
      params: { search: params?.search } 
    });
    
    const payload = response.data?.data || response.data;
    const rawData = Array.isArray(payload?.items) ? payload.items : (Array.isArray(payload) ? payload : []);
    
    // Pagination
    const page = params?.page || 1;
    const limit = params?.limit || 10;
    const startIndex = (page - 1) * limit;
    const paginatedMerchants = rawData.slice(startIndex, startIndex + limit);

    return { 
      items: paginatedMerchants, 
      total: rawData.length 
    };
  },

  createMerchant: async (payload: CreateMerchantFormValues) => {
    const payloadToSend = {
      merchant_code: payload.merchant_code,
      merchant_name: payload.merchant_name,
      business_type: payload.business_type,
      email: payload.email,
      phone: payload.phone,
      callback: (payload.callback?.default_callback_url || payload.callback?.default_redirect_url) ? payload.callback : undefined,
      owner: payload.create_owner ? payload.owner : undefined,
      create_default_api_key: payload.create_default_api_key
    };
    const response = await axiosInstance.post('/admin/merchants', payloadToSend);
    return response.data;
  },

  generateApiKey: async (merchantId: string) => {
    const response = await axiosInstance.post(`/admin/merchants/${merchantId}/api-keys`, { 
      key_name: 'Default Key', 
      environment: 'SANDBOX' 
    });
    return response.data;
  },

  configWebhook: async (merchantId: string, payload: ConfigWebhookFormValues) => {
    const response = await axiosInstance.patch(`/admin/merchants/${merchantId}`, { callback: payload });
    return response.data;
  },

  approveMerchant: async (merchantId: string) => {
    const response = await axiosInstance.post(`/admin/merchants/${merchantId}/actions/approve`, { reason: 'Duyệt Merchant' });
    return response.data;
  },

  rejectMerchant: async (merchantId: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/merchants/${merchantId}/actions/reject`, { reason });
    return response.data;
  },

  suspendMerchant: async (merchantId: string, reason: string) => {
    const response = await axiosInstance.post(`/admin/merchants/${merchantId}/actions/suspend`, { reason });
    return response.data;
  },

  activateMerchant: async (merchantId: string) => {
    const response = await axiosInstance.post(`/admin/merchants/${merchantId}/actions/activate`, { reason: 'Khôi phục Merchant' });
    return response.data;
  }
};
