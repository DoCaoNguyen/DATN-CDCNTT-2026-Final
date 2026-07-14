export interface LedgerEntry {
  id: string;
  wallet_id: string;
  direction: 'DEBIT' | 'CREDIT';
  amount: number;
  post_balance: number;
  description: string;
  created_at: string;
}

export interface Transaction {
  id: string;
  trans_code: string;
  trans_type: 'TOPUP' | 'TRANSFER' | 'PAYMENT' | 'REFUND' | string;
  amount: number;
  status: 'PENDING' | 'SUCCESS' | 'FAILED' | 'REVERSED' | string;
  description: string;
  source_id: string;
  created_at: string;
}

export interface TransactionQueryParams {
  search?: string;
  type?: string;
  status?: string;
}
