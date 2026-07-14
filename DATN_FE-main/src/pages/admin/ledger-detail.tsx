import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useLedgerTransactionDetail } from '../../features/transactions/hooks/use-ledger';
import { StatusBadge } from '../../components/ui/admin-components';
import { formatVND, formatDateTime } from '../../utils/formatters';
import { ArrowLeft, Loader2, BookOpen, Layers } from 'lucide-react';

const TRANSACTION_TYPE_MAP: Record<string, string> = {
  TOPUP: 'Nạp tiền',
  TRANSFER: 'Chuyển tiền',
  PAYMENT: 'Thanh toán',
  REFUND: 'Hoàn tiền',
  WITHDRAW: 'Rút tiền',
  WITHDRAWAL: 'Rút tiền',
  DEPOSIT: 'Nạp tiền',
  ADJUSTMENT: 'Điều chỉnh',
  BANK_TRANSFER: 'Chuyển khoản NH'
};

const SOURCE_TYPE_MAP: Record<string, string> = {
  SYSTEM: 'Hệ thống',
  USER: 'Người dùng',
  MERCHANT: 'Doanh nghiệp',
  ADMIN: 'Quản trị viên',
  PAYMENT: 'Đơn thanh toán',
  WITHDRAWAL: 'Đơn rút tiền',
  DEPOSIT: 'Đơn nạp tiền',
  TOPUP_TRANSACTION: 'GD Nạp tiền',
  PAYMENT_TRANSACTION: 'GD Thanh toán',
  TRANSFER_TRANSACTION: 'GD Chuyển tiền',
  REFUND_TRANSACTION: 'GD Hoàn tiền',
  WITHDRAWAL_TRANSACTION: 'GD Rút tiền',
  DEPOSIT_TRANSACTION: 'GD Nạp tiền',
  TRANSFER: 'Chuyển tiền',
  WALLET_TRANSFER: 'Chuyển tiền nội bộ'
};

export default function LedgerDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data, isLoading } = useLedgerTransactionDetail(id || '');

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600 mb-4" />
        <p className="text-slate-500 font-medium">Đang tải chi tiết bút toán...</p>
      </div>
    );
  }

  const transaction = data?.data || data;

  if (!transaction) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <p className="text-slate-500 font-medium mb-4">Không tìm thấy giao dịch sổ cái.</p>
        <button onClick={() => navigate(-1)} className="text-blue-600 hover:underline">Quay lại</button>
      </div>
    );
  }

  const entries = transaction.entries || [];

  return (
    <div className="w-full max-w-7xl mx-auto pb-10">
      <button 
        onClick={() => navigate(-1)} 
        className="flex items-center text-slate-500 hover:text-slate-800 mb-6 font-medium transition-colors"
      >
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại danh sách
      </button>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden mb-6">
        <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
          <div className="flex items-center">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center mr-4">
              <BookOpen className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-800">
                Chi tiết nghiệp vụ: {transaction.transaction_no || transaction.id}
              </h2>
              <p className="text-sm text-slate-500 mt-1">
                Tạo lúc: {formatDateTime(transaction.created_at)}
              </p>
            </div>
          </div>
          <StatusBadge status={transaction.status} />
        </div>

        <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <p className="text-sm text-slate-500 mb-1">Loại nghiệp vụ</p>
            <p className="font-semibold text-slate-800">{TRANSACTION_TYPE_MAP[transaction.transaction_type] || transaction.transaction_type || '—'}</p>
          </div>
          <div>
            <p className="text-sm text-slate-500 mb-1">Nguồn phát sinh</p>
            <p className="font-semibold text-slate-800">{SOURCE_TYPE_MAP[transaction.source_type] || transaction.source_type || '—'}</p>
          </div>
          <div>
            <p className="text-sm text-slate-500 mb-1">Mã đối tượng nguồn</p>
            <p className="font-mono text-sm text-slate-700 bg-slate-100 px-2 py-1 rounded inline-block">
              {transaction.source_id || '—'}
            </p>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center bg-slate-50/50">
          <Layers className="w-5 h-5 mr-2 text-blue-600" />
          <h3 className="text-lg font-bold text-slate-800">Các bút toán thành phần</h3>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse whitespace-nowrap">
            <thead>
              <tr className="bg-white border-b border-slate-200 text-sm font-semibold text-slate-600">
                <th className="p-4">Thời gian</th>
                <th className="p-4">Đối tượng liên quan</th>
                <th className="p-4">Loại tài khoản</th>
                <th className="p-4">Chiều bút toán</th>
                <th className="p-4 text-right">Số tiền</th>
                <th className="p-4 text-right">Số dư trước</th>
                <th className="p-4 text-right">Số dư sau</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-sm">
              {entries.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-slate-500">
                    Không có bút toán nào trong nghiệp vụ này.
                  </td>
                </tr>
              ) : (
                entries.map((entry: any) => (
                  <tr key={entry.id} className="hover:bg-slate-50">
                    <td className="p-4 text-slate-600 text-xs font-mono">
                      {formatDateTime(entry.created_at)}
                    </td>
                    <td className="p-4">
                      {entry.wallet_id ? (
                        <div>
                          <p className="font-semibold text-slate-700">
                            {entry.wallet_code || entry.wallet_no || (entry.account_type === 'USER_WALLET' ? 'Ví Khách hàng' : 'Ví')}
                          </p>
                          {entry.owner_name && <p className="text-xs text-slate-500">{entry.owner_name}</p>}
                        </div>
                      ) : (
                        <span className="text-slate-700 font-medium">
                          {entry.account_type === 'SYSTEM_ACCOUNT' ? 'Tài khoản Hệ thống' :
                           entry.account_type === 'MERCHANT' ? 'Tài khoản Merchant' : '—'}
                        </span>
                      )}
                    </td>
                    <td className="p-4 font-medium text-slate-700">
                      {entry.account_type || '—'}
                    </td>
                    <td className="p-4">
                      <span className={`px-2 py-1 text-xs font-bold rounded ${
                        entry.entry_type === 'DEBIT' 
                          ? 'bg-red-50 text-red-700' 
                          : 'bg-green-50 text-green-700'
                      }`}>
                        {entry.entry_type === 'DEBIT' ? 'Ghi nợ (DEBIT)' : 'Ghi có (CREDIT)'}
                      </span>
                    </td>
                    <td className="p-4 text-right font-semibold text-slate-800">
                      {formatVND(entry.amount)}
                    </td>
                    <td className="p-4 text-right text-slate-600">
                      {formatVND(entry.balance_before)}
                    </td>
                    <td className="p-4 text-right text-slate-600">
                      {formatVND(entry.balance_after)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
