import { Badge } from '../../../components/ui/badge';

interface MerchantStatusBadgeProps {
  status: string;
}

export function MerchantStatusBadge({ status }: MerchantStatusBadgeProps) {
  switch (status) {
    case 'ACTIVE':
      return <Badge variant="outline" className="bg-emerald-50 text-emerald-700 border-emerald-200">HOẠT ĐỘNG</Badge>;
    case 'PENDING':
    case 'PENDING_REVIEW':
      return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">CHỜ DUYỆT</Badge>;
    case 'SUSPENDED':
      return <Badge variant="outline" className="bg-orange-50 text-orange-700 border-orange-200">TẠM NGƯNG</Badge>;
    case 'REJECTED':
      return <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">TỪ CHỐI</Badge>;
    default:
      return <Badge variant="outline">{status}</Badge>;
  }
}
