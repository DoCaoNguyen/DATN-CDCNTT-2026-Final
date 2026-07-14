import React, { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Store, CheckCircle, XCircle, Loader2, Plus, ArrowLeft, Webhook, Key, Ban, RefreshCcw, Building2, Globe, ShieldCheck, KeySquare, AlertCircle, Copy, Info } from 'lucide-react';
import toast from 'react-hot-toast';
import { ConfirmDialog } from '../../components/common/confirm-dialog';
import { merchantService } from '../../features/merchant-mangement/merchant.service';
import type { MerchantDetail } from '../../types';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { AdminTable, PageShell } from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { SearchFilterBar } from '../../components/organisms/filters/search-filter-bar';
import { ActionMenu, ActionMenuItem } from '../../components/ui/action-menu';
import type { ColumnDef } from '@tanstack/react-table';
import { getStatusVariant } from '../../utils/formatters';
import { 
  merchantNameSchema, 
  taxCodeSchema, 
  emailSchema, 
  vietnamMobilePhoneSchema,
  optionalVietnamPhoneSchema,
  fullNameSchema,
  usernameSchema,
  httpUrlSchema
} from '../../shared/validation/common-validation';

export default function MerchantManage() {
  const [merchants, setMerchants] = useState<MerchantDetail[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [isProcessing, setIsProcessing] = useState(false);
  const navigate = useNavigate();

  const { params, setQueryParams } = useApiQueryParams();

  // State Modals
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [confirmState, setConfirmState] = useState<{ open: boolean; type: string; id: string; message: string }>({ open: false, type: '', id: '', message: '' });
  
  const [suspendingMerchant, setSuspendingMerchant] = useState<MerchantDetail | null>(null);
  const [suspendReason, setSuspendReason] = useState('');
  
  // Bổ sung State cho Modal Từ chối
  const [rejectingMerchant, setRejectingMerchant] = useState<MerchantDetail | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  
  const [configMerchant, setConfigMerchant] = useState<any | null>(null);
  const [callbackUrl, setCallbackUrl] = useState('');
  const [redirectUrl, setRedirectUrl] = useState('');

  const [newMerchant, setNewMerchant] = useState<any>({
    merchant_name: '', 
    business_type: 'ONLINE', 
    representative_name: '',
    tax_code: '',
    address: '',
    email: '', 
    phone: '',
    callback: {
      default_callback_url: '',
      default_redirect_url: ''
    },
    create_owner: false,
    owner: {
      username: '',
      full_name: '',
      email: '',
      phone: ''
    }
  });

  const [successInfo, setSuccessInfo] = useState<{
    ownerUserId?: string;
    ownerEmail?: string;
    email_sent?: boolean;
    merchantName?: string;
  } | null>(null);

  const [isResending, setIsResending] = useState(false);

  useEffect(() => {
    fetchMerchants();
  }, [params.page, params.limit, params.search]);

  const fetchMerchants = async () => {
    setIsLoading(true);
    try {
      const res = await merchantService.getMerchants(params.search, params.page, params.limit);
      const payload = res?.data || res;
      
      const itemsList = (payload as any)?.data?.items || (payload as any)?.items || (payload as any)?.data;
      const totalItems = (payload as any)?.total || (payload as any)?.data?.total || 0;

      if (Array.isArray(itemsList)) {
        setTotal(totalItems || itemsList.length);
        setMerchants(itemsList);
      } else {
        setMerchants([]);
        setTotal(0);
      }
    } catch (error) {
      console.error('Lỗi tải danh sách Merchant:', error);
      setMerchants([]);
      setTotal(0);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsProcessing(true);
    setFieldErrors({});

    // Client-side Validation
    const errors: Record<string, string> = {};

    const mnRes = merchantNameSchema.safeParse(newMerchant.merchant_name);
    if (!mnRes.success) errors.merchant_name = mnRes.error.issues[0].message;

    if (newMerchant.email) {
      const emailRes = emailSchema.safeParse(newMerchant.email);
      if (!emailRes.success) errors.email = emailRes.error.issues[0].message;
    }

    if (newMerchant.phone) {
      const phoneRes = optionalVietnamPhoneSchema.safeParse(newMerchant.phone);
      if (!phoneRes.success) errors.phone = phoneRes.error.issues[0].message;
    }

    const taxRes = taxCodeSchema.safeParse(newMerchant.tax_code || '');
    if (!taxRes.success) errors.tax_code = taxRes.error.issues[0].message;

    if (!newMerchant.representative_name || !newMerchant.representative_name.trim()) {
      errors.representative_name = 'Người đại diện là bắt buộc.';
    }

    if (!newMerchant.address || !newMerchant.address.trim()) {
      errors.address = 'Địa chỉ doanh nghiệp là bắt buộc.';
    }

    if (newMerchant.callback?.default_callback_url) {
      const cbUrlRes = httpUrlSchema.safeParse(newMerchant.callback.default_callback_url);
      if (!cbUrlRes.success) errors['callback.default_callback_url'] = cbUrlRes.error.issues[0].message;
    }

    if (newMerchant.callback?.default_redirect_url) {
      const rUrlRes = httpUrlSchema.safeParse(newMerchant.callback.default_redirect_url);
      if (!rUrlRes.success) errors['callback.default_redirect_url'] = rUrlRes.error.issues[0].message;
    }

    if (newMerchant.create_owner) {
      const fnRes = fullNameSchema.safeParse(newMerchant.owner.full_name);
      if (!fnRes.success) errors['owner.full_name'] = fnRes.error.issues[0].message;

      const unRes = usernameSchema.safeParse(newMerchant.owner.username);
      if (!unRes.success) errors['owner.username'] = unRes.error.issues[0].message;

      const oEmailRes = emailSchema.safeParse(newMerchant.owner.email);
      if (!oEmailRes.success) errors['owner.email'] = oEmailRes.error.issues[0].message;

      if (newMerchant.owner.phone) {
        const oPhoneRes = optionalVietnamPhoneSchema.safeParse(newMerchant.owner.phone);
        if (!oPhoneRes.success) errors['owner.phone'] = oPhoneRes.error.issues[0].message;
      }
    }

    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      setIsProcessing(false);
      return;
    }

    try {
      const payloadToSend = {
        merchant_name: newMerchant.merchant_name,
        business_type: newMerchant.business_type,
        representative_name: newMerchant.representative_name,
        tax_code: newMerchant.tax_code,
        address: newMerchant.address,
        email: newMerchant.email,
        phone: newMerchant.phone,
        callback: (newMerchant.callback?.default_callback_url || newMerchant.callback?.default_redirect_url) ? newMerchant.callback : undefined,
        owner_info: newMerchant.create_owner ? newMerchant.owner : undefined
      };
      
      const res = await merchantService.createMerchant(payloadToSend);
      if (res.success || res?.data?.success) {
        setShowCreateModal(false);
        fetchMerchants();
        
        const data = res.data || res;
        if (newMerchant.create_owner && data.owner_user_id) {
          setSuccessInfo({
            ownerUserId: data.owner_user_id,
            ownerEmail: newMerchant.owner.email,
            email_sent: !!data.email_sent,
            merchantName: payloadToSend.merchant_name
          });
        } else {
          toast.success('Đăng ký Merchant thành công!');
        }
        
        setNewMerchant({
          merchant_name: '', business_type: 'ONLINE', representative_name: '', tax_code: '', address: '', email: '', phone: '',
          callback: { default_callback_url: '', default_redirect_url: '' },
          create_owner: false,
          owner: { username: '', full_name: '', email: '', phone: '' }
        });
      }
    } catch (error: any) {
      console.error(error);
      const errRes = error.response?.data;
      if (errRes && errRes.code === 'RESOURCE_CONFLICT' && errRes.errors) {
        const beErrors: Record<string, string> = {};
        errRes.errors.forEach((e: any) => {
          // Xử lý map "owner_info.username" -> "owner.username" cho UI
          const uiField = e.field.replace('owner_info.', 'owner.');
          beErrors[uiField] = e.message;
        });
        setFieldErrors(beErrors);
        toast.error('Dữ liệu không hợp lệ hoặc đã tồn tại.');
      } else {
        toast.error(errRes?.message || errRes?.error || 'Lỗi đăng ký Merchant. Kiểm tra lại API Backend.');
      }
    } finally {
      setIsProcessing(false);
    }
  };

  const handleConfirmAction = async () => {
    const { type, id } = confirmState;
    if (!type || !id) return;
    
    setIsProcessing(true);
    try {
      if (type === 'generate_key') {
        const res = await merchantService.generateApiKey(id, { key_name: 'Default Key', environment: 'SANDBOX' });
        if (res.success || res?.data?.success) {
          toast.success('Đã cấp API Key thành công! Vui lòng kiểm tra email merchant.');
          fetchMerchants();
        }
      } else if (type === 'approve') {
        const res = await merchantService.approve(id);
        if (res.success || res?.data?.success) {
          toast.success('Duyệt Merchant thành công!');
          setMerchants((merchants || []).map(m => m.id === id ? { ...m, status: 'ACTIVE' } : m));
        }
      } else if (type === 'activate') {
        const res = await merchantService.activate(id);
        if (res.success || res?.data?.success) {
          toast.success('Khôi phục hoạt động thành công!');
          setMerchants((merchants || []).map(m => m.id === id ? { ...m, status: 'ACTIVE' } : m));
        }
      }
    } catch (error: any) {
      toast.error(error?.response?.data?.message || 'Có lỗi xảy ra khi thực hiện thao tác.');
    } finally {
      setIsProcessing(false);
      setConfirmState({ open: false, type: '', id: '', message: '' });
    }
  };

  const submitConfigCallback = async () => {
    if (!configMerchant || !callbackUrl.trim() || !redirectUrl.trim()) return;
    setIsProcessing(true);
    try {
      const res = await merchantService.configCallback(configMerchant.id, { 
        default_callback_url: callbackUrl,
        default_redirect_url: redirectUrl
      });
      if (res.success || res?.data?.success) {
        setMerchants((merchants || []).map(m => m.id === configMerchant.id ? { ...m, default_callback_url: callbackUrl } : m));
        setConfigMerchant(null);
        toast.success('Lưu cấu hình Callback thành công!');
      }
    } catch (error) {
      toast.error('Lỗi khi lưu cấu hình Callback.');
    } finally {
      setIsProcessing(false);
    }
  };

  const submitReject = async () => {
    if (!rejectingMerchant || !rejectReason.trim()) return;
    setIsProcessing(true);
    try {
      const res = await merchantService.reject(rejectingMerchant.id, rejectReason);
      if (res.success || res?.data?.success) {
        setMerchants((merchants || []).map(m => m.id === rejectingMerchant.id ? { ...m, status: 'REJECTED' } : m));
        setRejectingMerchant(null);
        setRejectReason('');
        toast.success('Đã từ chối Merchant!');
      }
    } catch (error) {
      toast.error('Lỗi khi từ chối.');
    } finally {
      setIsProcessing(false);
    }
  };

  const submitSuspend = async () => {
    if (!suspendingMerchant || !suspendReason.trim()) return;
    setIsProcessing(true);
    try {
      const res = await merchantService.suspend(suspendingMerchant.id, suspendReason);
      if (res.success || res?.data?.success) {
        setMerchants((merchants || []).map(m => m.id === suspendingMerchant.id ? { ...m, status: 'SUSPENDED' } : m));
        setSuspendingMerchant(null);
        setSuspendReason('');
        toast.success('Đã tạm ngưng Merchant!');
      }
    } catch (error) {
      toast.error('Lỗi tạm ngưng.');
    } finally {
      setIsProcessing(false);
    }
  };

  const columns = useMemo<ColumnDef<MerchantDetail>[]>(
    () => [
      {
        id: 'merchant',
        header: 'Merchant',
        cell: ({ row }) => (
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600">
              <Store className="w-5 h-5" />
            </div>
            <div>
              <p className="font-bold text-slate-800">{row.original.merchant_name}</p>
              <p className="text-xs text-slate-500 font-mono mt-0.5">{row.original.merchant_code} • {row.original.business_type}</p>
            </div>
          </div>
        )
      },
      {
        id: 'integration',
        header: 'Tích hợp API',
        cell: ({ row }) => {
          const m = row.original as any;
          return (
            <div className="flex flex-col gap-1">
              {m.has_api_key ? (
                <span className="inline-flex items-center w-fit px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-50 text-emerald-700">
                  <CheckCircle className="w-3 h-3 mr-1" /> Đã cấp API Key
                </span>
              ) : (
                <span className="inline-flex items-center w-fit px-2 py-0.5 rounded text-[11px] font-medium bg-slate-100 text-slate-600">
                  Chưa có API Key
                </span>
              )}
              {m.webhook_configured ? (
                m.callback_enabled !== false ? (
                  <span className="inline-flex items-center w-fit px-2 py-0.5 rounded text-[11px] font-medium bg-blue-50 text-blue-700" title={m.default_callback_url}>
                    <Webhook className="w-3 h-3 mr-1" /> Đã cấu hình Webhook
                  </span>
                ) : (
                  <span className="inline-flex items-center w-fit px-2 py-0.5 rounded text-[11px] font-medium bg-orange-50 text-orange-700" title={m.default_callback_url}>
                    <Webhook className="w-3 h-3 mr-1" /> Webhook đang tắt
                  </span>
                )
              ) : (
                <span className="inline-flex items-center w-fit px-2 py-0.5 rounded text-[11px] font-medium bg-slate-100 text-slate-600">
                  Chưa cấu hình Webhook
                </span>
              )}
            </div>
          );
        }
      },
      {
        accessorKey: 'status',
        header: 'Trạng thái',
        cell: ({ getValue }) => {
          const v = getStatusVariant(getValue<string>(), 'merchant');
          return <span className={`px-3 py-1 rounded-full text-xs font-bold ${v.className}`}>{v.label}</span>;
        }
      },
      {
        id: 'actions',
        header: () => <div className="text-center">Thao tác</div>,
        cell: ({ row }) => {
          const m = row.original;
          return (
            <div className="flex justify-center">
              <ActionMenu>
                <ActionMenuItem 
                  icon={<Store />} 
                  label="Xem chi tiết" 
                  onClick={() => navigate(`/admin/merchants/${m.id}`)} 
                />
                
                {m.status === 'PENDING_REVIEW' && (
                  <>
                    <ActionMenuItem 
                      icon={<ShieldCheck />} 
                      label="Duyệt" 
                      onClick={() => setConfirmState({ open: true, type: 'approve', id: m.id, message: 'Xác nhận duyệt Merchant này?' })} 
                    />
                    <ActionMenuItem 
                      icon={<Ban />} 
                      label="Từ chối" 
                      onClick={() => setRejectingMerchant(m)} 
                      danger
                    />
                  </>
                )}

                {m.status === 'ACTIVE' && (
                  <ActionMenuItem 
                    icon={<Ban />} 
                    label="Tạm ngưng hoạt động" 
                    onClick={() => setSuspendingMerchant(m)} 
                    danger
                  />
                )}
                
                {m.status === 'SUSPENDED' && (
                  <ActionMenuItem 
                    icon={<RefreshCcw />} 
                    label="Khôi phục hoạt động" 
                    onClick={() => setConfirmState({ open: true, type: 'activate', id: m.id, message: 'Xác nhận khôi phục hoạt động cho Merchant này?' })} 
                  />
                )}
              </ActionMenu>
            </div>
          );
        }
      }
    ],
    [isProcessing]
  );

  const handleResendMerchantOnboarding = async () => {
    if (!successInfo || !successInfo.ownerUserId) return;
    setIsResending(true);
    try {
      await merchantService.resendOnboardingEmail(successInfo.ownerUserId);
      setSuccessInfo(prev => prev ? { ...prev, email_sent: true } : null);
      toast.success('Đã gửi lại email onboarding thành công!');
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Gửi lại email thất bại.');
    } finally {
      setIsResending(false);
    }
  };

  // Hiển thị thông tin cấp tài khoản thành công
  if (successInfo) {
    const isSent = successInfo.email_sent;
    return (
      <div className="flex-1 px-6 pt-10 pb-10 flex justify-center">
        <div className="w-full max-w-2xl bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
          <div className={`px-6 py-5 border-b border-gray-200 flex items-center gap-3 ${isSent ? 'bg-emerald-50/50' : 'bg-red-50/50'}`}>
            <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${isSent ? 'bg-emerald-100' : 'bg-red-100'}`}>
              <CheckCircle className="w-6 h-6 text-emerald-600" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-gray-950">Tạo Merchant thành công</h2>
              <p className={`text-sm mt-0.5 ${isSent ? 'text-emerald-600' : 'text-red-600'}`}>
                {isSent ? 'Tài khoản Owner đối tác đã hoạt động và sẵn sàng đăng nhập.' : 'Lưu ý: Chưa gửi được thông tin đăng nhập cho Owner đối tác.'}
              </p>
            </div>
          </div>
          
          <div className="p-6">
            {isSent ? (
              <div className="bg-emerald-50 border border-emerald-200 rounded-md p-4 mb-6 flex gap-3">
                <Info className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                <div className="text-sm text-emerald-800">
                  <p className="font-semibold mb-1">Email đã gửi thành công</p>
                  <p>Mật khẩu đăng nhập tạm thời đã được gửi trực tiếp tới email của chủ đối tác <strong>{successInfo.ownerEmail}</strong>. Owner được yêu cầu đổi mật khẩu ở lần đăng nhập đầu tiên.</p>
                </div>
              </div>
            ) : (
              <div className="bg-amber-50 border border-amber-200 rounded-md p-4 mb-6 flex gap-3">
                <AlertCircle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
                <div className="text-sm text-amber-800">
                  <p className="font-semibold mb-1">Cảnh báo: Gửi email thất bại (EMAIL_SEND_FAILED)</p>
                  <p className="mb-2">Hệ thống đã tạo xong tài khoản Merchant Owner nhưng không gửi được email chứa mật khẩu đăng nhập tạm thời tới địa chỉ <strong>{successInfo.ownerEmail}</strong> do lỗi kết nối SMTP.</p>
                  <p className="font-medium text-amber-700">Mật khẩu của chủ đối tác vẫn được bảo mật (không hiển thị rõ trên màn hình quản lý). Bạn hãy cấu hình lại SMTP Mail hoặc bấm nút "Gửi lại email" bên dưới để hệ thống cấp mật khẩu tạm mới và gửi lại.</p>
                </div>
              </div>
            )}

            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-md border border-gray-100">
                <div>
                  <span className="text-xs text-gray-500 block">Chủ đối tác (Owner)</span>
                  <span className="text-sm font-semibold text-gray-800">{successInfo.ownerEmail}</span>
                </div>
                <button
                  onClick={handleResendMerchantOnboarding}
                  disabled={isResending}
                  className={`px-4 py-2 border rounded-md text-sm font-medium transition-colors ${
                    isResending 
                      ? 'bg-gray-100 text-gray-400 border-gray-200 cursor-not-allowed'
                      : 'bg-white hover:bg-gray-50 text-blue-600 border-gray-300'
                  }`}
                >
                  {isResending ? 'Đang gửi...' : 'Gửi lại email'}
                </button>
              </div>
            </div>
          </div>
          
          <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end">
            <button
              onClick={() => { setSuccessInfo(null); }}
              className="px-5 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 transition-colors shadow-sm"
            >
              Hoàn tất
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (showCreateModal) {
    return (
      <div className="flex-1 px-6 pt-0 pb-10">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <Button variant="outline" size="icon" onClick={() => setShowCreateModal(false)}>
              <ArrowLeft className="w-4 h-4 text-gray-600" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Đăng ký Merchant mới</h1>
            </div>
          </div>
          <Button form="merchant-create-form" type="submit" disabled={isProcessing}>
            {isProcessing ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Plus className="w-4 h-4 mr-2" />}
            Tạo mới
          </Button>
        </div>

        <form id="merchant-create-form" onSubmit={handleCreateSubmit} noValidate>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 space-y-5">
              
              {/* Thông tin Doanh nghiệp/Đối tác */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2"><Building2 className="w-4 h-4 text-gray-500"/> Thông tin Doanh nghiệp/Đối tác</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Mã Merchant (Code)</label>
                    <div className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-md text-gray-500 text-sm italic">
                      Mã Merchant sẽ được tự động sinh.
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Tên Merchant <span className="text-red-500">*</span></label>
                    <input required type="text" value={newMerchant.merchant_name} onChange={(e) => { setNewMerchant({...newMerchant, merchant_name: e.target.value}); setFieldErrors(prev => ({ ...prev, merchant_name: '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors.merchant_name ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors.merchant_name && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors.merchant_name}</p>}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Mã số thuế <span className="text-red-500">*</span></label>
                    <input type="text" value={newMerchant.tax_code} onChange={(e) => { setNewMerchant({...newMerchant, tax_code: e.target.value}); setFieldErrors(prev => ({ ...prev, tax_code: '' })) }} placeholder="VD: 0312345678" className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors.tax_code ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors.tax_code && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors.tax_code}</p>}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Loại hình <span className="text-red-500">*</span></label>
                    <select value={newMerchant.business_type} onChange={(e) => setNewMerchant({...newMerchant, business_type: e.target.value})} className="w-full px-3 py-2.5 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                      <option value="ONLINE">Online (E-commerce)</option>
                      <option value="OFFLINE">Offline (Store/POS)</option>
                      <option value="BOTH">Cả hai</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Người đại diện <span className="text-red-500">*</span></label>
                    <input type="text" value={newMerchant.representative_name} onChange={(e) => { setNewMerchant({...newMerchant, representative_name: e.target.value}); setFieldErrors(prev => ({ ...prev, representative_name: '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors.representative_name ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors.representative_name && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors.representative_name}</p>}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Địa chỉ doanh nghiệp <span className="text-red-500">*</span></label>
                    <input type="text" value={newMerchant.address} onChange={(e) => { setNewMerchant({...newMerchant, address: e.target.value}); setFieldErrors(prev => ({ ...prev, address: '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors.address ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors.address && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors.address}</p>}
                  </div>
                </div>
              </div>

              {/* Thông tin Liên hệ */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2"><Store className="w-4 h-4 text-gray-500"/> Thông tin Liên hệ</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Email liên hệ</label>
                    <input type="email" value={newMerchant.email} onChange={(e) => { setNewMerchant({...newMerchant, email: e.target.value}); setFieldErrors(prev => ({ ...prev, email: '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors.email ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors.email && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors.email}</p>}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Số điện thoại <span className="text-red-500">*</span></label>
                    <input required type="text" value={newMerchant.phone} onChange={(e) => { setNewMerchant({...newMerchant, phone: e.target.value}); setFieldErrors(prev => ({ ...prev, phone: '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors.phone ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors.phone && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors.phone}</p>}
                  </div>
                </div>
              </div>

              {/* Cấu hình Tích hợp */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2"><Globe className="w-4 h-4 text-gray-500"/> Cấu hình Tích hợp (Tùy chọn)</h2>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Default Callback URL</label>
                    <input type="url" value={newMerchant.callback?.default_callback_url || ''} onChange={(e) => { setNewMerchant({...newMerchant, callback: { ...newMerchant.callback!, default_callback_url: e.target.value }}); setFieldErrors(prev => ({ ...prev, 'callback.default_callback_url': '' })) }} placeholder="https://..." className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors['callback.default_callback_url'] ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors['callback.default_callback_url'] && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors['callback.default_callback_url']}</p>}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Default Redirect URL</label>
                    <input type="url" value={newMerchant.callback?.default_redirect_url || ''} onChange={(e) => { setNewMerchant({...newMerchant, callback: { ...newMerchant.callback!, default_redirect_url: e.target.value }}); setFieldErrors(prev => ({ ...prev, 'callback.default_redirect_url': '' })) }} placeholder="https://..." className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${fieldErrors['callback.default_redirect_url'] ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                    {fieldErrors['callback.default_redirect_url'] && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors['callback.default_redirect_url']}</p>}
                  </div>
                </div>
              </div>

              {/* Tài khoản Owner */}
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2"><ShieldCheck className="w-4 h-4 text-gray-500"/> Tài khoản Owner</h2>
                  <label className="flex items-center space-x-2 cursor-pointer">
                    <input type="checkbox" checked={newMerchant.create_owner} onChange={e => setNewMerchant({ ...newMerchant, create_owner: e.target.checked })} className="w-4 h-4 text-blue-600 rounded border-gray-300 focus:ring-blue-500" />
                    <span className="text-sm font-medium text-gray-700">Tạo tài khoản</span>
                  </label>
                </div>

                {newMerchant.create_owner && (
                  <div className="p-5 bg-gray-50 border border-gray-200 rounded-lg space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1.5">Username Owner <span className="text-red-500">*</span></label>
                        <input required={newMerchant.create_owner} type="text" value={newMerchant.owner.username} onChange={e => { setNewMerchant({ ...newMerchant, owner: { ...newMerchant.owner, username: e.target.value } }); setFieldErrors(prev => ({ ...prev, 'owner.username': '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white ${fieldErrors['owner.username'] ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                        {fieldErrors['owner.username'] && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors['owner.username']}</p>}
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1.5">Họ tên <span className="text-red-500">*</span></label>
                        <input required={newMerchant.create_owner} type="text" value={newMerchant.owner.full_name} onChange={e => { setNewMerchant({ ...newMerchant, owner: { ...newMerchant.owner, full_name: e.target.value } }); setFieldErrors(prev => ({ ...prev, 'owner.full_name': '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white ${fieldErrors['owner.full_name'] ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                        {fieldErrors['owner.full_name'] && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors['owner.full_name']}</p>}
                      </div>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1.5">Số điện thoại <span className="text-red-500">*</span></label>
                        <input required={newMerchant.create_owner} type="text" value={newMerchant.owner.phone} onChange={e => { setNewMerchant({ ...newMerchant, owner: { ...newMerchant.owner, phone: e.target.value } }); setFieldErrors(prev => ({ ...prev, 'owner.phone': '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white ${fieldErrors['owner.phone'] ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                        {fieldErrors['owner.phone'] && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors['owner.phone']}</p>}
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1.5">Email <span className="text-red-500">*</span></label>
                        <input required={newMerchant.create_owner} type="email" value={newMerchant.owner.email} onChange={e => { setNewMerchant({ ...newMerchant, owner: { ...newMerchant.owner, email: e.target.value } }); setFieldErrors(prev => ({ ...prev, 'owner.email': '' })) }} className={`w-full px-3 py-2.5 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white ${fieldErrors['owner.email'] ? 'border-red-500 focus:border-red-500' : 'border-gray-300 focus:border-blue-500'}`} />
                        {fieldErrors['owner.email'] && <p className="mt-1 text-sm text-red-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" />{fieldErrors['owner.email']}</p>}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Sidebar */}
            <div className="space-y-4">
              <div className="bg-white border border-gray-200 rounded-lg p-5">
                <h3 className="text-sm font-semibold text-gray-900 mb-4">Tóm tắt</h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-500">Loại hình:</span>
                    <span className="font-medium text-gray-900">{newMerchant.business_type}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-500">Tài khoản Owner:</span>
                    <span className={`font-medium ${newMerchant.create_owner ? 'text-blue-600' : 'text-gray-400'}`}>
                      {newMerchant.create_owner ? 'Có tạo' : 'Không'}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    );
  }

  return (
    <PageShell
      title="Quản lý Merchant"
      description="Đăng ký, cấp API Key, cấu hình Webhook và giám sát Đối tác."
      actions={
        <Button onClick={() => setShowCreateModal(true)}>
          <Plus className="w-4 h-4 mr-2" /> Đăng ký
        </Button>
      }
    >
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 flex justify-end">
        <SearchFilterBar 
          searchPlaceholder="Tên, mã Merchant..."
          searchValue={params.search}
          onSearchChange={(val) => setQueryParams({ search: val, page: 1 })}
        />
      </div>

      <AdminTable 
        columns={columns}
        data={merchants}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={Math.ceil(total / params.limit) || 1}
        onPageChange={(page) => setQueryParams({ page })}
        onLimitChange={(limit) => setQueryParams({ limit, page: 1 })}
      />

      {/* --- CÁC MODALS --- */}




      {/* Modal Cấu hình Callback */}
      {configMerchant && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-2xl">
            <h3 className="text-lg font-bold">Cấu hình Webhook</h3>
            <p className="text-sm mt-1 text-slate-500">Merchant: <span className="font-bold text-slate-800">{configMerchant.merchant_name}</span></p>
            <label className="block text-sm font-semibold text-slate-700 mt-4 mb-2">Default Callback URL <span className="text-red-500">*</span></label>
            <input type="url" required placeholder="https://api.merchant.com/webhook" value={callbackUrl} onChange={e => setCallbackUrl(e.target.value)} className="w-full p-3 border rounded-xl outline-none focus:ring-2 focus:ring-indigo-500/20" />
            
            <label className="block text-sm font-semibold text-slate-700 mt-4 mb-2">Default Redirect URL <span className="text-red-500">*</span></label>
            <input type="url" required placeholder="https://merchant.com/payment-result" value={redirectUrl} onChange={e => setRedirectUrl(e.target.value)} className="w-full p-3 border rounded-xl outline-none focus:ring-2 focus:ring-indigo-500/20" />
            
            <div className="mt-6 flex justify-end space-x-3">
              <Button variant="ghost" onClick={() => setConfigMerchant(null)}>Hủy</Button>
              <Button variant="primary" onClick={submitConfigCallback} disabled={!callbackUrl.trim() || !redirectUrl.trim() || isProcessing}>
                {isProcessing && <Loader2 className="w-4 h-4 mr-2 animate-spin" />} Lưu cấu hình
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* --- BỔ SUNG: Modal Từ chối Merchant --- */}
      {rejectingMerchant && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-2xl">
            <h3 className="text-lg font-bold">Từ chối Merchant</h3>
            <label className="block text-sm font-semibold mt-4 mb-2">Lý do từ chối <span className="text-red-500">*</span></label>
            <textarea className="w-full p-3 border rounded-xl outline-none focus:ring-2 focus:ring-red-500/20" rows={3} value={rejectReason} onChange={e => setRejectReason(e.target.value)} placeholder="Vui lòng nhập lý do từ chối..." />
            <div className="mt-6 flex justify-end space-x-3">
              <Button variant="ghost" onClick={() => setRejectingMerchant(null)}>Hủy</Button>
              <Button variant="danger" onClick={submitReject} disabled={!rejectReason.trim() || isProcessing}>
                {isProcessing && <Loader2 className="w-4 h-4 mr-2 animate-spin" />} Xác nhận từ chối
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Tạm ngưng */}
      {suspendingMerchant && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-2xl">
            <h3 className="text-lg font-bold">Tạm ngưng Merchant</h3>
            <label className="block text-sm font-semibold mt-4 mb-2">Lý do ngưng hoạt động <span className="text-red-500">*</span></label>
            <textarea className="w-full p-3 border rounded-xl outline-none focus:ring-2 focus:ring-orange-500/20" rows={3} value={suspendReason} onChange={e => setSuspendReason(e.target.value)} />
            <div className="mt-6 flex justify-end space-x-3">
              <Button variant="ghost" onClick={() => setSuspendingMerchant(null)}>Hủy</Button>
              <Button variant="danger" onClick={submitSuspend} disabled={!suspendReason.trim() || isProcessing}>
                {isProcessing && <Loader2 className="w-4 h-4 mr-2 animate-spin" />} Xác nhận ngưng
              </Button>
            </div>
          </div>
        </div>
      )}
      <ConfirmDialog 
        open={confirmState.open} 
        title="Xác nhận thao tác"
        description={confirmState.message}
        onClose={() => setConfirmState({ ...confirmState, open: false })}
        onConfirm={handleConfirmAction}
        isLoading={isProcessing}
        variant={confirmState.type === 'generate_key' ? 'primary' : 'danger'}
      />
    </PageShell>
  );
}