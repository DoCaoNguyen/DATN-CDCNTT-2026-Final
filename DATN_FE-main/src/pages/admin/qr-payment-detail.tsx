import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQrPaymentDetail } from '../../features/payments/hooks/use-payment-orders';
import { formatVND, formatDateTime, getStatusVariant } from '../../utils/formatters';
import { ArrowLeft, QrCode, Calendar, Clock, Store, Hash, Link, AlertTriangle } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';

export default function QrPaymentDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data, isLoading, isError } = useQrPaymentDetail(id || '');

  const qr = data?.data || data;

  const getQrStatusStyle = (status: string) => {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':   return { bar: 'bg-green-500',   badge: 'bg-green-100 text-green-700',   dot: 'bg-green-500' };
      case 'USED':     return { bar: 'bg-violet-500', badge: 'bg-violet-100 text-violet-700', dot: 'bg-violet-500' };
      case 'EXPIRED':  return { bar: 'bg-amber-500',  badge: 'bg-amber-100 text-amber-700',  dot: 'bg-amber-500' };
      case 'CANCELED': return { bar: 'bg-slate-500',  badge: 'bg-slate-100 text-slate-700',  dot: 'bg-slate-500' };
      case 'FAILED':   return { bar: 'bg-red-500',    badge: 'bg-red-100 text-red-700',      dot: 'bg-red-500' };
      default:         return { bar: 'bg-gray-300',   badge: 'bg-gray-100 text-gray-600',    dot: 'bg-gray-300' };
    }
  };

  if (isLoading) {
    return (
      <div className="p-6 flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (isError || !qr) {
    return (
      <div className="p-6 mx-auto">
        <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-slate-500 hover:text-slate-800 mb-6 text-sm">
          <ArrowLeft className="w-4 h-4" /> Quay lại
        </button>
        <div className="bg-white rounded-2xl border border-slate-200 p-12 text-center">
          <QrCode className="w-12 h-12 text-slate-300 mx-auto mb-4" />
          <p className="text-slate-500 font-medium">Không tìm thấy mã QR</p>
          <p className="text-slate-400 text-sm mt-1">ID: {id}</p>
        </div>
      </div>
    );
  }

  const isExpired = qr.expired_at && new Date(qr.expired_at) < new Date();
  const displayQrStatus = (qr.status || qr.qr_status) === 'ACTIVE' && isExpired ? 'EXPIRED' : (qr.status || qr.qr_status);
  const displayOrderStatus = qr.order_status === 'PENDING' && isExpired ? 'EXPIRED' : qr.order_status;

  const statusStyle = getQrStatusStyle(displayQrStatus);
  const orderStatusV = getStatusVariant(displayOrderStatus);

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
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Chi tiết QR Thanh toán</h1>
          <p className="text-slate-400 text-xs font-mono mt-0.5">{qr.id}</p>
        </div>
        <span className={`px-3 py-1.5 rounded-full text-sm font-bold ${statusStyle.badge}`}>
          {displayQrStatus}
        </span>
      </div>

      {/* Status color bar */}
      <div className={`h-1.5 rounded-full ${statusStyle.bar}`} />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* QR Image Card */}
        <div className="md:col-span-1 bg-white rounded-2xl border border-slate-200 p-6 flex flex-col items-center gap-4">
          {qr.qr_payload || qr.qr_token ? (
            <div className="p-2 bg-white border border-slate-100 rounded-xl shadow-sm">
              <QRCodeSVG
                value={qr.qr_payload || qr.qr_token}
                size={160}
                bgColor={"#ffffff"}
                fgColor={"#000000"}
                level={"H"}
              />
            </div>
          ) : qr.qr_image_url ? (
            <img
              src={qr.qr_image_url}
              alt="QR Code"
              className="w-40 h-40 rounded-xl border border-slate-100 object-contain bg-slate-50"
              onError={(e) => {
                (e.target as HTMLImageElement).style.display = 'none';
              }}
            />
          ) : (
            <div className="w-40 h-40 rounded-xl bg-slate-100 flex items-center justify-center">
              <QrCode className="w-16 h-16 text-slate-300" />
            </div>
          )}
          <div className="text-center">
            <p className="text-xs text-slate-400 mb-1">QR Token</p>
            <p className="font-mono text-xs text-slate-600 break-all">{qr.qr_token}</p>
          </div>
        </div>

        {/* Info Cards */}
        <div className="md:col-span-2 space-y-4">
          {/* Merchant & Payment Info */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 space-y-4">
            <h3 className="text-sm font-semibold text-slate-700 flex items-center gap-2">
              <Store className="w-4 h-4 text-slate-400" /> Thông tin đơn hàng
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <InfoRow label="Merchant" value={qr.merchant_name || 'N/A'} />
              <InfoRow label="Mã đơn" value={<span className="font-mono text-xs">{qr.payment_no}</span>} />
              <InfoRow
                label="Số tiền"
                value={<span className="font-bold text-blue-700 text-base">{formatVND(qr.amount)}</span>}
              />
              <InfoRow
                label="Trạng thái đơn"
                value={
                  <span className={`px-2 py-0.5 rounded text-xs font-bold ${orderStatusV.className}`}>
                    {orderStatusV.label}
                  </span>
                }
              />
              <InfoRow
                label="Payment Order ID"
                value={<span className="font-mono text-xs text-slate-500 break-all">{qr.payment_order_id}</span>}
              />
              <InfoRow
                label="Merchant ID"
                value={<span className="font-mono text-xs text-slate-500">{qr.merchant_id}</span>}
              />
            </div>
            {(displayQrStatus === 'CANCELED' || displayOrderStatus === 'CANCELED') && (
              <div className="mt-4 p-3 bg-slate-50 border border-slate-200 rounded-lg">
                <p className="text-sm font-semibold text-slate-800">Trạng thái hiện tại: Đã hủy</p>
                <p className="text-xs text-slate-600 mt-0.5">Mã QR đã bị hủy và không còn hiệu lực thanh toán.</p>
              </div>
            )}
          </div>

          {/* Time Info */}
          <div className="bg-white rounded-2xl border border-slate-200 p-5 space-y-4">
            <h3 className="text-sm font-semibold text-slate-700 flex items-center gap-2">
              <Clock className="w-4 h-4 text-slate-400" /> Thời gian
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <InfoRow label="Tạo lúc" value={formatDateTime(qr.created_at)} />
              <InfoRow label="Hết hạn" value={
                <span className={qr.expired_at && new Date(qr.expired_at) < new Date() ? 'text-red-500 font-medium' : ''}>
                  {formatDateTime(qr.expired_at)}
                </span>
              } />
              {qr.canceled_at && <InfoRow label="Hủy lúc" value={formatDateTime(qr.canceled_at)} />}
              {qr.cancel_reason && (
                <div className="col-span-2">
                  <InfoRow label="Lý do hủy" value={qr.cancel_reason} />
                </div>
              )}
              <InfoRow
                label="Đã sử dụng lúc"
                value={qr.used_at ? formatDateTime(qr.used_at) : <span className="text-slate-300">Chưa sử dụng</span>}
              />
              <InfoRow label="Cập nhật lúc" value={formatDateTime(qr.updated_at)} />
            </div>
          </div>
        </div>
      </div>

      {/* QR Payload */}
      {qr.qr_payload && (
        <div className="bg-white rounded-2xl border border-slate-200 p-5">
          <h3 className="text-sm font-semibold text-slate-700 flex items-center gap-2 mb-3">
            <Link className="w-4 h-4 text-slate-400" /> QR Payload (Deep Link)
          </h3>
          <div className="bg-slate-900 rounded-xl px-4 py-3 flex items-center gap-3">
            <QrCode className="w-4 h-4 text-slate-400 shrink-0" />
            <code className="text-emerald-400 text-sm font-mono break-all">{qr.qr_payload}</code>
          </div>
        </div>
      )}
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="space-y-0.5">
      <p className="text-xs text-slate-400 uppercase tracking-wide font-medium">{label}</p>
      <div className="text-sm text-slate-800">{value ?? 'N/A'}</div>
    </div>
  );
}
