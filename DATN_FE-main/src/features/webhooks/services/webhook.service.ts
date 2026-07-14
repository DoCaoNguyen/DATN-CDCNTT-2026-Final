import { axiosInstance } from '../../../api/axios-instance';

export const webhookService = {
  getWebhooks: async (params: any) => {
    const response = await axiosInstance.get('/admin/webhooks', { params });
    return response.data;
  },
  
  getWebhookDetail: async (id: string) => {
    const response = await axiosInstance.get(`/admin/webhooks/${id}`);
    return response.data;
  },
  
  retryWebhook: async (id: string) => {
    const response = await axiosInstance.post(`/admin/webhooks/${id}/actions/retry`);
    return response.data;
  }
};
