import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Plus, Loader2, Info } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { z } from 'zod';
import { userService } from '../../features/user-management/user.service';
import { fullNameSchema, vietnamMobilePhoneSchema, emailSchema } from '../../shared/validation/common-validation';

const userCreateSchema = z.object({
  full_name: fullNameSchema,
  phone: vietnamMobilePhoneSchema,
  email: z.union([emailSchema, z.literal('')]).optional().transform(e => e === '' ? undefined : e)
});

export default function UserCreate() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [form, setForm] = useState({
    full_name: '',
    phone: '',
    email: '',
  });
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = async (e: React.FormEvent) => {
    if (isSubmitting) return;
    e.preventDefault();
    setError('');
    setErrors({});

    const parseResult = userCreateSchema.safeParse(form);
    if (!parseResult.success) {
      const fieldErrors: Record<string, string> = {};
      const flattened = parseResult.error.flatten().fieldErrors;
      
      for (const key in flattened) {
        if (flattened[key] && flattened[key]!.length > 0) {
          fieldErrors[key] = flattened[key]![0];
        }
      }
      setErrors(fieldErrors);
      
      // Focus vào field lỗi đầu tiên
      const firstErrorField = parseResult.error.issues[0]?.path[0]?.toString();
      if (firstErrorField) {
        document.getElementById(firstErrorField)?.focus();
      }
      return;
    }

    setIsSubmitting(true);
    try {
      // Tạo người dùng ví qua API /admin/users
      // Gửi đúng data đã pass qua Zod (email rỗng sẽ là undefined)
      await userService.createUser({
        full_name: form.full_name,
        phone: form.phone,
        email: parseResult.data.email,
      });
      
      // Invalidate cache để trang danh sách tự động cập nhật
      queryClient.invalidateQueries({ queryKey: ['admin-wallet-users'] });
      
      navigate('/admin/users', { replace: true });
    } catch (err: any) {
      const responseData = err?.response?.data;
      if (responseData?.code === 'RESOURCE_CONFLICT' && responseData.errors?.length > 0) {
        const conflictErrors: Record<string, string> = {};
        responseData.errors.forEach((e: any) => {
          conflictErrors[e.field] = e.message;
        });
        setErrors(conflictErrors);
        const firstErrorField = responseData.errors[0]?.field;
        if (firstErrorField) {
          document.getElementById(firstErrorField)?.focus();
        }
      } else {
        setError(responseData?.error || responseData?.message || err?.message || 'Tạo người dùng thất bại.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const set = (field: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }));
    // Khi user sửa field, xóa lỗi inline của riêng field đó
    if (errors[field]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  };

  return (
    <div className="flex-1 px-6 pt-0 pb-10">
      {/* Page Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/admin/users')}
            className="flex items-center justify-center w-8 h-8 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-gray-600" />
          </button>
          <h1 className="text-2xl font-bold text-gray-900">Tạo mới người dùng ví</h1>
        </div>
        <button
          form="user-create-form"
          type="submit"
          disabled={isSubmitting}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 disabled:opacity-50 transition-colors"
        >
          {isSubmitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
          Tạo mới
        </button>
      </div>

      <form id="user-create-form" onSubmit={handleSubmit} noValidate>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main — Thông tin cơ bản */}
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-white border border-gray-200 rounded-lg p-6">
              <h2 className="text-base font-semibold text-gray-900 mb-4">Thông tin cơ bản</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Họ và tên <span className="text-red-500">*</span>
                  </label>
                  <input
                    id="full_name"
                    type="text"
                    value={form.full_name}
                    onChange={set('full_name')}
                    placeholder="Nhập họ và tên đầy đủ"
                    className={`w-full px-3 py-2.5 border ${errors.full_name ? 'border-red-500' : 'border-gray-300'} rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500`}
                  />
                  {errors.full_name && <p className="mt-1.5 text-xs text-red-500">{errors.full_name}</p>}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Số điện thoại <span className="text-red-500">*</span>
                  </label>
                  <input
                    id="phone"
                    type="tel"
                    value={form.phone}
                    onChange={set('phone')}
                    placeholder="0901234567"
                    className={`w-full px-3 py-2.5 border ${errors.phone ? 'border-red-500' : 'border-gray-300'} rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500`}
                  />
                  {errors.phone && <p className="mt-1.5 text-xs text-red-500">{errors.phone}</p>}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
                  <input
                    id="email"
                    type="email"
                    value={form.email}
                    onChange={set('email')}
                    placeholder="example@email.com"
                    className={`w-full px-3 py-2.5 border ${errors.email ? 'border-red-500' : 'border-gray-300'} rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500`}
                  />
                  {errors.email && <p className="mt-1.5 text-xs text-red-500">{errors.email}</p>}
                </div>
              </div>

              {error && (
                <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-sm text-red-700">
                  {error}
                </div>
              )}
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-4">
            <div className="bg-white border border-gray-200 rounded-lg p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Tóm tắt</h3>
              <div className="space-y-2.5 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Loại tài khoản</span>
                  <span className="font-medium text-gray-900">Ví điện tử (USER)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Xác thực</span>
                  <span className="font-medium text-gray-900">Xác minh OTP và tạo mật khẩu đăng nhập</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Trạng thái ban đầu</span>
                  <span className="font-medium text-amber-600">Chờ xác minh</span>
                </div>
              </div>
            </div>

            <div className="bg-blue-50 border border-blue-100 rounded-lg p-4">
              <div className="flex gap-2">
                <Info className="w-4 h-4 text-blue-600 mt-0.5 shrink-0" />
                <div className="text-sm text-blue-700">
                  <p className="font-medium mb-1">Lưu ý</p>
                  <p>Người dùng xác minh số điện thoại bằng OTP và tự tạo mật khẩu đăng nhập trên Mobile App. PIN giao dịch được thiết lập riêng sau khi đăng nhập.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
