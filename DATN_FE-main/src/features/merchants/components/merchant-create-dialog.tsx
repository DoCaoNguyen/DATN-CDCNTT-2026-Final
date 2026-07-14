import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogTitle } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';
import { Input } from '../../../components/ui/input';
import { createMerchantSchema, type CreateMerchantFormValues } from '../schemas/merchant.schema';
import { useCreateMerchant } from '../hooks/use-merchant-actions';
import toast from 'react-hot-toast';
import { Loader2 } from 'lucide-react';

interface MerchantCreateDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: (info: { temporary_password?: string; api_key?: string; api_secret?: string }) => void;
}

export function MerchantCreateDialog({ open, onClose, onSuccess }: MerchantCreateDialogProps) {
  const { register, handleSubmit, watch, formState: { errors }, reset } = useForm<CreateMerchantFormValues>({
    resolver: zodResolver(createMerchantSchema),
    defaultValues: {
      business_type: 'ONLINE',
      create_owner: false,
      create_default_api_key: true,
    }
  });

  const watchCreateOwner = watch('create_owner');

  const createMutation = useCreateMerchant();

  const onSubmit = (data: CreateMerchantFormValues) => {
    createMutation.mutate(data, {
      onSuccess: (res: any) => {
        toast.success('Đăng ký Merchant thành công');
        const payloadData = res.data || res;
        reset();
        if (payloadData.temporary_password || payloadData.api_secret) {
          onSuccess({
            temporary_password: payloadData.temporary_password,
            api_key: payloadData.api_key,
            api_secret: payloadData.api_secret,
          });
        } else {
          onClose(); // Just close if no secret returned
        }
      },
      onError: (error: any) => {
        toast.error(error.response?.data?.error || 'Lỗi khi đăng ký Merchant');
      }
    });
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose}>
      <DialogHeader>
        <DialogTitle>Đăng ký Merchant mới</DialogTitle>
      </DialogHeader>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 py-4 max-h-[70vh] overflow-y-auto px-1">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Mã Merchant (Code) <span className="text-red-500">*</span></label>
            <Input {...register('merchant_code')} placeholder="MERCHANT_CODE" />
            {errors.merchant_code && <p className="text-red-500 text-xs">{errors.merchant_code.message}</p>}
          </div>
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Tên Doanh nghiệp <span className="text-red-500">*</span></label>
            <Input {...register('merchant_name')} placeholder="Tên cửa hàng" />
            {errors.merchant_name && <p className="text-red-500 text-xs">{errors.merchant_name.message}</p>}
          </div>
        </div>
        
        <div className="space-y-1">
          <label className="text-sm font-semibold text-slate-700">Loại hình</label>
          <select {...register('business_type')} className="w-full p-2.5 border border-slate-200 rounded-lg outline-none focus:ring-2 focus:ring-blue-500/20 bg-white">
            <option value="ONLINE">Online</option>
            <option value="OFFLINE">Offline</option>
            <option value="BOTH">Cả hai</option>
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Email liên hệ <span className="text-red-500">*</span></label>
            <Input {...register('email')} type="email" placeholder="email@merchant.com" />
            {errors.email && <p className="text-red-500 text-xs">{errors.email.message}</p>}
          </div>
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Số điện thoại <span className="text-red-500">*</span></label>
            <Input {...register('phone')} placeholder="09xxxxxxxx" />
            {errors.phone && <p className="text-red-500 text-xs">{errors.phone.message}</p>}
          </div>
        </div>

        <div className="space-y-1">
          <label className="text-sm font-semibold text-slate-700">Default Callback URL (Tùy chọn)</label>
          <Input {...register('callback.default_callback_url')} type="url" placeholder="https://api.merchant.com/webhook" />
          {errors.callback?.default_callback_url && <p className="text-red-500 text-xs">{errors.callback.default_callback_url.message}</p>}
        </div>

        <div className="space-y-1">
          <label className="text-sm font-semibold text-slate-700">Default Redirect URL (Tùy chọn)</label>
          <Input {...register('callback.default_redirect_url')} type="url" placeholder="https://merchant.com/result" />
          {errors.callback?.default_redirect_url && <p className="text-red-500 text-xs">{errors.callback.default_redirect_url.message}</p>}
        </div>

        <div className="pt-2 border-t border-slate-100">
          <label className="flex items-center space-x-2 cursor-pointer">
            <input type="checkbox" {...register('create_owner')} className="w-4 h-4 text-blue-600 rounded" />
            <span className="text-sm font-semibold text-slate-700">Tạo tài khoản Owner cho Merchant</span>
          </label>
        </div>

        {watchCreateOwner && (
          <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg space-y-3">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-sm font-semibold text-slate-700">Username Owner</label>
                <Input {...register('owner.username')} placeholder="username" />
              </div>
              <div className="space-y-1">
                <label className="text-sm font-semibold text-slate-700">Họ tên Owner</label>
                <Input {...register('owner.full_name')} placeholder="Họ và tên" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-sm font-semibold text-slate-700">SĐT Owner</label>
                <Input {...register('owner.phone')} placeholder="09xxxxxxxx" />
              </div>
              <div className="space-y-1">
                <label className="text-sm font-semibold text-slate-700">Email Owner</label>
                <Input {...register('owner.email')} type="email" placeholder="owner@merchant.com" />
              </div>
            </div>
          </div>
        )}

        <div>
          <label className="flex items-center space-x-2 cursor-pointer">
            <input type="checkbox" {...register('create_default_api_key')} className="w-4 h-4 text-blue-600 rounded" />
            <span className="text-sm font-semibold text-slate-700">Tạo sẵn Default API Key</span>
          </label>
        </div>

        <div className="flex justify-end space-x-3 pt-4 border-t border-slate-100 sticky bottom-0 bg-white">
          <Button type="button" variant="outline" onClick={handleClose}>
            Hủy bỏ
          </Button>
          <Button type="submit" disabled={createMutation.isPending} className="bg-blue-600 hover:bg-blue-700">
            {createMutation.isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Xác nhận Đăng ký
          </Button>
        </div>
      </form>
    </Dialog>
  );
}
