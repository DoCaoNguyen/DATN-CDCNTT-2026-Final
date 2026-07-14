import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Loader2, Lock, Unlock, KeyRound, Shield, MoreVertical, Edit } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { staffService } from '../../features/user-management/staff.service';
import { formatVND, formatDateTime, formatDisplayPhone } from '../../utils/formatters';
import { StatusBadge } from '../../components/ui/admin-components';

type Tab = 'info' | 'permissions';

function useStaffDetail(id: string) {
  return useQuery({
    queryKey: ['admin-staff-detail', id],
    queryFn: () => staffService.getStaffDetail(id),
    enabled: !!id,
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

export default function StaffDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>('info');
  const [isProcessing, setIsProcessing] = useState(false);
  const [confirmAction, setConfirmAction] = useState<null | 'lock' | 'unlock' | 'reset-pw' | 'edit'>(null);
  const [reason, setReason] = useState('');
  const [resetForm, setResetForm] = useState({ new_password: '', confirm_new_password: '', reason: '' });
  const [editForm, setEditForm] = useState({ full_name: '', username: '', email: '', phone: '' });
  const [menuOpen, setMenuOpen] = useState(false);

  const { data: staff, isLoading, refetch } = useStaffDetail(id || '');

  const handleLock = async () => {
    if (!reason.trim() || !id) return;
    setIsProcessing(true);
    try {
      await staffService.lockStaff(id, reason);
      setConfirmAction(null); setReason('');
      toast.success('Khóa tài khoản thành công!');
      refetch();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Lỗi khi khoá tài khoản.');
    } finally { setIsProcessing(false); }
  };

  const handleUnlock = async () => {
    if (!reason.trim() || !id) return;
    setIsProcessing(true);
    try {
      await staffService.unlockStaff(id, reason);
      setConfirmAction(null); setReason('');
      toast.success('Mở khóa tài khoản thành công!');
      refetch();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Lỗi khi mở khoá.');
    } finally { setIsProcessing(false); }
  };

  const handleResetPassword = async () => {
    if (!resetForm.new_password || !resetForm.confirm_new_password || !resetForm.reason.trim() || !id) return;
    if (resetForm.new_password !== resetForm.confirm_new_password) { toast.error('Mật khẩu xác nhận không khớp.'); return; }
    setIsProcessing(true);
    try {
      await staffService.resetStaffPassword(id, resetForm);
      setConfirmAction(null);
      setResetForm({ new_password: '', confirm_new_password: '', reason: '' });
      toast.success('Đặt lại mật khẩu thành công!');
    } catch (err: any) {
      toast.error(err?.response?.data?.error || err?.response?.data?.message || 'Lỗi khi đặt lại mật khẩu.');
    } finally { setIsProcessing(false); }
  };

  const handleOpenEdit = () => {
    if (!staff) return;
    setEditForm({
      full_name: staff.full_name || '',
      username: staff.username || '',
      email: staff.email || '',
      phone: staff.phone || ''
    });
    setConfirmAction('edit');
    setMenuOpen(false);
  };

  const handleUpdate = async () => {
    if (!id) return;
    if (!editForm.full_name.trim()) { toast.error('Họ và tên là bắt buộc.'); return; }
    if (!/^[\p{L}\.'-]+\s+[\p{L}\s\.'-]+$/u.test(editForm.full_name.trim())) { toast.error('Họ tên phải có ít nhất 2 từ và không chứa số hoặc ký tự đặc biệt.'); return; }
    if (!editForm.username.trim()) { toast.error('Username là bắt buộc.'); return; }
    if (!/^[a-zA-Z0-9_]{3,30}$/.test(editForm.username.trim())) { toast.error('Username chỉ được chứa chữ cái, số, dấu gạch dưới và từ 3-30 ký tự.'); return; }
    if (editForm.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(editForm.email.trim())) { toast.error('Email không hợp lệ.'); return; }
    if (editForm.phone && !/^(0|\+84|84)[3|5|7|8|9]\d{8}$/.test(editForm.phone.trim())) { toast.error('Số điện thoại không hợp lệ (Phải là số ĐT Việt Nam hợp lệ).'); return; }

    setIsProcessing(true);
    try {
      await staffService.updateStaff(id, editForm);
      setConfirmAction(null);
      toast.success('Cập nhật thông tin thành công!');
      refetch();
    } catch (err: any) {
      toast.error(err?.response?.data?.error || err?.response?.data?.message || 'Lỗi khi cập nhật thông tin.');
    } finally { setIsProcessing(false); }
  };


  const initials = (name?: string) => {
    if (!name) return 'S';
    return name.split(' ').map(w => w[0]).slice(-2).join('').toUpperCase();
  };

  if (isLoading) return <div className="flex items-center justify-center h-64"><Loader2 className="w-6 h-6 animate-spin text-blue-600" /></div>;
  if (!staff) return <div className="px-6 py-10 text-center text-gray-500">Không tìm thấy nhân viên.</div>;

  const isLocked = staff.status === 'LOCKED';
  const roles: string[] = staff.roles || staff.role_codes || [];

  return (
    <div className="flex-1 px-6 pt-0 pb-10 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/admin/staffs')}
            className="flex items-center justify-center w-8 h-8 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-gray-600" />
          </button>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-semibold text-sm">
              {initials(staff.full_name)}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold text-gray-900">{staff.full_name}</h1>
                <StatusBadge status={staff.status} />
              </div>
              <p className="text-gray-500 font-medium">
                {staff.username} · {roles.join(', ') || 'Không có role'}
              </p>
            </div>
          </div>
        </div>

        <div className="relative">
          <button
            onClick={() => setMenuOpen((p) => !p)}
            className="flex items-center gap-1 px-3 py-2 border border-gray-200 rounded-md text-sm hover:bg-gray-50 transition-colors"
          >
            <MoreVertical className="w-4 h-4" />
          </button>
          {menuOpen && (
            <div className="absolute right-0 mt-1 w-48 bg-white border border-gray-200 rounded-md shadow-lg z-20 py-1">
              <button onClick={handleOpenEdit}
                className="w-full flex items-center gap-2 px-4 py-2 text-sm text-blue-700 hover:bg-blue-50">
                <Edit className="w-3.5 h-3.5" /> Chỉnh sửa thông tin
              </button>
              {isLocked ? (
                <button onClick={() => { setConfirmAction('unlock'); setMenuOpen(false); }}
                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-emerald-700 hover:bg-emerald-50">
                  <Unlock className="w-3.5 h-3.5" /> Mở khoá tài khoản
                </button>
              ) : (
                <button onClick={() => { setConfirmAction('lock'); setMenuOpen(false); }}
                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-orange-700 hover:bg-orange-50">
                  <Lock className="w-3.5 h-3.5" /> Khoá tài khoản
                </button>
              )}
              <button onClick={() => { setConfirmAction('reset-pw'); setMenuOpen(false); }}
                className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50">
                <KeyRound className="w-3.5 h-3.5" /> Đặt lại mật khẩu
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <div className="flex">
          {(['info', 'permissions'] as Tab[]).map((k) => (
            <button key={k} onClick={() => setTab(k)}
              className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
                tab === k ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-800'
              }`}>
              {k === 'info' ? 'Thông tin' : 'Quyền hạn'}
            </button>
          ))}
        </div>
      </div>

      {tab === 'info' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <div className="bg-white border border-gray-200 rounded-lg p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Thông tin cá nhân</h3>
              <InfoRow label="Họ và tên" value={staff.full_name} />
              <InfoRow label="Username" value={<span className="font-mono">{staff.username}</span>} />
              <InfoRow label="Số điện thoại" value={formatDisplayPhone(staff.phone)} />
              <InfoRow label="Email" value={staff.email} />
              <InfoRow label="Trạng thái" value={<StatusBadge status={staff.status} />} />
              <InfoRow label="Đăng nhập lần cuối" value={staff.last_login_at ? formatDateTime(staff.last_login_at) : undefined} />
              <InfoRow label="Ngày tạo" value={staff.created_at ? formatDateTime(staff.created_at) : undefined} />
            </div>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-5 h-fit">
            <h3 className="text-sm font-semibold text-gray-900 mb-3">Vai trò</h3>
            <div className="flex flex-wrap gap-2">
              {roles.length ? roles.map((r: string) => (
                <span key={r} className="px-3 py-1 bg-indigo-50 text-indigo-700 text-sm font-medium rounded-full">{r}</span>
              )) : <span className="text-gray-400 text-sm">Chưa có vai trò</span>}
            </div>
          </div>
        </div>
      )}

      {tab === 'permissions' && (
        <div className="bg-white border border-gray-200 rounded-lg p-8 text-center">
          <Shield className="w-10 h-10 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500 text-sm">Quản lý phân quyền chi tiết tại <a href="/admin/roles" className="text-blue-600 underline">Phân quyền</a>.</p>
        </div>
      )}

      {/* Dialogs */}
      {(confirmAction === 'lock' || confirmAction === 'unlock') && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-xl">
            <div className="px-6 py-4 border-b">
              <h3 className="text-base font-semibold text-gray-900">
                {confirmAction === 'lock' ? 'Khoá tài khoản' : 'Mở khoá tài khoản'}
              </h3>
              <p className="text-sm text-gray-500 mt-0.5">Nhân viên: <strong>{staff.full_name}</strong></p>
            </div>
            <div className="px-6 py-4">
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Lý do <span className="text-red-500">*</span></label>
              <textarea rows={3} value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Nhập lý do..."
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/20" />
            </div>
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <button onClick={() => { setConfirmAction(null); setReason(''); }}
                className="px-4 py-2 text-sm text-gray-700 border border-gray-200 rounded-md hover:bg-gray-100">Hủy</button>
              <button onClick={confirmAction === 'lock' ? handleLock : handleUnlock}
                disabled={!reason.trim() || isProcessing}
                className={`px-4 py-2 text-sm text-white rounded-md font-medium disabled:opacity-50 flex items-center gap-1.5 ${confirmAction === 'lock' ? 'bg-orange-500 hover:bg-orange-600' : 'bg-emerald-600 hover:bg-emerald-700'}`}>
                {isProcessing && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                {confirmAction === 'lock' ? 'Xác nhận khoá' : 'Xác nhận mở khoá'}
              </button>
            </div>
          </div>
        </div>
      )}

      {confirmAction === 'reset-pw' && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-xl">
            <div className="px-6 py-4 border-b">
              <h3 className="text-base font-semibold text-gray-900">Đặt lại mật khẩu</h3>
              <p className="text-sm text-gray-500 mt-0.5">Nhân viên: <strong>{staff.full_name}</strong></p>
            </div>
            <div className="px-6 py-4 space-y-3">
              {(['new_password', 'confirm_new_password', 'reason'] as const).map((f) => (
                <div key={f}>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    {f === 'new_password' ? 'Mật khẩu mới' : f === 'confirm_new_password' ? 'Xác nhận mật khẩu' : 'Lý do'}
                    <span className="text-red-500"> *</span>
                  </label>
                  {f === 'reason' ? (
                    <textarea rows={2} value={resetForm[f]} onChange={(e) => setResetForm(p => ({ ...p, [f]: e.target.value }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm resize-none" />
                  ) : (
                    <input type="text" value={resetForm[f]} onChange={(e) => setResetForm(p => ({ ...p, [f]: e.target.value }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
                  )}
                </div>
              ))}
            </div>
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <button onClick={() => { setConfirmAction(null); setResetForm({ new_password: '', confirm_new_password: '', reason: '' }); }}
                className="px-4 py-2 text-sm text-gray-700 border border-gray-200 rounded-md hover:bg-gray-100">Hủy</button>
              <button onClick={handleResetPassword} disabled={isProcessing}
                className="px-4 py-2 text-sm text-white bg-indigo-600 hover:bg-indigo-700 rounded-md font-medium disabled:opacity-50 flex items-center gap-1.5">
                {isProcessing && <Loader2 className="w-3.5 h-3.5 animate-spin" />} Đặt lại mật khẩu
              </button>
            </div>
          </div>
        </div>
      )}

      {confirmAction === 'edit' && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-lg shadow-xl">
            <div className="px-6 py-4 border-b">
              <h3 className="text-base font-semibold text-gray-900">Chỉnh sửa thông tin nhân viên</h3>
              <p className="text-sm text-gray-500 mt-0.5">Cập nhật thông tin cho <strong>{staff.full_name}</strong></p>
            </div>
            <div className="px-6 py-4 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Họ và tên <span className="text-red-500">*</span>
                  </label>
                  <input type="text" value={editForm.full_name} onChange={(e) => setEditForm(p => ({ ...p, full_name: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Username <span className="text-red-500">*</span>
                  </label>
                  <input type="text" value={editForm.username} onChange={(e) => setEditForm(p => ({ ...p, username: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">Số điện thoại</label>
                  <input type="tel" value={editForm.phone} onChange={(e) => setEditForm(p => ({ ...p, phone: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
                  <input type="email" value={editForm.email} onChange={(e) => setEditForm(p => ({ ...p, email: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
                </div>
              </div>
            </div>
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <button onClick={() => setConfirmAction(null)}
                className="px-4 py-2 text-sm text-gray-700 border border-gray-200 rounded-md hover:bg-gray-100">Hủy</button>
              <button onClick={handleUpdate} disabled={isProcessing}
                className="px-4 py-2 text-sm text-white bg-blue-600 hover:bg-blue-700 rounded-md font-medium disabled:opacity-50 flex items-center gap-1.5">
                {isProcessing && <Loader2 className="w-3.5 h-3.5 animate-spin" />} Cập nhật
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
