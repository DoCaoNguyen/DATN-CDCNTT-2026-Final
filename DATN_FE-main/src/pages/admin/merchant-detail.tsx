import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Loader2, Store, MoreVertical, Ban, ShieldCheck, Webhook, KeySquare, RefreshCw, Trash2, Key, Copy } from 'lucide-react';
import toast from 'react-hot-toast';
import { merchantService } from '../../features/merchant-mangement/merchant.service';
import { formatDateTime, getStatusVariant, formatDisplayPhone } from '../../utils/formatters';
import { ConfirmDialog } from '../../components/common/confirm-dialog';
import { MerchantWebhookDialog } from '../../features/merchants/components/merchant-webhook-dialog';

type Tab = 'info' | 'webhook' | 'api_keys';

function InfoRow({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="grid grid-cols-5 py-2.5 border-b border-gray-100 last:border-0">
      <span className="col-span-2 text-sm text-gray-500">{label}</span>
      <span className="col-span-3 text-sm text-gray-900 font-medium">{value ?? '—'}</span>
    </div>
  );
}

export default function MerchantDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [data, setData] = useState<any | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [tab, setTab] = useState<Tab>('info');
  const [menuOpen, setMenuOpen] = useState(false);
  const [isEditingWebhook, setIsEditingWebhook] = useState(false);
  const [webhookForm, setWebhookForm] = useState({ 
    default_callback_url: '', 
    default_redirect_url: '',
    callback_enabled: false,
    retry_enabled: true
  });

  const [confirmAction, setConfirmAction] = useState<null | 'suspend' | 'approve' | 'reject'>(null);
  const [reason, setReason] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  const [apiKeys, setApiKeys] = useState<any[]>([]);
  const [isLoadingKeys, setIsLoadingKeys] = useState(false);

  const [confirmKeyAction, setConfirmKeyAction] = useState<{ open: boolean; type: 'rotate' | 'revoke'; id: string; message: string }>({ open: false, type: 'rotate', id: '', message: '' });
  const [newSecretModal, setNewSecretModal] = useState<{ open: boolean; rawSecret: string; apiKey?: string }>({ open: false, rawSecret: '' });

  const [createKeyModal, setCreateKeyModal] = useState<{ open: boolean; environment: 'SANDBOX' | 'LIVE' }>({ open: false, environment: 'SANDBOX' });
  const [createKeyName, setCreateKeyName] = useState('');
  const [createKeyError, setCreateKeyError] = useState('');

  useEffect(() => {
    if (!id) return;
    fetchDetail();
  }, [id, navigate]);

  useEffect(() => {
    if (tab === 'api_keys' && id && apiKeys.length === 0) {
      fetchApiKeys();
    }
  }, [tab, id]);

  const fetchApiKeys = async () => {
    setIsLoadingKeys(true);
    try {
      const res = await merchantService.getApiKeys(id!);
      setApiKeys(res.data || []);
    } catch (err) {
      toast.error('Lỗi khi tải danh sách API Key');
    } finally {
      setIsLoadingKeys(false);
    }
  };

  const handleKeyAction = async () => {
    if (!id || !confirmKeyAction.open) return;
    setIsProcessing(true);
    try {
      if (confirmKeyAction.type === 'rotate') {
        const res = await merchantService.rotateApiKey(id, confirmKeyAction.id);
        if (res.data?.raw_secret) {
          setNewSecretModal({ open: true, rawSecret: res.data.raw_secret, apiKey: res.data.api_key });
        } else {
          toast.success('Rotate API Key thành công!');
        }
      } else if (confirmKeyAction.type === 'revoke') {
        await merchantService.revokeApiKey(id, confirmKeyAction.id);
        toast.success('Thu hồi API Key thành công!');
      }
      setConfirmKeyAction({ open: false, type: 'rotate', id: '', message: '' });
      fetchApiKeys();
      fetchDetail(); // to sync has_api_key status
    } catch (err: any) {
      const errorMsg = err.response?.data?.error || err.response?.data?.message || err.message;
      if (confirmKeyAction.type === 'rotate') toast.error(errorMsg || 'Rotate API Key thất bại');
      else toast.error(errorMsg || 'Thu hồi API Key thất bại');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleCreateKey = async () => {
    if (!id) return;
    const trimmedName = createKeyName.trim();
    if (!trimmedName || trimmedName.length < 3 || trimmedName.length > 100) {
      setCreateKeyError('Tên API Key bắt buộc, từ 3 đến 100 ký tự');
      return;
    }
    
    setIsProcessing(true);
    setCreateKeyError('');
    try {
      const res = await merchantService.generateApiKey(id, { key_name: trimmedName, environment: createKeyModal.environment });
      if (res.data?.raw_secret) {
        setNewSecretModal({ open: true, rawSecret: res.data.raw_secret, apiKey: res.data.api_key });
      } else {
        toast.success('Cấp API Key thành công!');
      }
      setCreateKeyModal({ open: false, environment: 'SANDBOX' });
      fetchApiKeys();
      fetchDetail();
    } catch (err: any) {
      toast.error(err.response?.data?.error || err.response?.data?.message || err.message || 'Cấp API Key thất bại');
    } finally {
      setIsProcessing(false);
    }
  };

  const fetchDetail = async () => {
    setIsLoading(true);
    try {
      const res = await merchantService.getMerchantById(id!);
      if (res?.data) {
        setData(res.data);
      }
    } catch (err) {
      toast.error('Lỗi khi tải chi tiết Merchant');
      navigate('/admin/merchants');
    } finally {
      setIsLoading(false);
    }
  };

  const handleAction = async () => {
    if (!id || !confirmAction) return;
    if ((confirmAction === 'suspend' || confirmAction === 'reject') && !reason.trim()) {
      toast.error('Vui lòng nhập lý do');
      return;
    }

    setIsProcessing(true);
    try {
      if (confirmAction === 'suspend') {
        await merchantService.suspend(id, reason);
        toast.success('Đã tạm ngưng Merchant!');
      } else if (confirmAction === 'reject') {
        await merchantService.reject(id, reason);
        toast.success('Đã từ chối Merchant!');
      } else if (confirmAction === 'approve') {
        await merchantService.approve(id);
        toast.success('Duyệt Merchant thành công!');
      }
      setConfirmAction(null);
      setReason('');
      setMenuOpen(false);
      fetchDetail();
    } catch (err: any) {
      toast.error('Thao tác thất bại. Vui lòng thử lại.');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleEditWebhookClick = () => {
    const callbackConfig = data?.callback_config || {};
    setWebhookForm({
      default_callback_url: callbackConfig.default_callback_url || '',
      default_redirect_url: callbackConfig.default_redirect_url || '',
      callback_enabled: callbackConfig.callback_enabled ?? false,
      retry_enabled: callbackConfig.retry_enabled ?? true
    });
    setIsEditingWebhook(true);
  };

  const handleSaveWebhook = async () => {
    if (!id) return;
    setIsProcessing(true);
    try {
      await merchantService.configCallback(id, webhookForm);
      toast.success('Lưu cấu hình Webhook thành công!');
      setIsEditingWebhook(false);
      fetchDetail();
    } catch (err: any) {
      toast.error(err.response?.data?.error || 'Lỗi khi lưu cấu hình Webhook');
    } finally {
      setIsProcessing(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (!data || !data.merchant) {
    return (
      <div className="px-6 py-10 text-center text-gray-500">
        <p>Không tìm thấy Merchant.</p>
        <button onClick={() => navigate('/admin/merchants')} className="mt-4 text-blue-600 text-sm underline">
          Quay lại danh sách
        </button>
      </div>
    );
  }

  const merchant = data.merchant;
  const callbackConfig = data.callback_config;
  const isSuspended = merchant.status === 'SUSPENDED';
  const isPending = merchant.status === 'PENDING_REVIEW';
  const isActive = merchant.status === 'ACTIVE';

  const initials = (name?: string) => {
    if (!name) return 'M';
    return name.split(' ').map(w => w[0]).slice(-2).join('').toUpperCase();
  };

  const statusVariant = getStatusVariant(merchant.status, 'merchant');

  return (
    <div className="flex-1 px-6 pt-0 pb-10 space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/admin/merchants')}
            className="flex items-center justify-center w-8 h-8 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-gray-600" />
          </button>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-semibold text-sm">
              {initials(merchant.merchant_name)}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold text-gray-900">{merchant.merchant_name}</h1>
                <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${statusVariant.className}`}>{statusVariant.label}</span>
              </div>
              <p className="text-xs font-mono text-gray-400">{merchant.merchant_code} • {merchant.business_type}</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="relative">
          <button
            onClick={() => setMenuOpen((p) => !p)}
            className="flex items-center gap-1 px-3 py-2 border border-gray-200 rounded-md text-sm hover:bg-gray-50 transition-colors"
          >
            <MoreVertical className="w-4 h-4" />
          </button>
          {menuOpen && (
            <div className="absolute right-0 mt-1 w-44 bg-white border border-gray-200 rounded-md shadow-lg z-20 py-1">
              {isPending && (
                <>
                  <button
                    onClick={() => { setConfirmAction('approve'); setMenuOpen(false); }}
                    className="w-full flex items-center gap-2 px-4 py-2 text-sm text-emerald-700 hover:bg-emerald-50"
                  >
                    <ShieldCheck className="w-3.5 h-3.5" /> Duyệt Merchant
                  </button>
                  <button
                    onClick={() => { setConfirmAction('reject'); setMenuOpen(false); }}
                    className="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-700 hover:bg-red-50"
                  >
                    <Ban className="w-3.5 h-3.5" /> Từ chối
                  </button>
                </>
              )}
              {isActive && (
                <button
                  onClick={() => { setConfirmAction('suspend'); setMenuOpen(false); }}
                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-orange-700 hover:bg-orange-50"
                >
                  <Ban className="w-3.5 h-3.5" /> Tạm ngưng
                </button>
              )}
              {isSuspended && (
                <button
                  disabled
                  title="Tính năng khôi phục nằm ở ngoài danh sách"
                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-400 cursor-not-allowed"
                >
                  <ShieldCheck className="w-3.5 h-3.5" /> Khôi phục (ở danh sách)
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <div className="flex gap-0">
          <button
            onClick={() => setTab('info')}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              tab === 'info' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            Thông tin chung
          </button>
          <button
            onClick={() => setTab('webhook')}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              tab === 'webhook' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            Cấu hình Webhook
          </button>
          <button
            onClick={() => setTab('api_keys')}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              tab === 'api_keys' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            Quản lý API Key
          </button>
        </div>
      </div>

      {/* Tab Content */}
      {tab === 'info' && (
        <div className="bg-white border border-gray-200 rounded-lg p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
            <Store className="w-4 h-4" /> Chi tiết Merchant
          </h3>
          <InfoRow label="Mã Merchant" value={<span className="font-mono">{merchant.merchant_code}</span>} />
          <InfoRow label="Tên doanh nghiệp" value={merchant.merchant_name} />
          <InfoRow label="Người đại diện" value={merchant.representative_name} />
          <InfoRow label="Loại hình" value={merchant.business_type} />
          <InfoRow label="Mã số thuế" value={merchant.tax_code} />
          <InfoRow label="Email liên hệ" value={merchant.email} />
          <InfoRow label="Số điện thoại" value={formatDisplayPhone(merchant.phone)} />
          <InfoRow label="Địa chỉ" value={merchant.address} />
          <InfoRow label="Ghi chú rủi ro" value={merchant.risk_note} />
          <InfoRow label="Ngày tạo" value={formatDateTime(merchant.created_at)} />
        </div>
      )}

      {tab === 'webhook' && (
        <div className="bg-white border border-gray-200 rounded-lg p-5 max-w-3xl relative">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-gray-900 flex items-center gap-2">
              <Webhook className="w-4 h-4" /> Cấu hình API / Webhook
            </h3>
            {!isEditingWebhook ? (
              <button
                onClick={handleEditWebhookClick}
                className="px-3 py-1.5 text-sm font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-md transition-colors"
              >
                Chỉnh sửa
              </button>
            ) : (
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setIsEditingWebhook(false)}
                  disabled={isProcessing}
                  className="px-3 py-1.5 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-md transition-colors disabled:opacity-50"
                >
                  Hủy
                </button>
                <button
                  onClick={handleSaveWebhook}
                  disabled={isProcessing}
                  className="px-3 py-1.5 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md transition-colors flex items-center disabled:opacity-50"
                >
                  {isProcessing && <Loader2 className="w-3.5 h-3.5 mr-1 animate-spin" />}
                  Lưu
                </button>
              </div>
            )}
          </div>
          
          {!isEditingWebhook ? (
            callbackConfig ? (
              <>
                <InfoRow label="Trạng thái" value={
                  <span className={callbackConfig.callback_enabled ? "text-emerald-600 font-semibold" : "text-gray-500 font-semibold"}>
                    {callbackConfig.callback_enabled ? "Đang bật" : "Đang tắt"}
                  </span>
                } />
                <InfoRow label="Callback URL" value={
                  <span className="font-mono text-xs bg-slate-50 px-2 py-1 rounded border border-slate-100 break-all">{callbackConfig.default_callback_url || 'Chưa cấu hình'}</span>
                } />
                <InfoRow label="Redirect URL" value={
                  <span className="font-mono text-xs bg-slate-50 px-2 py-1 rounded border border-slate-100 break-all">{callbackConfig.default_redirect_url || 'Chưa cấu hình'}</span>
                } />
                <InfoRow label="Cho phép Retry" value={callbackConfig.retry_enabled ? "Có" : "Không"} />
                <InfoRow label="Cập nhật lần cuối" value={formatDateTime(callbackConfig.updated_at)} />
              </>
            ) : (
              <div className="text-center py-6 text-gray-500 text-sm">
                Merchant này chưa được cấu hình Webhook. Hãy nhấn "Chỉnh sửa" để cấu hình.
              </div>
            )
          ) : (
            <div className="space-y-4 pt-2">
              <div className="flex items-center gap-6 mb-4">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input 
                    type="checkbox" 
                    checked={webhookForm.callback_enabled}
                    onChange={(e) => setWebhookForm({ ...webhookForm, callback_enabled: e.target.checked })}
                    className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                  />
                  <span className="text-sm font-semibold text-slate-700">Bật Webhook</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input 
                    type="checkbox" 
                    checked={webhookForm.retry_enabled}
                    onChange={(e) => setWebhookForm({ ...webhookForm, retry_enabled: e.target.checked })}
                    className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                  />
                  <span className="text-sm font-semibold text-slate-700">Cho phép Retry</span>
                </label>
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">Callback URL</label>
                <input 
                  type="url" 
                  value={webhookForm.default_callback_url} 
                  onChange={(e) => setWebhookForm({ ...webhookForm, default_callback_url: e.target.value })}
                  placeholder="https://..."
                  className="w-full px-3 py-2 border border-slate-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">Redirect URL</label>
                <input 
                  type="url" 
                  value={webhookForm.default_redirect_url} 
                  onChange={(e) => setWebhookForm({ ...webhookForm, default_redirect_url: e.target.value })}
                  placeholder="https://..."
                  className="w-full px-3 py-2 border border-slate-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          )}
        </div>
      )}

      {tab === 'api_keys' && (() => {
        const hasActiveSandbox = apiKeys.some(k => k.environment === 'SANDBOX' && k.status === 'ACTIVE');
        const hasActiveLive = apiKeys.some(k => k.environment === 'LIVE' && k.status === 'ACTIVE');
        
        return (
        <div className="bg-white border border-gray-200 rounded-lg p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-semibold text-gray-900 flex items-center gap-2">
              <KeySquare className="w-4 h-4" /> Quản lý API Key
            </h3>
            <div className="flex items-center gap-2">
              {!hasActiveSandbox && (
                <button
                  onClick={() => {
                    setCreateKeyName(`${merchant.merchant_code}-SANDBOX`);
                    setCreateKeyError('');
                    setCreateKeyModal({ open: true, environment: 'SANDBOX' });
                  }}
                  className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 transition-colors"
                >
                  Cấp SANDBOX Key
                </button>
              )}
              {!hasActiveLive && (
                <button
                  onClick={() => {
                    setCreateKeyName(`${merchant.merchant_code}-LIVE`);
                    setCreateKeyError('');
                    setCreateKeyModal({ open: true, environment: 'LIVE' });
                  }}
                  className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-md hover:bg-emerald-100 transition-colors"
                >
                  Cấp PRODUCTION Key
                </button>
              )}
            </div>
          </div>

          {isLoadingKeys ? (
            <div className="py-10 flex justify-center"><Loader2 className="w-6 h-6 animate-spin text-blue-600" /></div>
          ) : apiKeys.length === 0 ? (
            <div className="text-center py-6 text-gray-500 text-sm">
              Merchant chưa có API Key nào được cấp.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead>
                  <tr className="border-b border-gray-200 text-gray-500">
                    <th className="py-3 px-4 font-medium">Tên Key</th>
                    <th className="py-3 px-4 font-medium">Môi trường</th>
                    <th className="py-3 px-4 font-medium">Prefix</th>
                    <th className="py-3 px-4 font-medium">Ngày tạo</th>
                    <th className="py-3 px-4 font-medium">Ngày thu hồi</th>
                    <th className="py-3 px-4 font-medium">Trạng thái</th>
                    <th className="py-3 px-4 font-medium text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody>
                  {apiKeys.map((key) => {
                    const isKeyActive = key.status === 'ACTIVE';
                    return (
                      <tr key={key.id} className="border-b border-gray-100 last:border-0 hover:bg-gray-50">
                        <td className="py-3 px-4 text-gray-900 font-medium">
                          <div className="flex items-center gap-2">
                            <Key className="w-4 h-4 text-gray-400" />
                            {key.key_name || '—'}
                          </div>
                        </td>
                        <td className="py-3 px-4 text-gray-600">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${key.environment === 'LIVE' ? 'bg-purple-100 text-purple-700' : 'bg-gray-100 text-gray-700'}`}>
                            {key.environment === 'LIVE' ? 'PRODUCTION' : key.environment}
                          </span>
                        </td>
                        <td className="py-3 px-4">
                          <span className="font-mono text-xs bg-slate-100 text-slate-700 px-2 py-1 rounded">
                            {key.api_key_prefix || 'pk_***'}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-gray-500 text-xs">
                          {formatDateTime(key.created_at)}
                        </td>
                        <td className="py-3 px-4 text-gray-500 text-xs">
                          {key.revoked_at ? formatDateTime(key.revoked_at) : '—'}
                        </td>
                        <td className="py-3 px-4">
                          <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                            isKeyActive ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'
                          }`}>
                            {isKeyActive ? 'Hoạt động' : 'Đã thu hồi'}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-right space-x-2">
                          {isKeyActive && (
                            <>
                              <button 
                                onClick={() => setConfirmKeyAction({ open: true, type: 'rotate', id: key.id, message: 'Bạn có chắc chắn muốn rotate API Key này? Key cũ sẽ bị vô hiệu hóa ngay lập tức.' })}
                                className="inline-flex items-center gap-1 px-2.5 py-1.5 text-[11px] font-medium text-orange-700 bg-orange-50 hover:bg-orange-100 rounded transition-colors"
                              >
                                <RefreshCw className="w-3 h-3" /> Rotate
                              </button>
                              <button 
                                onClick={() => setConfirmKeyAction({ open: true, type: 'revoke', id: key.id, message: 'Thu hồi API Key này? Các ứng dụng đang dùng key này sẽ không thể gọi API được nữa.' })}
                                className="inline-flex items-center gap-1 px-2.5 py-1.5 text-[11px] font-medium text-red-700 bg-red-50 hover:bg-red-100 rounded transition-colors"
                              >
                                <Trash2 className="w-3 h-3" /> Thu hồi
                              </button>
                            </>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
        );
      })()}

      {/* Confirm dialog */}
      {confirmAction && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-xl">
            <div className="px-6 py-4 border-b border-gray-100">
              <h3 className="text-base font-semibold text-gray-900">
                {confirmAction === 'approve' ? 'Duyệt Merchant' : confirmAction === 'reject' ? 'Từ chối Merchant' : 'Tạm ngưng Merchant'}
              </h3>
              <p className="text-sm text-gray-500 mt-0.5">Tên: <strong>{merchant.merchant_name}</strong></p>
            </div>
            
            {(confirmAction === 'suspend' || confirmAction === 'reject') && (
              <div className="px-6 py-4">
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Lý do <span className="text-red-500">*</span>
                </label>
                <textarea
                  rows={3}
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="Nhập lý do..."
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                />
              </div>
            )}
            {confirmAction === 'approve' && (
              <div className="px-6 py-4">
                <p className="text-sm text-gray-700">Bạn có chắc chắn muốn duyệt Merchant này không?</p>
              </div>
            )}
            
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <button
                onClick={() => { setConfirmAction(null); setReason(''); }}
                className="px-4 py-2 text-sm text-gray-700 border border-gray-200 rounded-md hover:bg-gray-100"
              >
                Hủy
              </button>
              <button
                onClick={handleAction}
                disabled={isProcessing || ((confirmAction === 'suspend' || confirmAction === 'reject') && !reason.trim())}
                className={`px-4 py-2 text-sm text-white rounded-md font-medium disabled:opacity-50 flex items-center gap-1.5 ${
                  confirmAction === 'approve' ? 'bg-emerald-600 hover:bg-emerald-700' : 
                  confirmAction === 'reject' ? 'bg-red-600 hover:bg-red-700' :
                  'bg-orange-500 hover:bg-orange-600'
                }`}
              >
                {isProcessing && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Xác nhận
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Dialog for Create API Key */}
      {createKeyModal.open && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-xl">
            <div className="px-6 py-4 border-b border-gray-100">
              <h3 className="text-base font-semibold text-gray-900">
                Cấp mới API Key
              </h3>
            </div>
            
            <div className="px-6 py-4 space-y-4">
              <div className="bg-blue-50 border border-blue-100 p-3 rounded-md">
                <p className="text-sm text-blue-800">
                  Xác nhận tạo mới API Key cho môi trường <strong>{createKeyModal.environment === 'LIVE' ? 'PRODUCTION' : 'SANDBOX'}</strong>? Mỗi Merchant chỉ có 1 key ACTIVE cho môi trường này.
                </p>
                <p className="text-xs text-blue-600 font-semibold mt-1">
                  Lưu ý: API Secret chỉ hiển thị một lần sau khi tạo.
                </p>
              </div>

              <InfoRow label="Merchant" value={merchant.merchant_name} />
              <InfoRow label="Môi trường" value={createKeyModal.environment === 'LIVE' ? 'PRODUCTION' : 'SANDBOX'} />

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Tên API Key <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={createKeyName}
                  onChange={(e) => setCreateKeyName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                  placeholder="VD: Tiki-SANDBOX"
                  disabled={isProcessing}
                />
                {createKeyError && <p className="text-red-500 text-xs mt-1">{createKeyError}</p>}
              </div>
            </div>
            
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <button
                onClick={() => setCreateKeyModal({ open: false, environment: 'SANDBOX' })}
                disabled={isProcessing}
                className="px-4 py-2 text-sm text-gray-700 border border-gray-200 rounded-md hover:bg-gray-100 disabled:opacity-50"
              >
                Hủy
              </button>
              <button
                onClick={handleCreateKey}
                disabled={isProcessing}
                className="px-4 py-2 text-sm text-white bg-blue-600 rounded-md font-medium hover:bg-blue-700 disabled:opacity-50 flex items-center gap-1.5"
              >
                {isProcessing && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Xác nhận
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Dialog for API Key Actions (Rotate/Revoke) */}
      <ConfirmDialog
        open={confirmKeyAction.open}
        title={confirmKeyAction.type === 'rotate' ? 'Rotate API Key' : 'Thu hồi API Key'}
        description={confirmKeyAction.message}
        onConfirm={handleKeyAction}
        onClose={() => setConfirmKeyAction({ ...confirmKeyAction, open: false })}
        isProcessing={isProcessing}
      />



      {/* Modal Show New Secret */}
      {newSecretModal.open && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-xl">
            <div className="px-6 py-4 border-b border-gray-100">
              <h3 className="text-base font-semibold text-gray-900">
                Lưu lại API Secret Key
              </h3>
              <p className="text-sm text-red-600 mt-1">
                Lưu ý: API Secret chỉ hiển thị 1 lần duy nhất. Hãy copy và lưu trữ an toàn.
              </p>
            </div>
            
            <div className="px-6 py-4 space-y-4">
              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider">API Key (Public)</label>
                  <button onClick={() => { navigator.clipboard.writeText(newSecretModal.apiKey || ''); toast.success('Đã copy API Key'); }} className="text-blue-600 hover:text-blue-800 flex items-center gap-1 text-[11px] font-medium">
                    <Copy className="w-3 h-3" /> Copy
                  </button>
                </div>
                <div className="bg-slate-50 border border-slate-200 rounded p-3 font-mono text-sm break-all text-slate-800 select-all">
                  {newSecretModal.apiKey}
                </div>
              </div>
              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider">API Secret Key</label>
                  <button onClick={() => { navigator.clipboard.writeText(newSecretModal.rawSecret); toast.success('Đã copy Secret Key'); }} className="text-blue-600 hover:text-blue-800 flex items-center gap-1 text-[11px] font-medium">
                    <Copy className="w-3 h-3" /> Copy
                  </button>
                </div>
                <div className="bg-slate-50 border border-slate-200 rounded p-3 font-mono text-sm break-all text-slate-800 select-all">
                  {newSecretModal.rawSecret}
                </div>
              </div>
            </div>
            
            <div className="px-6 py-3 bg-gray-50 flex justify-end gap-2 rounded-b-lg">
              <button
                onClick={() => {
                  setNewSecretModal({ open: false, rawSecret: '' });
                  toast.success('Đã xác nhận lưu an toàn!');
                }}
                className="px-4 py-2 text-sm text-white bg-blue-600 rounded-md hover:bg-blue-700 font-medium"
              >
                Tôi đã sao chép và lưu an toàn
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
