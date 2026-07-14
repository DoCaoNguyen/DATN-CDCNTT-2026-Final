export const TRANSACTION_TYPES = [
  { value: 'TOPUP', label: 'Nạp tiền (Topup)' },
  { value: 'TRANSFER', label: 'Chuyển tiền (Transfer)' },
  { value: 'PAYMENT', label: 'Thanh toán (Payment)' },
  { value: 'REFUND', label: 'Hoàn tiền (Refund)' }
] as const;

export const TRANSACTION_STATUSES = [
  { value: 'SUCCESS', label: 'Thành công' },
  { value: 'PENDING', label: 'Đang xử lý' },
  { value: 'FAILED', label: 'Thất bại' },
  { value: 'REVERSED', label: 'Đã đảo ngược' }
] as const;
