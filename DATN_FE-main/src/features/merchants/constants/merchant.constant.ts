export const MERCHANT_STATUSES = [
  { value: 'ACTIVE', label: 'Hoạt động (Active)' },
  { value: 'PENDING', label: 'Chờ duyệt (Pending)' },
  { value: 'PENDING_REVIEW', label: 'Chờ duyệt (Pending Review)' },
  { value: 'SUSPENDED', label: 'Tạm ngưng (Suspended)' },
  { value: 'REJECTED', label: 'Từ chối (Rejected)' },
] as const;
