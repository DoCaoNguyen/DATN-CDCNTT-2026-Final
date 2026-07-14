import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, User2, Lock, Unlock, Loader2 } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { axiosInstance } from '../../config/axios-instance';
import { userService } from '../../features/user-management/user.service';
import {
  AdminTable, PageShell, SearchBar, FilterSelect, StatusBadge,
} from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { ActionMenu, ActionMenuItem } from '../../components/ui/action-menu';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import toast from 'react-hot-toast';
import type { ColumnDef } from '@tanstack/react-table';
import { formatVND, formatDateTime } from '../../utils/formatters';

const STATUS_OPTIONS = [
  { value: 'ACTIVE', label: 'Hoạt động' },
  { value: 'PENDING_VERIFY', label: 'Chờ xác minh' },
  { value: 'LOCKED', label: 'Đã khoá' },
];

function useWalletUsers(params: any) {
  return useQuery({
    queryKey: ['admin-wallet-users', params],
    queryFn: async () => {
      const res = await axiosInstance.get('/admin/users', {
        // user_type=USER để chỉ lấy người dùng ví, không lấy staff/admin
        params: { page: params.page, limit: params.limit, q: params.search, status: params.status, user_type: 'USER' },
      });
      return res.data?.data || res.data;
    },
  });
}

export default function UserManage() {
  const navigate = useNavigate();
  const { params, setQueryParams } = useApiQueryParams();
  const { data, isLoading, refetch } = useWalletUsers(params);

  const [confirmAction, setConfirmAction] = useState<null | { type: 'lock' | 'unlock'; user: any }>(null);
  const [reason, setReason] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  const items = data?.items ?? (Array.isArray(data) ? data : []);
  const total = data?.pagination?.total ?? data?.total ?? 0;
  const totalPages = data?.pagination ? Math.ceil(total / params.limit) : (data?.total_pages ?? 1);

  const handleLock = async () => {
    if (!reason.trim() || !confirmAction) return;
    setIsProcessing(true);
    try {
      await userService.lockUser(confirmAction.user.id, reason);
      toast.success('Đã khoá tài khoản');
      setConfirmAction(null); setReason('');
      refetch();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Lỗi khi khoá tài khoản.');
    } finally { setIsProcessing(false); }
  };

  const handleUnlock = async () => {
    if (!reason.trim() || !confirmAction) return;
    setIsProcessing(true);
    try {
      await userService.unlockUser(confirmAction.user.id, reason);
      toast.success('Đã mở khoá tài khoản');
      setConfirmAction(null); setReason('');
      refetch();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Lỗi khi mở khoá.');
    } finally { setIsProcessing(false); }
  };

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'full_name',
      header: 'Người dùng',
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-gray-900">{row.original.full_name}</p>
          {row.original.email && <p className="text-xs text-gray-400">{row.original.email}</p>}
        </div>
      ),
    },
    {
      accessorKey: 'phone',
      header: 'Số điện thoại',
      cell: ({ row }) => {
        let displayPhone = row.original.phone || '';
        if (displayPhone.startsWith('+84')) {
          displayPhone = '0' + displayPhone.slice(3);
        } else if (displayPhone.startsWith('84')) {
          displayPhone = '0' + displayPhone.slice(2);
        }

        return <span className="text-sm font-medium text-gray-800">{displayPhone}</span>;
      },
    },
    {
      id: 'wallet',
      header: 'Mã ví',
      cell: ({ row }) => (
        <span className="text-sm font-mono text-gray-700">
          {row.original.wallet?.wallet_no || '—'}
        </span>
      ),
    },
    {
      id: 'balance',
      header: 'Số dư',
      cell: ({ row }) => (
        <span className="text-sm font-semibold text-gray-800">
          {row.original.wallet ? formatVND(row.original.wallet.available_balance || 0) : '—'}
        </span>
      ),
    },
    {
      accessorKey: 'is_kyc_verified',
      header: 'KYC',
      cell: ({ getValue }) => (
        <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${getValue() ? 'bg-green-50 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
          {getValue() ? 'Đã xác minh' : 'Chưa xác minh'}
        </span>
      ),
    },
    {
      accessorKey: 'status',
      header: 'Trạng thái',
      cell: ({ getValue }) => <StatusBadge status={getValue<string>()} />,
    },
    {
      accessorKey: 'created_at',
      header: 'Ngày tạo',
      cell: ({ getValue }) => <span className="text-sm text-gray-500">{formatDateTime(getValue<string>())}</span>,
    },
    {
      id: 'actions',
      header: () => <div className="text-center">Thao tác</div>,
      cell: ({ row }) => {
        const user = row.original;
        const isLocked = user.status === 'LOCKED';
        return (
          <div className="flex justify-center">
            <ActionMenu>
              <ActionMenuItem 
                icon={<User2 className="w-4 h-4" />} 
                label="Xem chi tiết" 
                onClick={() => navigate(`/admin/users/${user.id}`)} 
              />
              {isLocked ? (
                <ActionMenuItem 
                  icon={<Unlock className="w-4 h-4" />} 
                  label="Mở khoá" 
                  onClick={() => setConfirmAction({ type: 'unlock', user })} 
                />
              ) : (
                <ActionMenuItem 
                  icon={<Lock className="w-4 h-4" />} 
                  label="Khoá" 
                  onClick={() => setConfirmAction({ type: 'lock', user })} 
                  danger
                />
              )}
            </ActionMenu>
          </div>
        );
      },
    },
  ], [navigate]);

  return (
    <PageShell
      title="Người dùng ví"
      description="Quản lý tài khoản người dùng ví điện tử. Xác thực bằng SĐT + OTP + PIN."
      actions={
        <Button onClick={() => navigate('/admin/users/create')}>
          <Plus className="w-4 h-4 mr-2" /> Thêm người dùng
        </Button>
      }
    >
      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tên, số điện thoại, email..."
        />
        <FilterSelect
          value={params.status || ''}
          onChange={(v) => setQueryParams({ status: v, page: 1 })}
          options={STATUS_OPTIONS}
          placeholder="Trạng thái"
        />
      </div>

      <AdminTable
        columns={columns}
        data={items}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={totalPages}
        onPageChange={(p) => setQueryParams({ page: p })}
        onLimitChange={(l) => setQueryParams({ limit: l, page: 1 })}
        emptyIcon={<User2 className="w-10 h-10 text-gray-300 mx-auto" />}
        emptyText="Chưa có người dùng ví nào"
      />

      {/* Confirm Lock/Unlock Dialog */}
      {confirmAction && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-xl">
            <div className="px-6 py-4 border-b">
              <h3 className="text-base font-semibold text-gray-900">
                {confirmAction.type === 'lock' ? 'Khoá tài khoản' : 'Mở khoá tài khoản'}
              </h3>
              <p className="text-sm text-gray-500 mt-0.5">
                Người dùng: <strong>{confirmAction.user.full_name}</strong>
              </p>
            </div>
            <div className="px-6 py-4">
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                Lý do <span className="text-red-500">*</span>
              </label>
              <textarea
                rows={3} value={reason} onChange={(e) => setReason(e.target.value)}
                placeholder="Nhập lý do..."
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <Button variant="outline" onClick={() => { setConfirmAction(null); setReason(''); }}>
                Hủy
              </Button>
              <Button
                variant={confirmAction.type === 'lock' ? 'danger' : 'primary'}
                onClick={confirmAction.type === 'lock' ? handleLock : handleUnlock}
                disabled={!reason.trim() || isProcessing}
              >
                {isProcessing && <Loader2 className="w-3.5 h-3.5 animate-spin mr-1.5" />}
                {confirmAction.type === 'lock' ? 'Xác nhận khoá' : 'Xác nhận mở khoá'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </PageShell>
  );
}