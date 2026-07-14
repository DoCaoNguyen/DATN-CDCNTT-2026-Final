import { useState } from 'react';
import { Dialog, DialogHeader, DialogTitle, DialogFooter } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';
import { Textarea } from '../../../components/ui/textarea';
import type { Wallet } from '../types/wallet.type';

interface WalletActionDialogProps {
  wallet: Wallet | null;
  action: 'LOCK' | 'UNLOCK' | null;
  open: boolean;
  onClose: () => void;
  onConfirm: (walletId: string, reason?: string) => void;
  isProcessing: boolean;
}

export function WalletActionDialog({ wallet, action, open, onClose, onConfirm, isProcessing }: WalletActionDialogProps) {
  const [reason, setReason] = useState('');

  if (!wallet || !action) return null;

  const handleConfirm = () => {
    onConfirm(wallet.id, action === 'LOCK' ? reason : undefined);
  };

  const isLock = action === 'LOCK';

  return (
    <Dialog open={open} onClose={() => {
      setReason('');
      onClose();
    }}>
      <DialogHeader>
        <DialogTitle>{isLock ? 'Khóa Ví Hệ Thống' : 'Mở Khóa Ví'}</DialogTitle>
      </DialogHeader>

      <div className="py-4 space-y-4">
        <p className="text-sm text-slate-600">
          Bạn đang thao tác với ví <span className="font-bold font-mono text-slate-800">{wallet.wallet_no}</span> 
          của người dùng <span className="font-bold text-slate-800">{wallet.user?.full_name || wallet.full_name || 'N/A'}</span>.
        </p>

        {isLock && (
          <div className="space-y-2">
            <label className="text-sm font-semibold text-slate-700">
              Lý do khóa (Bắt buộc) <span className="text-red-500">*</span>
            </label>
            <Textarea 
              value={reason} 
              onChange={(e) => setReason(e.target.value)} 
              placeholder="Gian lận, yêu cầu từ user..." 
              rows={3}
            />
          </div>
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
          variant={isLock ? 'danger' : 'primary'}
          className={!isLock ? 'bg-emerald-600 hover:bg-emerald-700 text-white' : ''}
          onClick={handleConfirm}
          disabled={isProcessing || (isLock && !reason.trim())}
        >
          {isProcessing ? 'Đang xử lý...' : (isLock ? 'Xác nhận khóa' : 'Xác nhận mở')}
        </Button>
      </DialogFooter>
    </Dialog>
  );
}
