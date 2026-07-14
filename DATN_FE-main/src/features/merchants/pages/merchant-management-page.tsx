import { useState } from 'react';
import { PageHeader } from '../../../components/common/page-header';
import { ErrorState } from '../../../components/common/error-state';
import { MerchantFilters } from '../components/merchant-filters';
import { MerchantTable } from '../components/merchant-table';
import { MerchantActionDialog } from '../components/merchant-action-dialog';
import { MerchantCreateDialog } from '../components/merchant-create-dialog';
import { MerchantWebhookDialog } from '../components/merchant-webhook-dialog';
import { useMerchants } from '../hooks/use-merchants';
import { 
  useApproveMerchant, 
  useRejectMerchant, 
  useSuspendMerchant, 
  useActivateMerchant, 
  useGenerateApiKey 
} from '../hooks/use-merchant-actions';
import type { MerchantQueryParams, Merchant } from '../types/merchant.type';
import { ChevronLeft, ChevronRight, CheckCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { Dialog, DialogHeader, DialogTitle } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';

export default function MerchantManagementPage() {
  const [filters, setFilters] = useState<MerchantQueryParams>({ search: '', page: 1, limit: 10 });
  
  const { data, isLoading, isError, error, refetch } = useMerchants(filters);
  const merchants = data?.items || [];
  const total = data?.total || 0;
  const totalPages = Math.ceil(total / (filters.limit || 10)) || 1;

  // Dialog states
  const [showCreate, setShowCreate] = useState(false);
  
  const [actionMerchant, setActionMerchant] = useState<Merchant | null>(null);
  const [actionType, setActionType] = useState<'APPROVE' | 'REJECT' | 'SUSPEND' | 'ACTIVATE' | 'GENERATE_KEY' | 'CONFIG_WEBHOOK' | null>(null);

  // Success Info Display (API Key / Password)
  const [successInfo, setSuccessInfo] = useState<{
    temporary_password?: string;
    api_key?: string;
    api_secret?: string;
  } | null>(null);
  
  const approveMutation = useApproveMerchant();
  const rejectMutation = useRejectMerchant();
  const suspendMutation = useSuspendMerchant();
  const activateMutation = useActivateMerchant();
  const generateKeyMutation = useGenerateApiKey();

  const handleActionConfirm = (merchantId: string, reason?: string) => {
    const handleError = (error: any, defaultMsg: string) => {
      toast.error(error.response?.data?.error || defaultMsg);
    };

    const handleSuccess = (msg: string) => {
      toast.success(msg);
      setActionMerchant(null);
      setActionType(null);
    };

    switch(actionType) {
      case 'APPROVE':
        approveMutation.mutate(merchantId, {
          onSuccess: () => handleSuccess('Đã duyệt Merchant thành công'),
          onError: (err) => handleError(err, 'Lỗi khi duyệt Merchant')
        });
        break;
      case 'REJECT':
        rejectMutation.mutate({ merchantId, reason: reason || '' }, {
          onSuccess: () => handleSuccess('Đã từ chối Merchant'),
          onError: (err) => handleError(err, 'Lỗi khi từ chối Merchant')
        });
        break;
      case 'SUSPEND':
        suspendMutation.mutate({ merchantId, reason: reason || '' }, {
          onSuccess: () => handleSuccess('Đã tạm ngưng Merchant'),
          onError: (err) => handleError(err, 'Lỗi khi tạm ngưng Merchant')
        });
        break;
      case 'ACTIVATE':
        activateMutation.mutate(merchantId, {
          onSuccess: () => handleSuccess('Đã khôi phục hoạt động Merchant'),
          onError: (err) => handleError(err, 'Lỗi khi khôi phục Merchant')
        });
        break;
      case 'GENERATE_KEY':
        generateKeyMutation.mutate(merchantId, {
          onSuccess: (res: any) => {
            const payloadData = res.data || res;
            if (payloadData.api_key || payloadData.api_secret) {
              setSuccessInfo({
                api_key: payloadData.api_key,
                api_secret: payloadData.api_secret,
              });
            } else {
              toast.success('Đã cấp API Key thành công! Vui lòng kiểm tra email merchant.');
            }
            setActionMerchant(null);
            setActionType(null);
          },
          onError: (err) => handleError(err, 'Lỗi khi cấp API Key')
        });
        break;
    }
  };

  const handleCreateSuccess = (info: { temporary_password?: string; api_key?: string; api_secret?: string }) => {
    setShowCreate(false);
    if (info.temporary_password || info.api_secret) {
      setSuccessInfo(info);
    } else {
      setFilters(prev => ({ ...prev, page: 1 }));
    }
  };

  const isProcessing = approveMutation.isPending || rejectMutation.isPending || suspendMutation.isPending || activateMutation.isPending || generateKeyMutation.isPending;

  return (
    <div className="w-full max-w-7xl mx-auto pb-10 space-y-6 animate-in fade-in duration-500">
      <PageHeader 
        title="Quản lý Merchant" 
        description="Đăng ký, cấp API Key, cấu hình Webhook và giám sát Đối tác."
      />

      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200">
        <MerchantFilters 
          initialFilters={filters} 
          onFilterChange={setFilters} 
          onCreateMerchant={() => setShowCreate(true)} 
        />
      </div>

      {isError ? (
        <ErrorState 
          error={error?.message || 'Có lỗi xảy ra khi tải danh sách Merchant'} 
          onRetry={() => refetch()} 
        />
      ) : (
        <div className="space-y-4">
          <MerchantTable 
            merchants={merchants} 
            isLoading={isLoading} 
            onAction={(merchant, action) => {
              setActionMerchant(merchant);
              setActionType(action);
            }} 
          />
          
          {totalPages > 1 && (
            <div className="flex justify-center items-center space-x-4 pt-2">
              <button 
                disabled={filters.page === 1} 
                onClick={() => setFilters(prev => ({ ...prev, page: (prev.page || 1) - 1 }))} 
                className="px-4 py-2 rounded-lg border bg-white text-slate-600 hover:bg-slate-100 disabled:opacity-50 text-sm font-semibold flex items-center shadow-sm"
              >
                <ChevronLeft className="w-4 h-4 mr-1" /> Trước
              </button>
              <span className="text-sm font-semibold text-slate-700">Trang {filters.page} / {totalPages}</span>
              <button 
                disabled={filters.page! >= totalPages} 
                onClick={() => setFilters(prev => ({ ...prev, page: (prev.page || 1) + 1 }))} 
                className="px-4 py-2 rounded-lg border bg-white text-slate-600 hover:bg-slate-100 disabled:opacity-50 text-sm font-semibold flex items-center shadow-sm"
              >
                Sau <ChevronRight className="w-4 h-4 ml-1" />
              </button>
            </div>
          )}
        </div>
      )}

      {/* Dialogs */}
      <MerchantCreateDialog 
        open={showCreate} 
        onClose={() => setShowCreate(false)} 
        onSuccess={handleCreateSuccess} 
      />

      <MerchantActionDialog 
        merchant={actionType !== 'CONFIG_WEBHOOK' ? actionMerchant : null}
        action={actionType !== 'CONFIG_WEBHOOK' ? actionType : null}
        open={!!actionType && actionType !== 'CONFIG_WEBHOOK'}
        onClose={() => {
          setActionMerchant(null);
          setActionType(null);
        }}
        onConfirm={handleActionConfirm}
        isProcessing={isProcessing}
      />

      <MerchantWebhookDialog 
        merchant={actionType === 'CONFIG_WEBHOOK' ? actionMerchant : null}
        open={actionType === 'CONFIG_WEBHOOK'}
        onClose={() => {
          setActionMerchant(null);
          setActionType(null);
        }}
      />

      {/* Success Credentials Dialog */}
      <Dialog open={!!successInfo} onClose={() => {}}>
        <DialogHeader>
          <DialogTitle className="flex items-center text-emerald-600">
            <CheckCircle className="w-5 h-5 mr-2" /> 
            Thông tin bảo mật quan trọng
          </DialogTitle>
        </DialogHeader>
        <div className="py-4">
          <p className="text-sm text-slate-500 mb-4">
            Lưu ý: Mật khẩu và API Secret chỉ hiển thị <strong className="text-red-500">MỘT LẦN DUY NHẤT</strong>. Vui lòng sao chép ngay.
          </p>
          
          <div className="space-y-4">
            {successInfo?.temporary_password && (
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">Mật khẩu Owner (Tạm thời)</label>
                <div className="flex items-center space-x-2">
                  <input readOnly type="text" value={successInfo.temporary_password} className="flex-1 p-2 border border-slate-200 rounded-lg bg-slate-50 font-mono text-indigo-600 font-bold outline-none" />
                  <Button onClick={() => { navigator.clipboard.writeText(successInfo.temporary_password!); toast.success('Đã copy!'); }} variant="outline" className="text-indigo-700 border-indigo-200 hover:bg-indigo-50">Copy</Button>
                </div>
              </div>
            )}
            
            {successInfo?.api_key && (
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">API Key</label>
                <div className="flex items-center space-x-2">
                  <input readOnly type="text" value={successInfo.api_key} className="flex-1 p-2 border border-slate-200 rounded-lg bg-slate-50 font-mono outline-none" />
                  <Button onClick={() => { navigator.clipboard.writeText(successInfo.api_key!); toast.success('Đã copy!'); }} variant="outline">Copy</Button>
                </div>
              </div>
            )}
            
            {successInfo?.api_secret && (
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">API Secret</label>
                <div className="flex items-center space-x-2">
                  <input readOnly type="text" value={successInfo.api_secret} className="flex-1 p-2 border border-red-200 rounded-lg bg-red-50 font-mono text-red-600 font-bold outline-none" />
                  <Button onClick={() => { navigator.clipboard.writeText(successInfo.api_secret!); toast.success('Đã copy!'); }} variant="outline" className="text-red-700 border-red-200 hover:bg-red-50">Copy</Button>
                </div>
              </div>
            )}
          </div>
        </div>
        <div className="flex justify-end border-t border-slate-100 pt-4">
          <Button onClick={() => {
            setSuccessInfo(null);
            setFilters(prev => ({ ...prev, page: 1 }));
          }} className="bg-blue-600 hover:bg-blue-700 text-white">
            Hoàn thành
          </Button>
        </div>
      </Dialog>
    </div>
  );
}
