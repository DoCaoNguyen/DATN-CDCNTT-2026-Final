import { useState } from 'react';
import { PageHeader } from '../../../components/common/page-header';
import { ErrorState } from '../../../components/common/error-state';
import { WalletFilters } from '../components/wallet-filters';
import { WalletTable } from '../components/wallet-table';
import { WalletDetailView } from '../components/wallet-detail-view';
import { WalletActionDialog } from '../components/wallet-action-dialog';
import { useWallets } from '../hooks/use-wallets';
import { useLockWallet, useUnlockWallet } from '../hooks/use-wallet-actions';
import type { WalletQueryParams, Wallet } from '../types/wallet.type';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import toast from 'react-hot-toast';

export default function WalletManagementPage() {
  const [filters, setFilters] = useState<WalletQueryParams>({ search: '', page: 1, limit: 10 });
  const [selectedWallet, setSelectedWallet] = useState<Wallet | null>(null);
  
  // Action Dialog state
  const [actionWallet, setActionWallet] = useState<Wallet | null>(null);
  const [actionType, setActionType] = useState<'LOCK' | 'UNLOCK' | null>(null);

  const { data, isLoading, isError, error, refetch } = useWallets(filters);
  const wallets = data?.items || [];
  const total = data?.total || 0;
  const totalPages = Math.ceil(total / (filters.limit || 10)) || 1;

  const lockMutation = useLockWallet();
  const unlockMutation = useUnlockWallet();

  const handleActionConfirm = (walletId: string, reason?: string) => {
    if (actionType === 'LOCK') {
      lockMutation.mutate({ walletId, reason: reason || 'Locked by admin' }, {
        onSuccess: () => {
          toast.success('Khóa ví thành công');
          setActionWallet(null);
          setActionType(null);
        },
        onError: () => {
          toast.error('Lỗi khi khóa ví. Vui lòng thử lại.');
        }
      });
    } else if (actionType === 'UNLOCK') {
      unlockMutation.mutate(walletId, {
        onSuccess: () => {
          toast.success('Mở khóa ví thành công');
          setActionWallet(null);
          setActionType(null);
        },
        onError: () => {
          toast.error('Lỗi khi mở khóa ví. Vui lòng thử lại.');
        }
      });
    }
  };

  // Render detail view if a wallet is selected
  if (selectedWallet) {
    return (
      <div className="w-full max-w-7xl mx-auto pb-10">
        <WalletDetailView wallet={selectedWallet} onBack={() => setSelectedWallet(null)} />
      </div>
    );
  }

  return (
    <div className="w-full max-w-7xl mx-auto pb-10 space-y-6 animate-in fade-in duration-500">
      <PageHeader 
        title="Quản lý Ví điện tử" 
        description="Kiểm soát trạng thái và xem chi tiết dòng tiền (Ledger) của từng ví."
      />

      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200">
        <WalletFilters initialFilters={filters} onFilterChange={setFilters} />
      </div>

      {isError ? (
        <ErrorState 
          error={error?.message || 'Có lỗi xảy ra khi tải danh sách ví'} 
          onRetry={() => refetch()} 
        />
      ) : (
        <div className="space-y-4">
          <WalletTable 
            wallets={wallets} 
            isLoading={isLoading} 
            onViewDetails={setSelectedWallet} 
            onAction={(wallet, action) => {
              setActionWallet(wallet);
              setActionType(action);
            }} 
          />
          
          {totalPages > 1 && (
            <div className="flex justify-center items-center space-x-4 pt-2">
              <button 
                disabled={filters.page === 1} 
                onClick={() => setFilters(prev => ({ ...prev, page: (prev.page || 1) - 1 }))} 
                className="px-4 py-2 rounded-lg border bg-white text-slate-600 hover:bg-slate-100 disabled:opacity-50 text-sm font-semibold flex items-center shadow-sm"
              >
                <ChevronLeft className="w-4 h-4 mr-1" /> Trước
              </button>
              <span className="text-sm font-semibold text-slate-700">Trang {filters.page} / {totalPages}</span>
              <button 
                disabled={filters.page! >= totalPages} 
                onClick={() => setFilters(prev => ({ ...prev, page: (prev.page || 1) + 1 }))} 
                className="px-4 py-2 rounded-lg border bg-white text-slate-600 hover:bg-slate-100 disabled:opacity-50 text-sm font-semibold flex items-center shadow-sm"
              >
                Sau <ChevronRight className="w-4 h-4 ml-1" />
              </button>
            </div>
          )}
        </div>
      )}

      <WalletActionDialog 
        wallet={actionWallet}
        action={actionType}
        open={!!actionWallet}
        onClose={() => {
          setActionWallet(null);
          setActionType(null);
        }}
        onConfirm={handleActionConfirm}
        isProcessing={lockMutation.isPending || unlockMutation.isPending}
      />
    </div>
  );
}
