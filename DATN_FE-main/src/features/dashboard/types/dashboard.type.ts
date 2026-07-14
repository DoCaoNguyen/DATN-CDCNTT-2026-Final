export interface ChartData {
  time: string;
  amount: number;
}

export interface RecentTransaction {
  status: 'SUCCESS' | 'FAILED' | 'PENDING' | string;
  transaction_type: string;
  transaction_no: string;
  amount: number;
  created_at: string;
}

export interface DashboardKpis {
  total_users: number;
  total_merchants: number;
  total_transactions: number;
  total_amount: number;
  error_rate: number;
  chart_data: ChartData[];
  recent_transactions: RecentTransaction[];
}
