import { axiosInstance } from '../../../api/axios-instance';

export const paymentOrderService = {
  getPaymentOrders: async (params: any) => {
    const response = await axiosInstance.get('/admin/payments/payment-orders', { params });
    return response.data;
  },

  getPaymentOrderDetail: async (id: string) => {
    const response = await axiosInstance.get(`/admin/payments/payment-orders/${id}`);
    return response.data;
  },

  getPaymentTimeline: async (id: string) => {
    const response = await axiosInstance.get(`/admin/payments/payment-orders/${id}/timeline`);
    return response.data;
  },

  getPaymentLedger: async (id: string) => {
    const response = await axiosInstance.get(`/admin/payments/payment-orders/${id}/ledger`);
    return response.data;
  },

  getPaymentCallbacks: async (id: string) => {
    const response = await axiosInstance.get(`/admin/payments/payment-orders/${id}/callbacks`);
    return response.data;
  },
};

export const qrPaymentService = {
  getQrPayments: async (params: any) => {
    const response = await axiosInstance.get('/admin/payments/qr-payments', { params });
    return response.data;
  },

  getQrPaymentDetail: async (id: string) => {
    const response = await axiosInstance.get(`/admin/payments/qr-payments/${id}`);
    return response.data;
  },

  expireQrJob: async () => {
    const response = await axiosInstance.post('/admin/payments/qr-payments/jobs/expire');
    return response.data;
  },
};
