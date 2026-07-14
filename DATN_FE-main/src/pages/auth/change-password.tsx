import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { Lock, Loader2, Eye, EyeOff } from 'lucide-react';
import { authService } from '../../features/auth/auth.service';

const changePasswordSchema = z.object({
  current_password: z.string().min(1, { message: 'Vui lòng nhập mật khẩu hiện tại' }),
  new_password: z.string().min(6, { message: 'Mật khẩu mới phải có ít nhất 6 ký tự' }),
  confirm_new_password: z.string().min(1, { message: 'Vui lòng xác nhận mật khẩu mới' }),
}).refine((data) => data.new_password === data.confirm_new_password, {
  message: 'Mật khẩu xác nhận không khớp',
  path: ['confirm_new_password'],
});

type ChangePasswordFormValues = z.infer<typeof changePasswordSchema>;

export default function ChangePassword() {
  const navigate = useNavigate();
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [apiError, setApiError] = useState<string | null>(null);

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<ChangePasswordFormValues>({
    resolver: zodResolver(changePasswordSchema),
    defaultValues: { current_password: '', new_password: '', confirm_new_password: '' },
  });

  const onSubmit = async (data: ChangePasswordFormValues) => {
    setApiError(null);
    try {
      // Call BE to change password
      await authService.changePassword(data);
      
      // Token version is incremented on the backend, so the current token is invalidated.
      // We must clear local storage and redirect to login.
      localStorage.clear();
      alert('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.');
      navigate('/login', { replace: true });
    } catch (error: any) {
      if (error?.response?.data?.message) {
        setApiError(error.response.data.message);
      } else {
        setApiError('Không thể đổi mật khẩu. Vui lòng kiểm tra lại Backend!');
      }
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('user_info');
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-slate-100 flex items-center justify-center p-4 font-sans">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl overflow-hidden">
        
        {/* Header */}
        <div className="bg-blue-600 px-6 py-8 text-center text-white relative">
          <h2 className="text-2xl font-bold mt-2">Đổi mật khẩu lần đầu</h2>
          <p className="text-blue-100 mt-2 text-sm">
            Vì lý do bảo mật, bạn bắt buộc phải đổi mật khẩu trước khi tiếp tục sử dụng hệ thống.
          </p>
        </div>

        {/* Form */}
        <div className="p-8">
          {apiError && (
            <div className="mb-6 p-3 bg-red-50 border border-red-200 rounded-md text-sm text-red-600 font-medium">
              {apiError}
            </div>
          )}

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            {/* Current Password */}
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1.5">Mật khẩu hiện tại (Mật khẩu tạm thời)</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-slate-400" />
                </div>
                <input
                  type={showCurrentPassword ? 'text' : 'password'}
                  {...register('current_password')}
                  className={`block w-full pl-10 pr-10 py-2.5 sm:text-sm rounded-lg border ${
                    errors.current_password ? 'border-red-300 focus:ring-red-500/20' : 'border-slate-300 focus:ring-blue-500/20 focus:border-blue-500'
                  } focus:outline-none focus:ring-4 transition-all`}
                  placeholder="Nhập mật khẩu hiện tại"
                />
                <button
                  type="button"
                  onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600"
                >
                  {showCurrentPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>
              {errors.current_password && <p className="text-red-500 text-xs font-medium mt-1">{errors.current_password.message}</p>}
            </div>

            {/* New Password */}
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1.5">Mật khẩu mới</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-slate-400" />
                </div>
                <input
                  type={showNewPassword ? 'text' : 'password'}
                  {...register('new_password')}
                  className={`block w-full pl-10 pr-10 py-2.5 sm:text-sm rounded-lg border ${
                    errors.new_password ? 'border-red-300 focus:ring-red-500/20' : 'border-slate-300 focus:ring-blue-500/20 focus:border-blue-500'
                  } focus:outline-none focus:ring-4 transition-all`}
                  placeholder="Nhập mật khẩu mới"
                />
                <button
                  type="button"
                  onClick={() => setShowNewPassword(!showNewPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600"
                >
                  {showNewPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>
              {errors.new_password && <p className="text-red-500 text-xs font-medium mt-1">{errors.new_password.message}</p>}
            </div>

            {/* Confirm New Password */}
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1.5">Xác nhận mật khẩu mới</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-slate-400" />
                </div>
                <input
                  type={showConfirmPassword ? 'text' : 'password'}
                  {...register('confirm_new_password')}
                  className={`block w-full pl-10 pr-10 py-2.5 sm:text-sm rounded-lg border ${
                    errors.confirm_new_password ? 'border-red-300 focus:ring-red-500/20' : 'border-slate-300 focus:ring-blue-500/20 focus:border-blue-500'
                  } focus:outline-none focus:ring-4 transition-all`}
                  placeholder="Xác nhận mật khẩu mới"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600"
                >
                  {showConfirmPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>
              {errors.confirm_new_password && <p className="text-red-500 text-xs font-medium mt-1">{errors.confirm_new_password.message}</p>}
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full flex justify-center py-2.5 px-4 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-500/30 transition-colors disabled:opacity-70 disabled:cursor-not-allowed mt-2"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="animate-spin -ml-1 mr-2 h-5 w-5 text-white" />
                  Đang xử lý...
                </>
              ) : (
                'Đổi mật khẩu & Tiếp tục'
              )}
            </button>
          </form>

          {/* Footer links */}
          <div className="mt-8 text-center border-t border-slate-100 pt-6">
            <button
              onClick={handleLogout}
              className="text-sm text-slate-500 hover:text-slate-800 transition-colors"
            >
              Đăng xuất và quay lại trang đăng nhập
            </button>
          </div>

        </div>
      </div>
    </div>
  );
}
