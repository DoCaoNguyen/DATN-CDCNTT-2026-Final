import { z } from 'zod';

export const createUserSchema = z.object({
  username: z.string().min(3, 'Username phải có ít nhất 3 ký tự').max(50, 'Username tối đa 50 ký tự'),
  full_name: z.string().min(2, 'Họ tên phải có ít nhất 2 ký tự').max(100, 'Họ tên tối đa 100 ký tự'),
  phone: z.string().regex(/^(0|\+84)[1-9][0-9]{8}$/, 'Số điện thoại không hợp lệ (ví dụ: 0912345678)'),
  email: z.string().email('Email không hợp lệ').optional().or(z.literal('')),
});

export type CreateUserFormValues = z.infer<typeof createUserSchema>;

export const resetPasswordSchema = z.object({
  new_password: z.string().min(8, 'Mật khẩu phải có ít nhất 8 ký tự'),
  confirm_new_password: z.string(),
  reason: z.string().min(5, 'Vui lòng nhập lý do (ít nhất 5 ký tự)'),
}).refine((data) => data.new_password === data.confirm_new_password, {
  message: "Mật khẩu xác nhận không khớp",
  path: ["confirm_new_password"],
});

export type ResetPasswordFormValues = z.infer<typeof resetPasswordSchema>;
