export const USER_STATUSES = [
  { value: 'ACTIVE', label: 'Hoạt động (Active)' },
  { value: 'PENDING_VERIFY', label: 'Chờ xác thực (Pending Verify)' },
  { value: 'LOCKED', label: 'Bị khóa (Locked)' },
  { value: 'BLOCKED', label: 'Bị chặn (Blocked)' },
  { value: 'INACTIVE', label: 'Chưa kích hoạt (Inactive)' },
  { value: 'SUSPENDED', label: 'Đình chỉ (Suspended)' },
] as const;
