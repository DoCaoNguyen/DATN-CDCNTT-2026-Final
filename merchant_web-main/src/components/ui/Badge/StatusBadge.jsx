import { Badge } from '../Badge/Badge';

const STATUS_MAP = {
  ACTIVE: 'Hoạt động',
  INACTIVE: 'Ngừng hoạt động',
  SUCCESS: 'Thành công',
  PAID: 'Đã thanh toán',
  PENDING: 'Đang xử lý',
  RETRYING: 'Đang thử lại',
  FAILED: 'Thất bại',
  REVOKED: 'Đã thu hồi',
  EXPIRED: 'Hết hạn',
  CANCELED: 'Đã hủy',
  SANDBOX: 'Thử nghiệm',
  LIVE: 'Chính thức',
};

export const StatusBadge = ({ status }) => {
  if (!status) return <Badge variant="default"> </Badge>;

  const s = status.toUpperCase();
  let variant = 'default';

  if (['ACTIVE', 'SUCCESS', 'PAID'].includes(s)) variant = 'success';
  else if (['PENDING', 'RETRYING'].includes(s)) variant = 'warning';
  else if (['FAILED', 'REVOKED', 'CANCELED'].includes(s)) variant = 'danger';
  else if (['EXPIRED'].includes(s)) variant = 'warning';
  else if (['SANDBOX'].includes(s)) variant = 'info';
  else if (['LIVE'].includes(s)) variant = 'live';

  const label = STATUS_MAP[s] || status;

  return <Badge variant={variant}>{label}</Badge>;
};
