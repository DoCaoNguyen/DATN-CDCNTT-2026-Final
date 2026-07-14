export interface UserWallet {
  wallet_no?: string;
  available_balance?: number;
}

export interface User {
  id: string;
  username: string;
  full_name: string;
  phone: string;
  email?: string;
  user_type: string;
  status: 'ACTIVE' | 'LOCKED' | 'SUSPENDED' | string;
  created_at: string;
  last_login_at?: string;
  wallet?: UserWallet;
  roles?: string[];
}

export interface UserQueryParams {
  search?: string;
  page?: number;
  limit?: number;
}
