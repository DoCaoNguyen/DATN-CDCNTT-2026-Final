import { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, Loader2, Lock, Unlock, RefreshCw, Wallet, Activity, MoreVertical } from 'lucide-react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { userService } from '../../features/user-management/user.service';
import { axiosInstance } from '../../config/axios-instance';
import { formatVND, formatDateTime, formatDisplayPhone } from '../../utils/formatters';
import { StatusBadge } from '../../components/ui/admin-components';

type Tab = 'info' | 'transactions' | 'wallet';

function useUserDetail(id: string) {
  return useQuery({
    queryKey: ['admin-user-detail', id],
    queryFn: async () => {
      const res = await axiosInstance.get(`/admin/users/${id}`);
      return res.data?.data || res.data;
    },
    enabled: !!id,
  });
}

function useUserWalletHistory(walletId?: string) {
  return useQuery({
    queryKey: ['admin-wallet-history', walletId],
    queryFn: async () => {
      if (!walletId) return [];
      const res = await axiosInstance.get(`/admin/wallets/${walletId}/ledger`, { params: { page: 1, limit: 10 } });
      return res.data?.items || res.data?.data?.items || res.data?.data || [];
    },
    enabled: !!walletId,
  });
}

function InfoRow({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="grid grid-cols-5 py-2.5 border-b border-gray-100 last:border-0">
      <span className="col-span-2 text-sm text-gray-500">{label}</span>
      <span className="col-span-3 text-sm text-gray-900 font-medium">{value ?? '—'}</span>
    </div>
  );
}

export default function UserDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<Tab>('info');
  const [isProcessing, setIsProcessing] = useState(false);
  const [confirmAction, setConfirmAction] = useState<null | 'lock' | 'unlock'>(null);
  const [reason, setReason] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);

  const { data: user, isLoading, refetch } = useUserDetail(id || '');
  const { data: historyData = [], isLoading: isLoadingHistory } = useUserWalletHistory(user?.wallet?.id);

  const handleLock = async () => {
    if (!reason.trim() || !id) return;
    setIsProcessing(true);
    try {
      await userService.lockUser(id, reason);
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['user-detail', id] });
      toast.success('Khoá tài khoản thành công!');
      setConfirmAction(null);
      setReason('');
      refetch();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Lỗi khi khoá tài khoản.');
    } finally { setIsProcessing(false); }
  };

  const handleUnlock = async () => {
    if (!reason.trim() || !id) return;
    setIsProcessing(true);
    try {
      await userService.unlockUser(id, reason);
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['user-detail', id] });
      toast.success('Mở khoá tài khoản thành công!');
      setConfirmAction(null);
      setReason('');
      refetch();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Lỗi khi mở khoá tài khoản.');
    } finally { setIsProcessing(false); }
  };

  const initials = (name?: string) => {
    if (!name) return 'U';
    return name.split(' ').map(w => w[0]).slice(-2).join('').toUpperCase();
  };

  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    { key: 'info', label: 'Thông tin', icon: Activity },
    { key: 'transactions', label: 'Lịch sử GD', icon: Activity },
    { key: 'wallet', label: 'Ví', icon: Wallet },
  ];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-6 h-6 animate-spin text-blue-600" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="px-6 py-10 text-center text-gray-500">
        <p>Không tìm thấy người dùng.</p>
        <button onClick={() => navigate('/admin/users')} className="mt-4 text-blue-600 text-sm underline">
          Quay lại danh sách
        </button>
      </div>
    );
  }

  const isLocked = user.status === 'LOCKED';

  return (
    <div className="flex-1 px-6 pt-0 pb-10 space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/admin/users')}
            className="flex items-center justify-center w-8 h-8 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-gray-600" />
          </button>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-semibold text-sm">
              {initials(user.full_name)}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold text-gray-900">{user.full_name}</h1>
                <StatusBadge status={user.status} />
              </div>
              <p className="text-xs font-mono text-gray-400">{formatDisplayPhone(user.phone)}</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="relative">
          <button
            onClick={() => setMenuOpen((p) => !p)}
            className="flex items-center gap-1 px-3 py-2 border border-gray-200 rounded-md text-sm hover:bg-gray-50 transition-colors"
          >
            <MoreVertical className="w-4 h-4" />
          </button>
          {menuOpen && (
            <div className="absolute right-0 mt-1 w-44 bg-white border border-gray-200 rounded-md shadow-lg z-20 py-1">
              {isLocked ? (
                <button
                  onClick={() => { setConfirmAction('unlock'); setMenuOpen(false); }}
                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-emerald-700 hover:bg-emerald-50"
                >
                  <Unlock className="w-3.5 h-3.5" /> Mở khoá
                </button>
              ) : (
                <button
                  onClick={() => { setConfirmAction('lock'); setMenuOpen(false); }}
                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-orange-700 hover:bg-orange-50"
                >
                  <Lock className="w-3.5 h-3.5" /> Khoá tài khoản
                </button>
              )}
              {/* Reset PIN — TODO: chờ API admin reset PIN */}
              <button
                disabled
                title="Tính năng đang phát triển"
                className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-400 cursor-not-allowed"
              >
                <RefreshCw className="w-3.5 h-3.5" /> Reset PIN (TODO)
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <div className="flex gap-0">
          {tabs.map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setTab(key)}
              className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
                tab === key
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-800'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Tab Content */}
      {tab === 'info' && (
        <div className="bg-white border border-gray-200 rounded-lg p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-3">Thông tin cá nhân</h3>
          <InfoRow label="Họ và tên" value={user.full_name} />
          <InfoRow label="Số điện thoại" value={formatDisplayPhone(user.phone)} />
          <InfoRow label="Email" value={user.email} />
          <InfoRow label="Loại tài khoản" value={user.user_type} />
          <InfoRow label="KYC" value={user.is_kyc_verified ? '✅ Đã xác minh' : '❌ Chưa xác minh'} />
          <InfoRow label="Đăng nhập lần cuối" value={user.last_login_at ? formatDateTime(user.last_login_at) : undefined} />
          <InfoRow label="Ngày tạo" value={user.created_at ? formatDateTime(user.created_at) : undefined} />
        </div>
      )}

      {tab === 'transactions' && (
        <div className="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
          <div className="p-5 border-b border-slate-100 flex items-center justify-between">
            <h3 className="text-lg font-bold text-slate-800">Lịch sử giao dịch (Sao kê ví)</h3>
          </div>
          {isLoadingHistory ? (
            <div className="p-10 flex justify-center"><Loader2 className="w-6 h-6 animate-spin text-blue-600" /></div>
          ) : historyData.length === 0 ? (
            <div className="p-10 text-center text-gray-500">Người dùng này chưa có giao dịch nào.</div>
          ) : (
            <div className="overflow-x-auto w-full">
              <table className="w-full text-left border-collapse whitespace-nowrap">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-sm font-semibold text-slate-600">
                    <th className="p-4">Thời gian</th>
                    <th className="p-4">Loại GD</th>
                    <th className="p-4">Mã tham chiếu</th>
                    <th className="p-4 text-right">Biến động</th>
                    <th className="p-4 text-right">Số dư sau GD</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-sm">
                  {historyData.map((entry: any) => (
                    <tr key={entry.id} className="hover:bg-slate-50">
                      <td className="p-4 text-slate-600 text-xs font-mono">{formatDateTime(entry.created_at)}</td>
                      <td className="p-4 font-semibold text-slate-700">{entry.transaction_type || '—'}</td>
                      <td className="p-4">
                        <span className="px-2 py-1 bg-slate-100 text-slate-600 rounded font-mono text-xs">
                          {entry.transaction_no || entry.transaction_id || entry.id}
                        </span>
                      </td>
                      <td className={`p-4 text-right font-bold ${entry.entry_type === 'CREDIT' || entry.direction === 'CREDIT' ? 'text-emerald-600' : 'text-red-600'}`}>
                        {entry.entry_type === 'CREDIT' || entry.direction === 'CREDIT' ? '+' : '-'}{formatVND(entry.amount)}
                      </td>
                      <td className="p-4 text-right font-semibold text-slate-800">{formatVND(entry.balance_after ?? entry.post_balance ?? 0)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="p-4 bg-slate-50 border-t border-slate-200 text-center">
                <Link to={`/admin/wallets/${user.wallet.id}`} className="text-blue-600 hover:underline text-sm font-medium">
                  Xem toàn bộ tại Quản lý Ví →
                </Link>
              </div>
            </div>
          )}
        </div>
      )}

      {tab === 'wallet' && (
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <Wallet className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-slate-800">Thông tin ví điện tử</h3>
              <p className="text-sm text-slate-500">Mã ví: <span className="font-mono text-slate-700">{user.wallet?.wallet_no || 'Chưa có'}</span></p>
            </div>
          </div>
          
          <div className="bg-slate-50 rounded-xl p-5 mb-6 border border-slate-100">
            <p className="text-sm text-slate-500 mb-1">Số dư khả dụng</p>
            <p className="text-3xl font-bold text-emerald-600">
              {user.wallet ? formatVND(user.wallet.available_balance || 0) : '0 ₫'}
            </p>
          </div>

          <div className="space-y-1 mb-6">
            <InfoRow label="Trạng thái ví" value={user.wallet ? <StatusBadge status={user.wallet.status} /> : '—'} />
            <InfoRow label="Đơn vị tiền tệ" value={user.wallet?.currency || 'VND'} />
          </div>

          <Link
            to={`/admin/wallets/${user.wallet.id}`}
            className="inline-flex items-center justify-center px-4 py-2 border border-blue-600 text-blue-600 font-medium rounded-md hover:bg-blue-50 transition-colors"
          >
            Đi đến Quản lý Ví
          </Link>
        </div>
      )}

      {/* Confirm dialog: Lock / Unlock */}
      {confirmAction && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-xl">
            <div className="px-6 py-4 border-b border-gray-100">
              <h3 className="text-base font-semibold text-gray-900">
                {confirmAction === 'lock' ? 'Khoá tài khoản' : 'Mở khoá tài khoản'}
              </h3>
              <p className="text-sm text-gray-500 mt-0.5">Người dùng: <strong>{user.full_name}</strong></p>
            </div>
            <div className="px-6 py-4">
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                Lý do <span className="text-red-500">*</span>
              </label>
              <textarea
                rows={3}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Nhập lý do..."
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <button
                onClick={() => { setConfirmAction(null); setReason(''); }}
                className="px-4 py-2 text-sm text-gray-700 border border-gray-200 rounded-md hover:bg-gray-100"
              >
                Hủy
              </button>
              <button
                onClick={confirmAction === 'lock' ? handleLock : handleUnlock}
                disabled={!reason.trim() || isProcessing}
                className={`px-4 py-2 text-sm text-white rounded-md font-medium disabled:opacity-50 flex items-center gap-1.5 ${
                  confirmAction === 'lock' ? 'bg-orange-500 hover:bg-orange-600' : 'bg-emerald-600 hover:bg-emerald-700'
                }`}
              >
                {isProcessing && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                {confirmAction === 'lock' ? 'Xác nhận khoá' : 'Xác nhận mở khoá'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
