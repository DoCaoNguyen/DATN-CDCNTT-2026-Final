export interface Merchant {
  id: string;
  merchant_code: string;
  merchant_name: string;
  business_type: string;
  status: 'PENDING' | 'PENDING_REVIEW' | 'ACTIVE' | 'SUSPENDED' | 'REJECTED' | string;
  email?: string;
  phone?: string;
  api_key?: string;
  default_callback_url?: string;
  default_redirect_url?: string;
  created_at?: string;
}

export interface MerchantQueryParams {
  search?: string;
  page?: number;
  limit?: number;
}
