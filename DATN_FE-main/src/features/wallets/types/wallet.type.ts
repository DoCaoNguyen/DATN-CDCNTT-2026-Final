export interface Wallet {
  id: string;
  wallet_no: string;
  status: 'ACTIVE' | 'LOCKED' | 'CLOSED' | string;
  created_at: string;
  user?: {
    full_name: string;
    phone: string;
  };
  full_name?: string;
  phone?: string;
  balance?: {
    available_balance: number;
    locked_balance: number;
  };
  available_balance?: number;
  locked_balance?: number;
}

export interface WalletSummary {
  wallet?: {
    wallet_no: string;
  };
  owner?: {
    full_name: string;
  };
  balance?: {
    available_balance: number;
  };
  stats?: {
    topup_success_amount: number;
    transfer_sent_amount: number;
    payment_amount: number;
    refund_amount: number;
  };
}

export interface WalletLedgerEntry {
  ledger_entry_id?: string;
  id?: string;
  created_at: string;
  transaction_no: string;
  transaction_type: string;
  entry_type: 'CREDIT' | 'DEBIT';
  amount: number;
  balance_before: number;
  balance_after: number;
}

export interface WalletQueryParams {
  search?: string;
  page?: number;
  limit?: number;
}
