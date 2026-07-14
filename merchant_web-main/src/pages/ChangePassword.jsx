import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import axiosClient from '../api/axiosClient';
import useAuthStore from '../store/useAuthStore';
import { Button } from '../components/ui/Button/Button';
import { toast } from 'sonner';

const changePasswordSchema = z.object({
  oldPassword: z.string().min(1, "Mật khẩu hiện tại không được để trống"),
  newPassword: z.string().min(6, "Mật khẩu mới phải có ít nhất 6 ký tự"),
  confirmPassword: z.string().min(1, "Vui lòng xác nhận mật khẩu mới"),
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: "Mật khẩu xác nhận không khớp",
  path: ["confirmPassword"],
});

const ChangePassword = () => {
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const { user, setAuth, token } = useAuthStore();

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(changePasswordSchema),
    defaultValues: {
      oldPassword: '',
      newPassword: '',
      confirmPassword: '',
    },
  });

  const onSubmit = async (data) => {
    setError('');
    try {
      await axiosClient.post('/auth/change-password', {
        old_password: data.oldPassword,
        new_password: data.newPassword
      });

      // Update store so user doesn't get blocked by ProtectedRoute anymore
      setAuth(token, { ...user, is_force_change_password: false });
      toast.success('Đổi mật khẩu thành công');

      navigate('/merchant/dashboard');
    } catch (err) {
      console.error('Change password error:', err);
      const msg = err.response?.data?.error || err.response?.data?.message || 'Đổi mật khẩu thất bại';
      setError(msg);
      toast.error(msg);
    }
  };

  return (
    <div>
      <h3 style={{ textAlign: 'center', marginBottom: '1.5rem', color: 'var(--text-muted)', fontSize: '1rem', fontWeight: 500 }}>
        Bạn cần đổi mật khẩu trong lần đăng nhập đầu tiên
      </h3>

      {error && (
        <div style={{ padding: '0.75rem', backgroundColor: 'var(--danger-bg)', color: 'var(--danger)', borderRadius: 'var(--radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem', border: '1px solid rgba(239, 68, 68, 0.2)' }}>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div>
          <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)' }}>
            Mật khẩu hiện tại
          </label>
          <input
            type="password"
            {...register('oldPassword')}
            style={{ width: '100%', borderColor: errors.oldPassword ? 'var(--danger)' : undefined }}
            placeholder="Nhập mật khẩu hiện tại"
          />
          {errors.oldPassword && (
            <p className="text-danger" style={{ fontSize: '0.75rem', marginTop: '0.5rem' }}>{errors.oldPassword.message}</p>
          )}
        </div>

        <div>
          <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)' }}>
            Mật khẩu mới
          </label>
          <input
            type="password"
            {...register('newPassword')}
            style={{ width: '100%', borderColor: errors.newPassword ? 'var(--danger)' : undefined }}
            placeholder="Nhập mật khẩu mới (ít nhất 6 ký tự)"
          />
          {errors.newPassword && (
            <p className="text-danger" style={{ fontSize: '0.75rem', marginTop: '0.5rem' }}>{errors.newPassword.message}</p>
          )}
        </div>

        <div>
          <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)' }}>
            Xác nhận mật khẩu mới
          </label>
          <input
            type="password"
            {...register('confirmPassword')}
            style={{ width: '100%', borderColor: errors.confirmPassword ? 'var(--danger)' : undefined }}
            placeholder="Nhập lại mật khẩu mới"
          />
          {errors.confirmPassword && (
            <p className="text-danger" style={{ fontSize: '0.75rem', marginTop: '0.5rem' }}>{errors.confirmPassword.message}</p>
          )}
        </div>

        <Button
          type="submit"
          variant="primary"
          size="lg"
          style={{ width: '100%', marginTop: '0.5rem' }}
          isLoading={isSubmitting}
        >
          Xác nhận đổi mật khẩu
        </Button>
      </form>
    </div>
  );
};

export default ChangePassword;
