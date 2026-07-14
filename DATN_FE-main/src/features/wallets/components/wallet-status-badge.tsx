import { Badge } from '../../../components/ui/badge';

interface WalletStatusBadgeProps {
  status: string;
}

export function WalletStatusBadge({ status }: WalletStatusBadgeProps) {
  switch (status) {
    case 'ACTIVE':
      return <Badge variant="outline" className="bg-emerald-50 text-emerald-700 border-emerald-200">ACTIVE</Badge>;
    case 'LOCKED':
      return <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">LOCKED</Badge>;
    case 'CLOSED':
      return <Badge variant="outline" className="bg-slate-50 text-slate-600 border-slate-200">CLOSED</Badge>;
    default:
      return <Badge variant="outline">{status}</Badge>;
  }
}
