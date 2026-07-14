import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  usePaymentOrderDetail,
  usePaymentTimeline,
  usePaymentLedger,
  usePaymentCallbacks,
} from '../../features/payments/hooks/use-payment-orders';
import { formatVND, formatDateTime, getStatusVariant } from '../../utils/formatters';
import { ArrowLeft, Clock, BookOpen, Webhook, Info, AlertTriangle } from 'lucide-react';
import { Button } from '../../components/ui/button';

type Tab = 'info' | 'timeline' | 'ledger' | 'callbacks';

export default function PaymentOrderDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<Tab>('info');

  const { data: detailData, isLoading } = usePaymentOrderDetail(id || '');
  const { data: timelineData, isLoading: timelineLoading } = usePaymentTimeline(
    activeTab === 'timeline' ? id || '' : ''
  );
  const { data: ledgerData, isLoading: ledgerLoading } = usePaymentLedger(
    activeTab === 'ledger' ? id || '' : ''
  );
  const { data: callbacksData, isLoading: callbacksLoading } = usePaymentCallbacks(
    activeTab === 'callbacks' ? id || '' : ''
  );

  const order = detailData?.data;

  const tabs: { key: Tab; label: string; icon: React.ReactNode }[] = [
    { key: 'info', label: 'Thông tin', icon: <Info className="w-4 h-4" /> },
    { key: 'timeline', label: 'Timeline', icon: <Clock className="w-4 h-4" /> },
    { key: 'ledger', label: 'Sổ cái', icon: <BookOpen className="w-4 h-4" /> },
    { key: 'callbacks', label: 'Webhooks', icon: <Webhook className="w-4 h-4" /> },
  ];

  if (isLoading) {
    return (
      <div className="p-6 flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (!order) {
    return (
      <div className="p-6">
        <p className="text-slate-500">Không tìm thấy đơn hàng.</p>
      </div>
    );
  }

  const isExpired = order.expired_at && new Date(order.expired_at) < new Date();
  const displayStatus = order.status === 'PENDING' && isExpired ? 'EXPIRED' : order.status;

  const statusV = getStatusVariant(displayStatus);

  return (
    <div className="p-6 mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate(-1)}
          className="p-2 rounded-lg hover:bg-slate-100 transition-colors"
        >
          <ArrowLeft className="w-5 h-5 text-slate-600" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">
            Chi tiết đơn hàng
          </h1>
          <p className="text-slate-500 text-sm font-mono">{order.payment_no}</p>
        </div>
        <span className={`ml-auto px-3 py-1 rounded-full text-sm font-bold ${statusV.className}`}>
          {statusV.label}
        </span>
      </div>

      {/* Tab Nav */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="flex border-b border-slate-200">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`flex items-center gap-2 px-5 py-3 text-sm font-medium transition-colors border-b-2 -mb-px ${
                activeTab === tab.key
                  ? 'border-blue-600 text-blue-600 bg-blue-50/50'
                  : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50'
              }`}
            >
              {tab.icon}
              {tab.label}
            </button>
          ))}
        </div>

        <div className="p-6">
          {/* Tab: Thông tin */}
          {activeTab === 'info' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <InfoRow label="Mã đơn" value={<span className="font-mono">{order.payment_no}</span>} />
              <InfoRow label="Merchant" value={order.merchant_name} />
              <InfoRow label="Số tiền" value={<span className="font-bold text-blue-700">{formatVND(order.amount)}</span>} />
              <InfoRow label="Tiền tệ" value={order.currency} />
              <InfoRow label="Phương thức" value={order.payment_method} />
              <InfoRow label="Trạng thái" value={
                <span className={`px-2 py-1 rounded text-xs font-bold ${statusV.className}`}>{statusV.label}</span>
              } />
              <InfoRow label="Tạo lúc" value={formatDateTime(order.created_at)} />
              <InfoRow label="Hết hạn" value={formatDateTime(order.expired_at)} />
              {order.canceled_at && <InfoRow label="Hủy lúc" value={formatDateTime(order.canceled_at)} />}
              {order.cancel_reason && (
                <div className="md:col-span-2">
                  <InfoRow label="Lý do hủy" value={order.cancel_reason} />
                </div>
              )}
              {order.paid_at && <InfoRow label="Thanh toán lúc" value={formatDateTime(order.paid_at)} />}
              {order.description && (
                <div className="md:col-span-2">
                  <InfoRow label="Mô tả" value={order.description} />
                </div>
              )}
              {displayStatus === 'CANCELED' && (
                <div className="md:col-span-2 mt-2 p-3 bg-slate-50 border border-slate-200 rounded-lg">
                  <p className="text-sm font-semibold text-slate-800">Trạng thái hiện tại: Đã hủy</p>
                  <p className="text-xs text-slate-600 mt-0.5">Đơn thanh toán đã bị hủy và không còn hiệu lực.</p>
                </div>
              )}
            </div>
          )}

          {/* Tab: Timeline */}
          {activeTab === 'timeline' && (
            <TimelineTab data={timelineData?.data} isLoading={timelineLoading} />
          )}

          {/* Tab: Ledger */}
          {activeTab === 'ledger' && (
            <LedgerTab data={ledgerData?.data} isLoading={ledgerLoading} />
          )}

          {/* Tab: Callbacks/Webhooks */}
          {activeTab === 'callbacks' && (
            <CallbacksTab data={callbacksData?.data} isLoading={callbacksLoading} />
          )}
        </div>
      </div>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="space-y-1">
      <p className="text-xs font-medium text-slate-400 uppercase tracking-wide">{label}</p>
      <p className="text-sm text-slate-800">{value ?? 'N/A'}</p>
    </div>
  );
}

function TimelineTab({ data, isLoading }: { data: any[]; isLoading: boolean }) {
  if (isLoading) return <LoadingSpinner />;
  if (!data?.length) return <EmptyState message="Không có dữ liệu timeline" />;

  return (
    <div className="relative">
      <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-slate-200" />
      <div className="space-y-6">
        {data.map((item: any, idx: number) => {
          const v = getStatusVariant(item.status || item.event_type);
          return (
            <div key={idx} className="relative flex gap-4 pl-10">
              <div className={`absolute left-2.5 w-3 h-3 rounded-full border-2 border-white ${v.className.includes('emerald') ? 'bg-emerald-500' : v.className.includes('amber') ? 'bg-amber-400' : v.className.includes('red') ? 'bg-red-500' : 'bg-slate-400'}`} />
              <div className="flex-1 bg-slate-50 rounded-xl p-4 border border-slate-100">
                <div className="flex items-center justify-between mb-1">
                  <span className={`px-2 py-0.5 rounded text-xs font-bold ${v.className}`}>
                    {item.status || item.event_type}
                  </span>
                  <span className="text-xs text-slate-400">{formatDateTime(item.created_at || item.occurred_at)}</span>
                </div>
                {item.note && <p className="text-sm text-slate-600 mt-1">{item.note}</p>}
                {item.actor && <p className="text-xs text-slate-400 mt-1">Bởi: {item.actor}</p>}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function LedgerTab({ data, isLoading }: { data: any[]; isLoading: boolean }) {
  if (isLoading) return <LoadingSpinner />;
  if (!data?.length) return <EmptyState message="Không có dữ liệu sổ cái" />;

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200">
            <th className="text-left py-2 px-3 text-slate-500 font-medium text-xs uppercase">Mã GD</th>
            <th className="text-left py-2 px-3 text-slate-500 font-medium text-xs uppercase">Loại</th>
            <th className="text-right py-2 px-3 text-slate-500 font-medium text-xs uppercase">Số tiền</th>
            <th className="text-left py-2 px-3 text-slate-500 font-medium text-xs uppercase">Trạng thái</th>
            <th className="text-left py-2 px-3 text-slate-500 font-medium text-xs uppercase">Thời gian</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {data.map((item: any) => {
            const v = getStatusVariant(item.status);
            return (
              <tr key={item.id} className="hover:bg-slate-50">
                <td className="py-3 px-3 font-mono text-xs text-slate-600">{item.transaction_no}</td>
                <td className="py-3 px-3 text-slate-700">{item.transaction_type}</td>
                <td className="py-3 px-3 text-right font-bold text-slate-800">{formatVND(item.amount)}</td>
                <td className="py-3 px-3">
                  <span className={`px-2 py-0.5 rounded text-xs font-bold ${v.className}`}>{v.label}</span>
                </td>
                <td className="py-3 px-3 text-xs text-slate-500">{formatDateTime(item.created_at)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

function CallbacksTab({ data, isLoading }: { data: any[]; isLoading: boolean }) {
  if (isLoading) return <LoadingSpinner />;
  if (!data?.length) return <EmptyState message="Không có lịch sử webhook" />;

  return (
    <div className="space-y-3">
      {data.map((item: any) => (
        <div key={item._id} className={`rounded-xl border p-4 ${item.http_status >= 200 && item.http_status < 300 ? 'border-emerald-200 bg-emerald-50/50' : 'border-red-200 bg-red-50/50'}`}>
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-2">
              <span className={`text-xs font-bold px-2 py-0.5 rounded ${item.http_status >= 200 && item.http_status < 300 ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                HTTP {item.http_status || 'N/A'}
              </span>
              <span className="text-xs text-slate-500">{item.event_type}</span>
              <span className="text-xs text-slate-400">Lần #{item.attempt_no ?? 0}</span>
            </div>
            <span className="text-xs text-slate-400">{formatDateTime(item.created_at)}</span>
          </div>
          <p className="text-xs text-slate-500 truncate font-mono">{item.callback_url}</p>
          {item.error_message && (
            <p className="text-xs text-red-500 mt-1">{item.error_message}</p>
          )}
        </div>
      ))}
    </div>
  );
}

function LoadingSpinner() {
  return (
    <div className="flex items-center justify-center h-32">
      <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600" />
    </div>
  );
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="flex items-center justify-center h-32 text-slate-400 text-sm">
      {message}
    </div>
  );
}
