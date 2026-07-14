import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../../components/ui/table';
import { EmptyState } from '../../../components/common/empty-state';
import { LoadingState } from '../../../components/common/loading-state';
import { CopyableText } from '../../../components/common/copyable-text';
import { Button } from '../../../components/ui/button';
import { Store, Key, Webhook, CheckCircle, XCircle, Ban, RefreshCcw } from 'lucide-react';
import { MerchantStatusBadge } from './merchant-status-badge';
import type { Merchant } from '../types/merchant.type';

interface MerchantTableProps {
  merchants: Merchant[];
  isLoading: boolean;
  onAction: (merchant: Merchant, action: 'APPROVE' | 'REJECT' | 'SUSPEND' | 'ACTIVATE' | 'GENERATE_KEY' | 'CONFIG_WEBHOOK') => void;
}

export function MerchantTable({ merchants, isLoading, onAction }: MerchantTableProps) {
  if (isLoading) return <LoadingState message="Đang tải danh sách Merchant..." />;
  if (merchants.length === 0) return <EmptyState description="Không tìm thấy dữ liệu Merchant." />;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Merchant</TableHead>
            <TableHead>Cấu hình Tích hợp</TableHead>
            <TableHead className="text-center">Trạng thái</TableHead>
            <TableHead className="text-center">Thao tác</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {merchants.map((m) => (
            <TableRow key={m.id}>
              <TableCell>
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600">
                    <Store className="w-5 h-5" />
                  </div>
                  <div>
                    <p className="font-bold text-slate-800">{m.merchant_name}</p>
                    <div className="flex items-center text-xs text-slate-500 font-mono mt-0.5 space-x-1">
                      <CopyableText text={m.merchant_code} className="truncate max-w-[150px]" /> 
                      <span>• {m.business_type}</span>
                    </div>
                  </div>
                </div>
              </TableCell>
              <TableCell>
                <div className="flex flex-col space-y-1">
                  <span className="text-xs text-slate-500 flex items-center">
                    <Key className="w-3 h-3 mr-1" /> API Key: 
                    <strong className="ml-1 text-slate-700">{m.api_key ? 'Đã cấp' : 'Chưa cấp'}</strong>
                  </span>
                  <span className="text-xs text-slate-500 flex items-center">
                    <Webhook className="w-3 h-3 mr-1" /> Webhook: 
                    <strong className="ml-1 text-slate-700 truncate max-w-[150px]" title={m.default_callback_url || ''}>
                      {m.default_callback_url || 'Chưa cấu hình'}
                    </strong>
                  </span>
                </div>
              </TableCell>
              <TableCell className="text-center">
                <MerchantStatusBadge status={m.status} />
              </TableCell>
              <TableCell>
                <div className="flex items-center justify-center flex-wrap gap-2">
                  {(m.status === 'PENDING' || m.status === 'PENDING_REVIEW') && (
                    <>
                      <Button variant="outline" size="sm" onClick={() => onAction(m, 'APPROVE')} className="text-emerald-600 bg-emerald-50 hover:bg-emerald-100 hover:text-emerald-700 border-none px-3 py-1.5 h-auto text-xs">
                        <CheckCircle className="w-3.5 h-3.5 mr-1" /> Duyệt
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => onAction(m, 'REJECT')} className="text-red-600 bg-red-50 hover:bg-red-100 hover:text-red-700 border-none px-3 py-1.5 h-auto text-xs">
                        <XCircle className="w-3.5 h-3.5 mr-1" /> Từ chối
                      </Button>
                    </>
                  )}
                  
                  {m.status === 'ACTIVE' && (
                    <>
                      <Button variant="outline" size="sm" onClick={() => onAction(m, 'GENERATE_KEY')} className="text-blue-600 bg-blue-50 hover:bg-blue-100 hover:text-blue-700 border-none px-3 py-1.5 h-auto text-xs">
                        <Key className="w-3.5 h-3.5 mr-1" /> Cấp Key
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => onAction(m, 'CONFIG_WEBHOOK')} className="text-indigo-600 bg-indigo-50 hover:bg-indigo-100 hover:text-indigo-700 border-none px-3 py-1.5 h-auto text-xs">
                        <Webhook className="w-3.5 h-3.5 mr-1" /> Cấu hình
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => onAction(m, 'SUSPEND')} className="text-orange-600 bg-orange-50 hover:bg-orange-100 hover:text-orange-700 border-none px-3 py-1.5 h-auto text-xs">
                        <Ban className="w-3.5 h-3.5 mr-1" /> Ngưng
                      </Button>
                    </>
                  )}

                  {m.status === 'SUSPENDED' && (
                    <Button variant="outline" size="sm" onClick={() => onAction(m, 'ACTIVATE')} className="text-emerald-600 bg-emerald-50 hover:bg-emerald-100 hover:text-emerald-700 border-none px-3 py-1.5 h-auto text-xs">
                      <RefreshCcw className="w-3.5 h-3.5 mr-1" /> Khôi phục
                    </Button>
                  )}
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
