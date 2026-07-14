import { z } from 'zod';

export const createMerchantSchema = z.object({
  merchant_code: z.string().min(3, 'Mã Merchant tối thiểu 3 ký tự'),
  merchant_name: z.string().min(2, 'Tên Merchant tối thiểu 2 ký tự'),
  business_type: z.enum(['ONLINE', 'OFFLINE', 'BOTH']),
  email: z.string().email('Email không hợp lệ'),
  phone: z.string().min(10, 'Số điện thoại không hợp lệ'),
  callback: z.object({
    default_callback_url: z.string().url('URL không hợp lệ').optional().or(z.literal('')),
    default_redirect_url: z.string().url('URL không hợp lệ').optional().or(z.literal('')),
  }).optional(),
  create_owner: z.boolean(),
  owner: z.object({
    username: z.string().optional(),
    full_name: z.string().optional(),
    email: z.string().email('Email Owner không hợp lệ').optional().or(z.literal('')),
    phone: z.string().optional(),
  }).optional(),
  create_default_api_key: z.boolean(),
});

export type CreateMerchantFormValues = z.infer<typeof createMerchantSchema>;

export const configWebhookSchema = z.object({
  default_callback_url: z.string().url('Webhook URL không hợp lệ'),
  default_redirect_url: z.string().url('Redirect URL không hợp lệ'),
});

export type ConfigWebhookFormValues = z.infer<typeof configWebhookSchema>;
