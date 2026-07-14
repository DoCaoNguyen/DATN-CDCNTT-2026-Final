import { useState } from 'react';
import { PageHeader } from '../../../components/common/page-header';
import { ErrorState } from '../../../components/common/error-state';
import { TransactionTable } from '../components/transaction-table';
import { TransactionFilters } from '../components/transaction-filters';
import { TransactionDetailDialog } from '../components/transaction-detail-dialog';
import { useTransactions } from '../hooks/use-transactions';
import type { Transaction, TransactionQueryParams } from '../types/transaction.type';

export default function TransactionManagementPage() {
  const [filters, setFilters] = useState<TransactionQueryParams>({
    search: '',
    type: '',
    status: '',
  });

  const [selectedTx, setSelectedTx] = useState<Transaction | null>(null);

  const { data: transactions = [], isLoading, isError, error, refetch } = useTransactions(filters);

  const handleFilterChange = (newFilters: TransactionQueryParams) => {
    setFilters(newFilters);
  };

  return (
    <div className="w-full max-w-7xl mx-auto pb-10 space-y-6 animate-in fade-in duration-500">
      <PageHeader 
        title="Quản lý Giao dịch & Ledger" 
        description="Giám sát toàn bộ luồng tiền. Dữ liệu kế toán không thể sửa xóa."
      />

      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200">
        <TransactionFilters 
          initialFilters={filters} 
          onFilterChange={handleFilterChange} 
        />
      </div>

      {isError ? (
        <ErrorState 
          error={error?.message || 'Có lỗi xảy ra khi tải dữ liệu giao dịch'} 
          onRetry={() => refetch()} 
        />
      ) : (
        <TransactionTable 
          transactions={transactions} 
          isLoading={isLoading} 
          onViewDetails={setSelectedTx} 
        />
      )}

      <TransactionDetailDialog 
        transaction={selectedTx} 
        open={!!selectedTx} 
        onClose={() => setSelectedTx(null)} 
      />
    </div>
  );
}
