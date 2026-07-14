import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogTitle, DialogFooter } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';
import { Input } from '../../../components/ui/input';
import { configWebhookSchema, type ConfigWebhookFormValues } from '../schemas/merchant.schema';
import { useConfigWebhook } from '../hooks/use-merchant-actions';
import toast from 'react-hot-toast';
import { Loader2 } from 'lucide-react';
import type { Merchant } from '../types/merchant.type';

interface MerchantWebhookDialogProps {
  merchant: Merchant | null;
  open: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

export function MerchantWebhookDialog({ merchant, open, onClose, onSuccess }: MerchantWebhookDialogProps) {
  const { register, handleSubmit, formState: { errors }, reset } = useForm<ConfigWebhookFormValues>({
    resolver: zodResolver(configWebhookSchema)
  });

  const configMutation = useConfigWebhook();

  useEffect(() => {
    if (merchant && open) {
      reset({
        default_callback_url: merchant.default_callback_url || '',
        default_redirect_url: merchant.default_redirect_url || ''
      });
    }
  }, [merchant, open, reset]);

  if (!merchant) return null;

  const onSubmit = (data: ConfigWebhookFormValues) => {
    configMutation.mutate({ merchantId: merchant.id, data }, {
      onSuccess: () => {
        toast.success('Cấu hình Webhook thành công');
        reset();
        onClose();
        if (onSuccess) onSuccess();
      },
      onError: (error: any) => {
        toast.error(error.response?.data?.error || 'Lỗi khi cấu hình Webhook');
      }
    });
  };

  return (
    <Dialog open={open} onClose={() => { reset(); onClose(); }}>
      <DialogHeader>
        <DialogTitle>Cấu hình Webhook</DialogTitle>
      </DialogHeader>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 py-4">
        <p className="text-sm text-slate-500">
          Merchant: <span className="font-bold text-slate-800">{merchant.merchant_name}</span>
        </p>

        <div className="space-y-1">
          <label className="text-sm font-semibold text-slate-700">Default Callback URL <span className="text-red-500">*</span></label>
          <Input {...register('default_callback_url')} type="url" placeholder="https://api.merchant.com/webhook" />
          {errors.default_callback_url && <p className="text-red-500 text-xs">{errors.default_callback_url.message}</p>}
        </div>

        <div className="space-y-1">
          <label className="text-sm font-semibold text-slate-700">Default Redirect URL <span className="text-red-500">*</span></label>
          <Input {...register('default_redirect_url')} type="url" placeholder="https://merchant.com/payment-result" />
          {errors.default_redirect_url && <p className="text-red-500 text-xs">{errors.default_redirect_url.message}</p>}
        </div>

        <DialogFooter>
          <Button type="button" variant="outline" onClick={() => { reset(); onClose(); }}>
            Hủy bỏ
          </Button>
          <Button type="submit" disabled={configMutation.isPending} className="bg-indigo-600 hover:bg-indigo-700 text-white">
            {configMutation.isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Lưu cấu hình
          </Button>
        </DialogFooter>
      </form>
    </Dialog>
  );
}
