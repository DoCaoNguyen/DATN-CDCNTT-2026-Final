import { z } from 'zod';
import type { UseFormSetError } from 'react-hook-form';

// --- SCHEMAS ---

export const fullNameSchema = z.string()
  .trim()
  .min(1, 'Họ tên là bắt buộc.')
  .max(25, 'Họ tên không được vượt quá 25 ký tự.')
  .regex(/^[\p{L}\p{M}\s\-']+$/u, 'Họ tên không được chứa số hoặc ký tự đặc biệt.')
  .refine(val => val.trim().split(/\s+/).length >= 2, 'Họ tên phải có ít nhất 2 từ.');

export const vietnamMobilePhoneSchema = z.string()
  .trim()
  .min(1, 'Số điện thoại là bắt buộc.')
  .transform(val => {
    let cleaned = val.replace(/[\s\-\(\)]/g, '');
    if (cleaned.startsWith('+84')) cleaned = '0' + cleaned.slice(3);
    else if (cleaned.startsWith('84') && cleaned.length > 9) cleaned = '0' + cleaned.slice(2);
    return cleaned;
  })
  .refine(val => /^0[35789]\d{8}$/.test(val), 'SĐT di động VN phải có 10 số và bắt đầu bằng 03, 05, 07, 08, 09 (vd: 0912345678).');

export const optionalVietnamPhoneSchema = z.string().trim()
  .transform(val => {
    if (!val) return undefined;
    let cleaned = val.replace(/[\s\-\(\)]/g, '');
    if (cleaned.startsWith('+84')) cleaned = '0' + cleaned.slice(3);
    else if (cleaned.startsWith('84') && cleaned.length > 9) cleaned = '0' + cleaned.slice(2);
    return cleaned;
  })
  .superRefine((val, ctx) => {
    if (val === undefined) return;
    if (!/^0[35789]\d{8}$/.test(val)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'SĐT di động VN phải có 10 số và bắt đầu bằng 03, 05, 07, 08, 09 (vd: 0912345678).'
      });
    }
  });

export const usernameSchema = z.string()
  .trim()
  .min(3, 'Tên đăng nhập phải có ít nhất 3 ký tự.')
  .max(50, 'Tên đăng nhập không được vượt quá 50 ký tự.')
  .regex(/^[a-zA-Z0-9_\.]+$/, 'Tên đăng nhập chỉ được chứa chữ cái không dấu, số, dấu gạch dưới và dấu chấm.');

export const emailSchema = z.string()
  .trim()
  .min(1, 'Email là bắt buộc.')
  .email('Định dạng email không hợp lệ.');

export const merchantNameSchema = z.string()
  .trim()
  .min(1, 'Tên đối tác là bắt buộc.')
  .max(150, 'Tên đối tác không được vượt quá 150 ký tự.');

export const taxCodeSchema = z.string()
  .trim()
  .min(1, 'Mã số thuế là bắt buộc.')
  .regex(/^[0-9\-]+$/, 'Mã số thuế chỉ được chứa số và dấu gạch nối.');

export const httpUrlSchema = z.string()
  .trim()
  .min(1, 'URL là bắt buộc.')
  .url('Định dạng URL không hợp lệ (phải bắt đầu bằng http:// hoặc https://)')
  .regex(/^https?:\/\//, 'Định dạng URL không hợp lệ (phải bắt đầu bằng http:// hoặc https://)');

// --- MAPPING HELPERS ---

export const mapRoleToVietnamese = (role: string): string => {
  const map: Record<string, string> = {
    'USER': 'Người dùng Ví',
    'MERCHANT_USER': 'Nhân viên Đối tác',
    'MERCHANT_OWNER': 'Chủ Đối tác',
    'ADMIN': 'Quản trị viên',
    'SUPER_ADMIN': 'Quản trị viên Cấp cao',
    'SUPPORT_STAFF': 'Nhân viên Hỗ trợ',
  };
  return map[role] || role;
};

export const mapStatusToVietnamese = (status: string): string => {
  const map: Record<string, string> = {
    'ACTIVE': 'Đang hoạt động',
    'PENDING_VERIFY': 'Chờ xác thực',
    'LOCKED': 'Bị khóa',
    'BLOCKED': 'Bị chặn',
    'INACTIVE': 'Ngừng hoạt động',
    'PENDING_REVIEW': 'Chờ xét duyệt',
    'SUSPENDED': 'Bị đình chỉ',
    'REJECTED': 'Bị từ chối',
    'CLOSED': 'Đã đóng',
  };
  return map[status] || status;
};

export const mapBusinessTypeToVietnamese = (type: string): string => {
  const map: Record<string, string> = {
    'ONLINE': 'Trực tuyến',
    'OFFLINE': 'Trực tiếp',
    'BOTH': 'Trực tuyến & Trực tiếp',
  };
  return map[type] || type;
};

// --- ERROR HANDLING HELPERS ---

export interface ApiValidationError {
  field: string;
  code: string;
  message: string;
}

export interface ApiErrorResponse {
  success: boolean;
  code: string;
  message: string;
  errors?: ApiValidationError[];
}

/**
 * Hàm map lỗi từ API trả về vào React Hook Form setError
 */
export const mapApiErrorsToForm = (
  apiErrors: ApiValidationError[],
  setError: UseFormSetError<any>,
  prefix: string = ''
) => {
  if (!apiErrors || !Array.isArray(apiErrors)) return;
  apiErrors.forEach(err => {
    setError(`${prefix}${err.field}`, {
      type: 'server',
      message: err.message
    });
  });
};

/**
 * Hàm map lỗi từ API trả về thành object dạng { fieldName: errorMessage } (dùng cho setState thuần)
 */
export const mapApiErrorsToState = (
  apiErrors: ApiValidationError[],
  prefix: string = ''
): Record<string, string> => {
  const errorMap: Record<string, string> = {};
  if (!apiErrors || !Array.isArray(apiErrors)) return errorMap;
  apiErrors.forEach(err => {
    errorMap[`${prefix}${err.field}`] = err.message;
  });
  return errorMap;
};
