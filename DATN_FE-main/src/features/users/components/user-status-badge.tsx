import { Badge } from '../../../components/ui/badge';

interface UserStatusBadgeProps {
  status: string;
}

export function UserStatusBadge({ status }: UserStatusBadgeProps) {
  switch (status) {
    case 'ACTIVE':
      return <Badge variant="outline" className="bg-emerald-50 text-emerald-700 border-emerald-200">HOẠT ĐỘNG</Badge>;
    case 'PENDING_VERIFY':
      return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">CHỜ XÁC THỰC</Badge>;
    case 'INACTIVE':
      return <Badge variant="outline" className="bg-slate-50 text-slate-700 border-slate-200">CHƯA KÍCH HOẠT</Badge>;
    case 'LOCKED':
    case 'BLOCKED':
    case 'SUSPENDED':
      return <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">BỊ KHÓA</Badge>;
    default:
      return <Badge variant="outline">{status}</Badge>;
  }
}
