import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { User, Eye, EyeOff, Loader2 } from 'lucide-react';

import { authService } from '../../features/auth/auth.service';
import type { LoginPayload } from '../../types';

// 1. Khai báo luật kiểm tra dữ liệu bằng Zod
const loginSchema = z.object({
  login_id: z.string().min(3, { message: 'Tài khoản phải có ít nhất 3 ký tự' }),
  password: z.string().min(6, { message: 'Mật khẩu phải có ít nhất 6 ký tự' }),
});

type LoginFormValues = z.infer<typeof loginSchema>;

export default function AdminLogin() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [apiError, setApiError] = useState<string | null>(null);

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { login_id: '', password: '' },
  });

  const onSubmit = async (data: LoginFormValues) => {
    setApiError(null);
    try {
      const payload: LoginPayload = {
        login_id: data.login_id,
        password: data.password,
      };
      
      const response = await authService.login(payload);

      if (response.success) {
        const userRoles = response.data.user.roles || [];
        const hasAdminAccess = userRoles.some(role => 
          ['SUPER_ADMIN', 'ADMIN', 'SUPPORT_STAFF', 'ADMIN_OPS'].includes(role)
        );

        if (!hasAdminAccess) {
          setApiError('Tài khoản của bạn không có quyền truy cập trang quản trị.');
          return;
        }

        // Lưu trữ token dựa theo thiết kế hệ thống
        localStorage.setItem('access_token', response.data.access_token);
        localStorage.setItem('refresh_token', response.data.refresh_token);
        localStorage.setItem('user_info', JSON.stringify(response.data.user));
        
        navigate('/admin/dashboard');
      }
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } } };
      if (err?.response?.data?.message) {
        setApiError(err.response.data.message);
      } else {
        setApiError('Không thể kết nối máy chủ. Vui lòng kiểm tra lại Backend!');
      }
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4 sm:p-6 font-sans">
      <div className="max-w-5xl w-full bg-white rounded-xl shadow-2xl overflow-hidden flex flex-col md:flex-row min-h-[550px]">
        
        {/* Left Side - Illustration */}
        <div className="hidden md:flex md:w-[55%] items-center justify-center p-8 bg-white relative">
          <img 
            src="/wallet-illustration.png" 
            alt="E-Wallet Login Illustration" 
            className="w-full max-w-sm h-auto object-contain"
          />
        </div>

        {/* Right Side - Form */}
        <div className="w-full md:w-[45%] p-8 sm:p-12 flex flex-col justify-center bg-white relative z-10 md:-ml-8">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-extrabold text-slate-800 tracking-tight">Login</h2>
          </div>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            {apiError && (
              <div className="p-3 bg-red-50 border border-red-200 text-red-600 text-sm rounded-lg font-medium text-center mb-4">
                {apiError}
              </div>
            )}

            <div>
              <div className="relative flex items-center">
                <input
                  type="text"
                  {...register('login_id')}
                  className={`w-full bg-[#f3f4f6] text-slate-800 rounded-md px-5 py-3.5 outline-none transition-all placeholder:text-gray-400 font-medium ${
                    errors.login_id ? 'ring-2 ring-red-400' : 'focus:ring-2 focus:ring-blue-400'
                  }`}
                  placeholder="Username or Email"
                />
                <div className="absolute right-4 flex items-center pointer-events-none text-slate-800">
                  <User className="h-5 w-5" />
                </div>
              </div>
              {errors.login_id && <p className="text-red-500 text-xs font-medium mt-1.5 ml-1">{errors.login_id.message}</p>}
            </div>

            <div>
              <div className="relative flex items-center">
                <input
                  type={showPassword ? 'text' : 'password'}
                  {...register('password')}
                  className={`w-full bg-[#f3f4f6] text-slate-800 rounded-md px-5 py-3.5 outline-none transition-all placeholder:text-gray-400 font-medium ${
                    errors.password ? 'ring-2 ring-red-400' : 'focus:ring-2 focus:ring-blue-400'
                  }`}
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 flex items-center text-slate-800 hover:text-slate-600 transition-colors"
                >
                  {showPassword ? <Eye className="h-5 w-5" /> : <EyeOff className="h-5 w-5" />}
                </button>
              </div>
              {errors.password && <p className="text-red-500 text-xs font-medium mt-1.5 ml-1">{errors.password.message}</p>}
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full flex justify-center items-center py-3.5 px-4 rounded-full text-base font-bold text-white bg-[#3b82f6] hover:bg-blue-600 disabled:opacity-70 disabled:cursor-not-allowed transition-all mt-6 shadow-[0_8px_15px_rgba(59,130,246,0.3)] hover:shadow-[0_10px_20px_rgba(59,130,246,0.4)]"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="animate-spin -ml-1 mr-2 h-5 w-5 text-white" />
                  Đang xử lý...
                </>
              ) : (
                'Login'
              )}
            </button>
            
          </form>
        </div>
      </div>
    </div>
  );
}