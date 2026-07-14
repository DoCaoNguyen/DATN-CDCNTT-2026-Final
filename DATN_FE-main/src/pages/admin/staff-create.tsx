import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Plus, Loader2, Info, Shield, CheckCircle2, Copy, AlertCircle } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { staffService } from '../../features/user-management/staff.service';
import { fullNameSchema, usernameSchema, emailSchema, optionalVietnamPhoneSchema } from '../../shared/validation/common-validation';

const ROLE_OPTIONS = [
  { value: 'SUPPORT_STAFF', label: 'Support Staff' },
  { value: 'ADMIN', label: 'Admin' },
  { value: 'SUPER_ADMIN', label: 'Super Admin' },
];

export default function StaffCreate() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [successInfo, setSuccessInfo] = useState<{
    userId: string;
    email: string;
    email_sent: boolean;
  } | null>(null);
  const [isResending, setIsResending] = useState(false);
  const [resendStatus, setResendStatus] = useState<'IDLE' | 'SUCCESS' | 'FAILED'>('IDLE');

  // Refs for focusing first error field
  const inputRefs = {
    full_name: useRef<HTMLInputElement>(null),
    username: useRef<HTMLInputElement>(null),
    phone: useRef<HTMLInputElement>(null),
    email: useRef<HTMLInputElement>(null),
  };

  const [form, setForm] = useState({
    username: '',
    full_name: '',
    email: '',
    phone: '',
    role_codes: ['SUPPORT_STAFF'] as string[],
  });

  const set = (field: keyof typeof form) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
      setForm((prev) => ({ ...prev, [field]: e.target.value }));
      if (fieldErrors[field]) {
        setFieldErrors((prev) => ({ ...prev, [field]: '' }));
      }
    };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setFieldErrors({});

    // Client-side Zod validation
    const errors: Record<string, string> = {};

    const fnRes = fullNameSchema.safeParse(form.full_name);
    if (!fnRes.success) errors.full_name = fnRes.error.issues[0].message;

    const unRes = usernameSchema.safeParse(form.username);
    if (!unRes.success) errors.username = unRes.error.issues[0].message;

    const emRes = emailSchema.safeParse(form.email);
    if (!emRes.success) errors.email = emRes.error.issues[0].message;

    const phRes = optionalVietnamPhoneSchema.safeParse(form.phone);
    if (!phRes.success) errors.phone = phRes.error.issues[0].message;

    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      const firstErrorField = Object.keys(errors)[0] as keyof typeof inputRefs;
      inputRefs[firstErrorField]?.current?.focus();
      return;
    }

    setIsSubmitting(true);
    try {
      const payload: any = {
        username: form.username,
        full_name: form.full_name,
        email: form.email || undefined,
        role_codes: form.role_codes,
      };
      
      const normalizedPhone = optionalVietnamPhoneSchema.parse(form.phone);
      if (normalizedPhone) {
        payload.phone = normalizedPhone;
      }

      const res = await staffService.createStaff(payload);
      const data = res?.data || res;
      
      // Invalidate the cache to refresh the staff list
      queryClient.invalidateQueries({ queryKey: ['admin-staffs'] });

      if (data && data.id) {
        setSuccessInfo({
          userId: data.id,
          email: form.email,
          email_sent: !!data.email_sent
        });
      } else {
        navigate('/admin/staffs', { replace: true });
      }
    } catch (err: any) {
      const errData = err?.response?.data;
      if (errData?.code === 'RESOURCE_CONFLICT' && errData?.errors) {
        const newFieldErrors: Record<string, string> = {};
        errData.errors.forEach((e: any) => {
          if (e.field) newFieldErrors[e.field] = e.message;
        });
        setFieldErrors(newFieldErrors);
        const firstErrorField = errData.errors[0]?.field as keyof typeof inputRefs;
        if (inputRefs[firstErrorField]) {
          inputRefs[firstErrorField].current?.focus();
        }
      } else {
        setError(errData?.error || errData?.message || 'Tạo nhân viên thất bại.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  // Hiển thị mật khẩu tạm thời sau khi tạo thành công
  const handleResendOnboarding = async () => {
    if (!successInfo) return;
    setIsResending(true);
    setResendStatus('IDLE');
    try {
      await staffService.resendOnboardingEmail(successInfo.userId);
      setResendStatus('SUCCESS');
      setSuccessInfo(prev => prev ? { ...prev, email_sent: true } : null);
      toast.success('Đã gửi lại email onboarding thành công!');
    } catch (err: any) {
      setResendStatus('FAILED');
      toast.error(err?.response?.data?.message || 'Gửi lại email thất bại.');
    } finally {
      setIsResending(false);
    }
  };

  // Hiển thị trạng thái gửi email sau khi tạo thành công
  if (successInfo) {
    const isSent = successInfo.email_sent;
    return (
      <div className="flex-1 px-6 pt-10 pb-10 flex justify-center">
        <div className="w-full max-w-2xl bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
          <div className={`px-6 py-5 border-b border-gray-200 flex items-center gap-3 ${isSent ? 'bg-emerald-50/50' : 'bg-red-50/50'}`}>
            <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${isSent ? 'bg-emerald-100' : 'bg-red-100'}`}>
              <CheckCircle2 className={`w-6 h-6 ${isSent ? 'text-emerald-600' : 'text-red-600'}`} />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-gray-950">Tạo tài khoản nhân viên thành công</h2>
              <p className={`text-sm mt-0.5 ${isSent ? 'text-emerald-600' : 'text-red-600'}`}>
                {isSent ? 'Tài khoản nhân viên đã hoạt động và sẵn sàng đăng nhập.' : 'Lưu ý: Chưa gửi được thông tin đăng nhập cho nhân viên.'}
              </p>
            </div>
          </div>
          
          <div className="p-6">
            {isSent ? (
              <div className="bg-emerald-50 border border-emerald-200 rounded-md p-4 mb-6 flex gap-3">
                <Info className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                <div className="text-sm text-emerald-800">
                  <p className="font-semibold mb-1">Email đã gửi thành công</p>
                  <p>Mật khẩu đăng nhập tạm thời đã được gửi trực tiếp tới email <strong>{successInfo.email}</strong>. Nhân viên được yêu cầu đổi mật khẩu ở lần đăng nhập đầu tiên.</p>
                </div>
              </div>
            ) : (
              <div className="bg-amber-50 border border-amber-200 rounded-md p-4 mb-6 flex gap-3">
                <AlertCircle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
                <div className="text-sm text-amber-800">
                  <p className="font-semibold mb-1">Cảnh báo: Gửi email thất bại (EMAIL_SEND_FAILED)</p>
                  <p className="mb-2">Hệ thống đã tạo xong tài khoản nhân viên nhưng không gửi được email chứa mật khẩu đăng nhập tạm thời tới địa chỉ <strong>{successInfo.email}</strong> do lỗi kết nối SMTP hoặc cấu hình email sai.</p>
                  <p className="font-medium text-amber-700">Mật khẩu của nhân viên vẫn được bảo mật (không hiển thị rõ trên màn hình quản lý). Bạn hãy cấu hình lại SMTP Mail hoặc bấm nút "Gửi lại email" bên dưới để hệ thống cấp mật khẩu tạm mới và gửi lại.</p>
                </div>
              </div>
            )}

            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-md border border-gray-100">
                <div>
                  <span className="text-xs text-gray-500 block">Địa chỉ nhận thông tin</span>
                  <span className="text-sm font-semibold text-gray-800">{successInfo.email}</span>
                </div>
                <button
                  onClick={handleResendOnboarding}
                  disabled={isResending}
                  className={`px-4 py-2 border rounded-md text-sm font-medium transition-colors ${
                    isResending 
                      ? 'bg-gray-100 text-gray-400 border-gray-200 cursor-not-allowed'
                      : 'bg-white hover:bg-gray-50 text-blue-600 border-gray-300'
                  }`}
                >
                  {isResending ? 'Đang gửi...' : 'Gửi lại email'}
                </button>
              </div>
            </div>
          </div>
          
          <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end">
            <button
              onClick={() => navigate('/admin/staffs')}
              className="px-5 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 transition-colors shadow-sm"
            >
              Quay lại danh sách
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 px-6 pt-0 pb-10">
      {/* Page Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/admin/staffs')}
            className="flex items-center justify-center w-8 h-8 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-gray-600" />
          </button>
          <h1 className="text-2xl font-bold text-gray-900">Tạo mới nhân viên</h1>
        </div>
        <button
          form="staff-create-form"
          type="submit"
          disabled={isSubmitting}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 disabled:opacity-50 transition-colors"
        >
          {isSubmitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
          Tạo mới
        </button>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-red-50 border-l-4 border-red-500 rounded-md flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 shrink-0" />
          <p className="text-sm text-red-700">{error}</p>
        </div>
      )}

      <form id="staff-create-form" onSubmit={handleSubmit}>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main */}
          <div className="lg:col-span-2 space-y-5">
            {/* Thông tin cơ bản */}
            <div className="bg-white border border-gray-200 rounded-lg p-6">
              <h2 className="text-base font-semibold text-gray-900 mb-4">Thông tin cơ bản</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Họ và tên <span className="text-red-500">*</span>
                  </label>
                  <input
                    ref={inputRefs.full_name}
                    type="text" value={form.full_name} onChange={set('full_name')}
                    placeholder="Nhập họ và tên đầy đủ"
                    maxLength={25}
                    className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 ${
                      fieldErrors.full_name 
                        ? 'border-red-300 focus:ring-red-500/20 focus:border-red-500 bg-red-50/30' 
                        : 'border-gray-300 focus:ring-blue-500/20 focus:border-blue-500'
                    }`}
                  />
                  {fieldErrors.full_name && <p className="mt-1.5 text-xs text-red-600">{fieldErrors.full_name}</p>}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Username <span className="text-red-500">*</span>
                  </label>
                  <input
                    ref={inputRefs.username}
                    type="text" value={form.username} onChange={set('username')}
                    placeholder="admin_john"
                    className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 ${
                      fieldErrors.username 
                        ? 'border-red-300 focus:ring-red-500/20 focus:border-red-500 bg-red-50/30' 
                        : 'border-gray-300 focus:ring-blue-500/20 focus:border-blue-500'
                    }`}
                  />
                  {fieldErrors.username && <p className="mt-1.5 text-xs text-red-600">{fieldErrors.username}</p>}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">Số điện thoại</label>
                  <input
                    ref={inputRefs.phone}
                    type="tel" value={form.phone} onChange={set('phone')}
                    placeholder="0901234567"
                    className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 ${
                      fieldErrors.phone 
                        ? 'border-red-300 focus:ring-red-500/20 focus:border-red-500 bg-red-50/30' 
                        : 'border-gray-300 focus:ring-blue-500/20 focus:border-blue-500'
                    }`}
                  />
                  {fieldErrors.phone && <p className="mt-1.5 text-xs text-red-600">{fieldErrors.phone}</p>}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Email <span className="text-red-500">*</span>
                  </label>
                  <input
                    ref={inputRefs.email}
                    type="email" value={form.email} onChange={set('email')}
                    placeholder="nhanvien@company.com"
                    className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 ${
                      fieldErrors.email 
                        ? 'border-red-300 focus:ring-red-500/20 focus:border-red-500 bg-red-50/30' 
                        : 'border-gray-300 focus:ring-blue-500/20 focus:border-blue-500'
                    }`}
                  />
                  {fieldErrors.email && <p className="mt-1.5 text-xs text-red-600">{fieldErrors.email}</p>}
                </div>
              </div>
            </div>

            {/* Phân quyền */}
            <div className="bg-white border border-gray-200 rounded-lg p-6">
              <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <Shield className="w-4 h-4 text-gray-500" /> Phân quyền
              </h2>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Vai trò (Role) <span className="text-red-500">*</span>
                </label>
                <select
                  value={form.role_codes[0]}
                  onChange={(e) => setForm((prev) => ({ ...prev, role_codes: [e.target.value] }))}
                  className="w-full px-3 py-2.5 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                >
                  {ROLE_OPTIONS.map((r) => (
                    <option key={r.value} value={r.value}>{r.label}</option>
                  ))}
                </select>
              </div>
            </div>

            {error && (
              <div className="p-3 bg-red-50 border border-red-200 rounded-md text-sm text-red-700">{error}</div>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-4">
            <div className="bg-white border border-gray-200 rounded-lg p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Tóm tắt</h3>
              <div className="space-y-2.5 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Loại tài khoản</span>
                  <span className="font-medium text-gray-900">Staff / Admin</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Xác thực</span>
                  <span className="font-medium text-gray-900">Username + Password</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Vai trò đã chọn</span>
                  <span className="font-medium text-blue-700">{form.role_codes[0]}</span>
                </div>
              </div>
            </div>
            <div className="bg-amber-50 border border-amber-100 rounded-lg p-4">
              <div className="flex gap-2">
                <Info className="w-4 h-4 text-amber-600 mt-0.5 shrink-0" />
                <p className="text-sm text-amber-700">Mật khẩu tạm thời sẽ được cấp sau khi tạo thành công. Nhớ sao chép ngay.</p>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
