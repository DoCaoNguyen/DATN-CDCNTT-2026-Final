import { Badge } from '../ui/badge';

type StatusType = 'ACTIVE' | 'INACTIVE' | 'PENDING' | 'LOCKED' | 'APPROVED' | 'REJECTED' | 'SUCCESS' | 'FAILED';

export function StatusBadge({ status, label }: { status: StatusType | string, label?: string }) {
  let variant: 'default' | 'success' | 'warning' | 'danger' = 'default';
  
  switch (status) {
    case 'ACTIVE':
    case 'APPROVED':
    case 'SUCCESS':
      variant = 'success';
      break;
    case 'PENDING':
      variant = 'warning';
      break;
    case 'INACTIVE':
    case 'LOCKED':
    case 'REJECTED':
    case 'FAILED':
      variant = 'danger';
      break;
  }

  return <Badge variant={variant}>{label || status}</Badge>;
}
