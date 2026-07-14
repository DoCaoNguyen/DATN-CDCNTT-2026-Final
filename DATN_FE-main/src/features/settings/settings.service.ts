import { axiosInstance } from '../../config/axios-instance';

export const settingsService = {
  getSettings: async () => {
    const response = await axiosInstance.get('/admin/settings');
    return response.data;
  },

  updateSetting: async (key: string, value: any) => {
    const response = await axiosInstance.patch(`/admin/settings/${key}`, { setting_value: value });
    return response.data;
  },

  getHistory: async (key: string, params: any) => {
    const response = await axiosInstance.get('/admin/settings/history', { 
      params: { key, ...params } 
    });
    return response.data;
  }
};
