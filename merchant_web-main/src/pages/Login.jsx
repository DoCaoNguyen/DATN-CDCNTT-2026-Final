import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import axiosClient from '../api/axiosClient';
import useAuthStore from '../store/useAuthStore';
import { Button } from '../components/ui/Button/Button';
import { toast } from 'sonner';

const loginSchema = z.object({
  email: z.string().min(1, "Email không được để trống"),
  password: z.string().min(1, "Mật khẩu không được để trống"),
});

const Login = () => {
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const location = useLocation();
  const { setAuth } = useAuthStore();

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  });

  const onSubmit = async (data) => {
    setError('');
    try {
      const res = await axiosClient.post('/auth/login', {
        login_id: data.email,
        password: data.password
      });

      const user = res.data?.user || res.user; const accessToken = res.data?.access_token || res.data?.accessToken || res.access_token;

      // Check if user is merchant
      const isMerchantUser = user?.user_type === 'MERCHANT_USER';
      const hasMerchantRole = user?.roles?.some(r => r === 'MERCHANT_OWNER' || r === 'MERCHANT_STAFF');

      if (!isMerchantUser && !hasMerchantRole) {
        throw new Error('Tài khoản không có quyền truy cập Merchant Portal');
      }

      setAuth(accessToken, user);
      toast.success('Đăng nhập thành công');

      if (user.is_force_change_password) {
        navigate('/merchant/change-password', { replace: true });
      } else {
        const from = location.state?.from?.pathname || '/merchant/dashboard';
        navigate(from, { replace: true });
      }

    } catch (err) {
      console.error('Login error:', err);
      const msg = err.response?.data?.error || err.response?.data?.message || err.message || 'Đăng nhập thất bại';
      setError(msg);
      toast.error(msg);
    }
  };

  return (
    <div>
      {error && (
        <div style={{ padding: '0.75rem', backgroundColor: 'var(--danger-bg)', color: 'var(--danger)', borderRadius: 'var(--radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem', border: '1px solid rgba(239, 68, 68, 0.2)' }}>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div>
          <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)' }}>
            Email / Tên đăng nhập
          </label>
          <input
            type="text"
            {...register('email')}
            style={{ width: '100%', borderColor: errors.email ? 'var(--danger)' : undefined }}
            placeholder="Nhập email hoặc tên đăng nhập"
          />
          {errors.email && (
            <p className="text-danger" style={{ fontSize: '0.75rem', marginTop: '0.5rem' }}>
              {errors.email.message}
            </p>
          )}
        </div>

        <div>
          <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)' }}>
            Mật khẩu
          </label>
          <input
            type="password"
            {...register('password')}
            style={{ width: '100%', borderColor: errors.password ? 'var(--danger)' : undefined }}
            placeholder="********"
          />
          {errors.password && (
            <p className="text-danger" style={{ fontSize: '0.75rem', marginTop: '0.5rem' }}>
              {errors.password.message}
            </p>
          )}
        </div>

        <Button
          type="submit"
          variant="primary"
          size="lg"
          style={{ width: '100%', marginTop: '0.5rem' }}
          isLoading={isSubmitting}
        >
          Đăng nhập
        </Button>
      </form>
    </div>
  );
};

export default Login;
