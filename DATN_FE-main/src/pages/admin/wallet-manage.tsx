import { useEffect, useState, useMemo } from 'react';
import { Lock, Unlock, Loader2, Eye } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { ConfirmDialog } from '../../components/common/confirm-dialog';
import { walletService } from '../../features/wallet-management/wallet.service';
import { formatVND, formatDateTime, getStatusVariant } from '../../utils/formatters';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { AdminTable, PageShell } from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { SearchFilterBar } from '../../components/organisms/filters/search-filter-bar';
import { ActionMenu, ActionMenuItem } from '../../components/ui/action-menu';
import type { ColumnDef } from '@tanstack/react-table';

export default function WalletManage() {
  const [wallets, setWallets] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const navigate = useNavigate();
  
  const { params, setQueryParams } = useApiQueryParams();

  const [lockingWallet, setLockingWallet] = useState<any | null>(null);
  const [lockReason, setLockReason] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [confirmState, setConfirmState] = useState<{ open: boolean; id: string; message: string }>({ open: false, id: '', message: '' });


  const fetchWallets = async () => {
    setIsLoading(true);
    try {
      // Backend ko hỗ trợ search/pagination hoàn chỉnh nên lấy full và filter frontend
      const res = await walletService.getWallets(params.search, 1, 1000);
      const rawData = res?.data?.items || res?.items || res?.data || res;
      if (Array.isArray(rawData)) {
        let validWallets = rawData.filter(w => w.wallet_no);
        
        // Frontend search filter
        if (params.search) {
          const s = params.search.toLowerCase();
          validWallets = validWallets.filter(w => 
            w.wallet_no?.toLowerCase().includes(s) || 
            w.user?.full_name?.toLowerCase().includes(s) ||
            w.user?.phone?.includes(s)
          );
        }

        setTotal(validWallets.length);
        setWallets(validWallets.slice((params.page - 1) * params.limit, params.page * params.limit));
      } else {
        setWallets([]); setTotal(0);
      }
    } catch { 
      setWallets([]); setTotal(0); 
    } finally { 
      setIsLoading(false); 
    }
  };


  useEffect(() => {
    fetchWallets();
  }, [params.page, params.limit, params.search]);

  const handleConfirmUnlock = async () => {
    if (!confirmState.id) return;
    setIsProcessing(true);
    try {
      const res = await walletService.unlockWallet(confirmState.id);
      if (res?.success || res) {
        setWallets((prev) => prev.map(w => w.id === confirmState.id ? { ...w, status: 'ACTIVE' } : w));
        toast.success('Mở khóa ví thành công!');
      }
    } catch { 
      toast.error('Lỗi khi mở khóa'); 
    } finally { 
      setIsProcessing(false); 
      setConfirmState({ open: false, id: '', message: '' });
    }
  };

  const submitLock = async () => {
    if (!lockingWallet || !lockReason.trim()) return;
    setIsProcessing(true);
    try {
      const res = await walletService.lockWallet(lockingWallet.id, lockReason);
      if (res?.success || res) {
        setWallets((prev) => prev.map(w => w.id === lockingWallet.id ? { ...w, status: 'LOCKED' } : w));
        setLockingWallet(null); setLockReason('');
        toast.success('Khóa ví thành công!');
      }
    } catch {
      toast.error('Lỗi khi khóa ví');
    } finally { setIsProcessing(false); }
  };

  const columns = useMemo<ColumnDef<any>[]>(
    () => [
      {
        accessorKey: 'wallet_no',
        header: 'Mã Ví',
        cell: ({ row }) => (
          <div>
            <p className="font-bold text-slate-800 text-sm cursor-pointer hover:text-blue-600 transition-colors" onClick={() => navigate(`/admin/wallets/${row.original.id}`)}>
              {row.original.wallet_no}
            </p>
            <p className="text-xs text-slate-500">{formatDateTime(row.original.created_at)}</p>
          </div>
        )
      },
      {
        id: 'owner',
        header: 'Chủ sở hữu',
        cell: ({ row }) => {
          let displayPhone = row.original.user?.phone || row.original.phone || 'N/A';
          if (displayPhone.startsWith('+84')) {
            displayPhone = '0' + displayPhone.slice(3);
          } else if (displayPhone.startsWith('84')) {
            displayPhone = '0' + displayPhone.slice(2);
          }
          return (
            <div>
              <p className="font-semibold text-slate-700">{row.original.user?.full_name || row.original.full_name || 'N/A'}</p>
              <p className="text-xs text-slate-500">{displayPhone}</p>
            </div>
          );
        }
      },
      {
        accessorKey: 'wallet_type',
        header: 'Loại ví',
        cell: ({ row }) => <span className="text-gray-700 font-medium">{row.original.wallet_type || 'N/A'}</span>,
      },
      {
        id: 'available_balance',
        header: 'Số dư khả dụng',
        cell: ({ row }) => {
          const av = row.original.balance?.available_balance ?? row.original.available_balance ?? 0;
          return <span className="font-bold text-emerald-600">{formatVND(av)}</span>;
        }
      },
      {
        id: 'locked_balance',
        header: 'Số dư khóa',
        cell: ({ row }) => {
          const blocked = row.original.balance?.locked_balance ?? row.original.locked_balance ?? row.original.balance?.blocked_balance ?? row.original.blocked_balance ?? 0;
          return <span className="font-semibold text-orange-500">{formatVND(blocked)}</span>;
        }
      },
      {
        accessorKey: 'status',
        header: 'Trạng thái',
        cell: ({ row }) => {
          const actualStatus = row.original.status;
          const userStatus = row.original.user?.status;
          const effectiveStatus = (actualStatus === 'ACTIVE' && userStatus === 'PENDING_VERIFY') 
            ? 'PENDING_VERIFY' 
            : actualStatus;
          const v = getStatusVariant(effectiveStatus);
          return <span className={`px-2 py-1 rounded text-xs font-bold ${v.className}`}>{v.label}</span>;
        }
      },
      {
        id: 'actions',
        header: () => <div className="text-center">Thao tác</div>,
        cell: ({ row }) => (
          <div className="flex justify-center">
            <ActionMenu>
              <ActionMenuItem 
                icon={<Eye className="w-4 h-4" />} 
                label="Xem chi tiết" 
                onClick={() => navigate(`/admin/wallets/${row.original.id}`)} 
              />
              {row.original.status === 'ACTIVE' ? (
                <ActionMenuItem 
                  icon={<Lock className="w-4 h-4" />} 
                  label="Khóa" 
                  onClick={() => setLockingWallet(row.original)}
                  danger 
                />
              ) : (
                <ActionMenuItem 
                  icon={<Unlock className="w-4 h-4" />} 
                  label="Mở khóa" 
                  onClick={() => setConfirmState({ open: true, id: row.original.id, message: 'Bạn có chắc chắn muốn mở khóa ví này?' })} 
                />
              )}
            </ActionMenu>
          </div>
        )
      }
    ],
    []
  );



  return (
    <PageShell
      title="Quản lý Ví điện tử"
      description="Quản lý trạng thái và tra cứu lịch sử biến động ví người dùng."
    >
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 flex justify-end">
        <SearchFilterBar 
          searchPlaceholder="Mã ví, tên, sđt..."
          searchValue={params.search}
          onSearchChange={(val) => setQueryParams({ search: val, page: 1 })}
        />
      </div>

      <AdminTable 
        columns={columns}
        data={wallets}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={Math.ceil(total / params.limit) || 1}
        onPageChange={(page) => setQueryParams({ page })}
        onLimitChange={(limit) => setQueryParams({ limit, page: 1 })}
      />

      {lockingWallet && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md overflow-hidden shadow-2xl">
            <div className="p-6 border-b border-slate-100">
              <h3 className="text-lg font-bold text-slate-800">Khóa Ví</h3>
              <p className="text-sm text-slate-500 mt-1">Ví: <span className="font-bold text-slate-700">{lockingWallet.wallet_no}</span></p>
            </div>
            <div className="p-6">
              <label className="block text-sm font-semibold text-slate-700 mb-2">Lý do khóa (Đóng băng) <span className="text-red-500">*</span></label>
              <textarea rows={3} value={lockReason} onChange={(e) => setLockReason(e.target.value)} className="w-full p-3 border rounded-xl focus:ring-2 focus:ring-orange-500/20 outline-none resize-none text-sm" />
            </div>
            <div className="p-4 bg-slate-50 flex justify-end space-x-3">
              <Button variant="ghost" onClick={() => { setLockingWallet(null); setLockReason(''); }}>Hủy bỏ</Button>
              <Button variant="danger" onClick={submitLock} disabled={!lockReason.trim() || isProcessing}>
                {isProcessing && <Loader2 className="w-4 h-4 mr-2 animate-spin" />} Xác nhận khóa
              </Button>
            </div>
          </div>
        </div>
      )}
      <ConfirmDialog 
        open={confirmState.open} 
        title="Xác nhận mở khóa"
        description={confirmState.message}
        onClose={() => setConfirmState({ ...confirmState, open: false })}
        onConfirm={handleConfirmUnlock}
        isLoading={isProcessing}
        variant="primary"
      />
    </PageShell>
  );
}