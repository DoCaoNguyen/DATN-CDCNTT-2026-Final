import { format } from 'date-fns';

export const formatCurrencyVND = (amount: number): string => {
  if (amount === undefined || amount === null) return '0 đ';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
};

export const formatVND = formatCurrencyVND; // backward compatibility

export const formatDateTime = (dateString: string | null | undefined): string => {
  if (!dateString) return 'N/A';
  try {
    return format(new Date(dateString), 'dd/MM/yyyy HH:mm');
  } catch {
    return 'Invalid Date';
  }
};

export const formatShortId = (id: string): string => {
  if (!id) return '';
  if (id.length <= 15) return id;
  return `${id.substring(0, 8)}...${id.substring(id.length - 7)}`;
};

export const formatDisplayPhone = (phone?: string | null): string => {
  if (!phone) return 'N/A';
  if (phone.startsWith('+84')) return '0' + phone.slice(3);
  if (phone.startsWith('84')) return '0' + phone.slice(2);
  return phone;
};

export const getStatusVariant = (status: string, context?: 'merchant' | 'user' | 'wallet' | string) => {
  const s = status?.toUpperCase() || '';
  
  let label = s;
  
  if (s === 'SUCCESS') label = 'Thành công';
  else if (s === 'PAID') label = 'Đã thanh toán';
  else if (s === 'COMPLETED') label = 'Hoàn thành';
  else if (s === 'VERIFIED') label = 'Đã xác thực';
  else if (s === 'ACTIVE') label = 'Hoạt động';
  else if (s === 'PROCESSING') label = 'Đang xử lý';
  else if (s === 'PENDING') label = 'Chờ xử lý';
  else if (s === 'PENDING_VERIFY') label = 'Chờ xác minh';
  else if (s === 'PENDING_REVIEW') label = 'Chờ duyệt';
  else if (s === 'USED') label = 'Đã sử dụng';
  else if (s === 'RETRYING') label = 'Đang thử lại';
  else if (s === 'FAILED') label = 'Thất bại';
  else if (s === 'REJECTED') label = 'Từ chối';
  else if (s === 'EXPIRED') label = 'Hết hạn';
  else if (s === 'CANCELED') label = 'Đã hủy';
  else if (s === 'INACTIVE') label = 'Ngừng hoạt động';
  else if (s === 'REFUNDED') label = 'Đã hoàn tiền';
  else if (s === 'REVERSED') label = 'Đã đảo ngược';
  else if (s === 'BLOCKED') label = 'Bị chặn';
  else if (s === 'LOCKED') label = 'Đã khóa';
  else if (s === 'SUSPENDED') {
    label = context === 'merchant' ? 'Tạm ngưng' : 'Đã khóa';
  }

  if (label === s) label = s || 'N/A'; // fallback

  switch (s) {
    case 'SUCCESS':
    case 'PAID':
    case 'COMPLETED':
    case 'VERIFIED':
      return { className: 'bg-emerald-100 text-emerald-700', label };
    case 'ACTIVE':
    case 'PROCESSING':
      return { className: 'bg-blue-100 text-blue-700', label };
    case 'PENDING':
    case 'PENDING_VERIFY':
    case 'PENDING_REVIEW':
      return { className: 'bg-amber-100 text-amber-700', label };
    case 'USED':
      return { className: 'bg-violet-100 text-violet-700', label };
    case 'RETRYING':
      return { className: 'bg-orange-100 text-orange-700', label };
    case 'FAILED':
    case 'LOCKED':
    case 'BLOCKED':
    case 'REJECTED':
    case 'SUSPENDED':
      return { className: 'bg-red-100 text-red-700', label };
    case 'EXPIRED':
    case 'CANCELED':
    case 'INACTIVE':
      return { className: 'bg-slate-200 text-slate-500', label };
    case 'REFUNDED':
    case 'REVERSED':
      return { className: 'bg-purple-100 text-purple-700', label };
    default:
      return { className: 'bg-slate-100 text-slate-700', label };
  }
};
