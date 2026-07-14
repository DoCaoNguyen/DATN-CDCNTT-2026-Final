import { axiosInstance } from '../../config/axios-instance';

export const roleService = {
  getRoles: async () => {
    const response = await axiosInstance.get('/admin/roles');
    return response.data;
  },
  
  createRole: async (data: { code?: string, name: string, description: string, permissions: string[] }) => {
    const payload = {
      ...data,
      code: data.code || (data.name || '').toUpperCase().replace(/\s+/g, '_')
    };
    const response = await axiosInstance.post('/admin/roles', payload);
    return response.data;
  },

  updateRole: async (id: string, data: { name: string, description: string, permissions: string[] }) => {
    const response = await axiosInstance.patch(`/admin/roles/${id}`, data);
    return response.data;
  },

  deleteRole: async (id: string) => {
    const response = await axiosInstance.delete(`/admin/roles/${id}`);
    return response.data;
  },

  getPermissions: async () => {
    const response = await axiosInstance.get('/admin/permissions');
    return response.data;
  }
};
