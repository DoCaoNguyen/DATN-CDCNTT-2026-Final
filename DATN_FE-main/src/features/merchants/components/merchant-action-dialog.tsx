import { useState } from 'react';
import { Dialog, DialogHeader, DialogTitle, DialogFooter } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';
import { Textarea } from '../../../components/ui/textarea';
import type { Merchant } from '../types/merchant.type';

interface MerchantActionDialogProps {
  merchant: Merchant | null;
  action: 'APPROVE' | 'REJECT' | 'SUSPEND' | 'ACTIVATE' | 'GENERATE_KEY' | null;
  open: boolean;
  onClose: () => void;
  onConfirm: (merchantId: string, reason?: string) => void;
  isProcessing: boolean;
}

export function MerchantActionDialog({ merchant, action, open, onClose, onConfirm, isProcessing }: MerchantActionDialogProps) {
  const [reason, setReason] = useState('');

  if (!merchant || !action) return null;

  const handleConfirm = () => {
    onConfirm(merchant.id, reason);
  };

  const isReject = action === 'REJECT';
  const isSuspend = action === 'SUSPEND';
  const requiresReason = isReject || isSuspend;
  
  const getTitle = () => {
    switch(action) {
      case 'APPROVE': return 'Duyệt Merchant';
      case 'REJECT': return 'Từ chối Merchant';
      case 'SUSPEND': return 'Tạm ngưng Merchant';
      case 'ACTIVATE': return 'Khôi phục Merchant';
      case 'GENERATE_KEY': return 'Cấp lại API Key';
      default: return '';
    }
  };

  const getMessage = () => {
    switch(action) {
      case 'APPROVE': return 'Xác nhận duyệt Merchant này?';
      case 'ACTIVATE': return 'Xác nhận khôi phục hoạt động cho Merchant này?';
      case 'GENERATE_KEY': return 'Xác nhận cấp lại/tạo mới API Key cho Merchant này? Key cũ sẽ bị vô hiệu hóa.';
      default: return '';
    }
  };

  const getButtonClass = () => {
    switch(action) {
      case 'REJECT': return 'bg-red-600 hover:bg-red-700 text-white';
      case 'SUSPEND': return 'bg-orange-500 hover:bg-orange-600 text-white';
      case 'APPROVE': 
      case 'ACTIVATE': return 'bg-emerald-600 hover:bg-emerald-700 text-white';
      case 'GENERATE_KEY': return 'bg-blue-600 hover:bg-blue-700 text-white';
      default: return '';
    }
  };

  return (
    <Dialog open={open} onClose={() => {
      setReason('');
      onClose();
    }}>
      <DialogHeader>
        <DialogTitle>{getTitle()}</DialogTitle>
      </DialogHeader>

      <div className="py-4 space-y-4">
        <p className="text-sm text-slate-600">
          Merchant: <span className="font-bold text-slate-800">{merchant.merchant_name}</span>
        </p>

        {requiresReason ? (
          <div className="space-y-2">
            <label className="text-sm font-semibold text-slate-700">
              Lý do (Bắt buộc) <span className="text-red-500">*</span>
            </label>
            <Textarea 
              value={reason} 
              onChange={(e) => setReason(e.target.value)} 
              placeholder={isReject ? "Nhập lý do từ chối..." : "Nhập lý do tạm ngưng..."} 
              rows={3}
            />
          </div>
        ) : (
          <p className="text-sm font-medium text-slate-700">{getMessage()}</p>
        )}
      </div>

      <DialogFooter>
        <Button variant="outline" onClick={() => {
          setReason('');
          onClose();
        }}>
          Hủy
        </Button>
        <Button 
          className={getButtonClass()}
          onClick={handleConfirm}
          disabled={isProcessing || (requiresReason && !reason.trim())}
        >
          {isProcessing ? 'Đang xử lý...' : 'Xác nhận'}
        </Button>
      </DialogFooter>
    </Dialog>
  );
}
