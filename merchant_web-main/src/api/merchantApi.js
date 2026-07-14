import axiosClient from './axiosClient';

export const merchantApi = {
  // Dashboard
  getBalance: () => axiosClient.get('/merchant/balance').then(res => res.data),
  
  getPaymentOrders: (params = { page: 1, limit: 5 }) => 
    axiosClient.get('/merchant/payment-orders', { params }).then(res => res.data),
    
  getTransactions: (params = { page: 1, limit: 5 }) => 
    axiosClient.get('/merchant/transactions', { params }).then(res => res.data),
    
  getWebhooks: (params = { page: 1, limit: 5 }) => 
    axiosClient.get('/merchant/webhooks', { params }).then(res => res.data),

  // Phase 5 Additions
  getWebhookById: (id) => axiosClient.get('/merchant/webhooks/' + id).then(res => res.data),
  retryWebhook: (id) => axiosClient.post('/merchant/webhooks/' + id + '/retry').then(res => res.data),
  getPaymentOrderById: (id) => axiosClient.get('/merchant/payment-orders/' + id).then(res => res.data),
  getTransactionById: (id) => axiosClient.get('/merchant/transactions/' + id).then(res => res.data),
  getStatement: (params = { page: 1, limit: 5 }) => axiosClient.get('/merchant/balance/statement', { params }).then(res => res.data),
  // API Keys
  getApiKeys: () => axiosClient.get('/merchant/api-keys').then(res => res.data),
  
  createApiKey: (data) => axiosClient.post('/merchant/api-keys', data).then(res => res.data),
  
  rotateSecret: (keyId) => axiosClient.post(`/merchant/api-keys/${keyId}/actions/rotate-secret`).then(res => res.data),
  
  revokeKey: (keyId) => axiosClient.post(`/merchant/api-keys/${keyId}/actions/revoke`).then(res => res.data),
};
