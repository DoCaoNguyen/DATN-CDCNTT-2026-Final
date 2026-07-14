import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Loader2, ArrowLeft, Wallet, ArrowDownRight, ArrowUpRight, List } from 'lucide-react';
import { walletService } from '../../features/wallet-management/wallet.service';
import { formatVND, formatDateTime, getStatusVariant } from '../../utils/formatters';

export default function WalletDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [summaryData, setSummaryData] = useState<any>(null);
  const [historyData, setHistoryData] = useState<any[]>([]);
  const [isLoadingDetail, setIsLoadingDetail] = useState(true);

  const fetchWalletDetail = async (walletId: string) => {
    setIsLoadingDetail(true);
    try {
      const [summaryRes, historyRes] = await Promise.all([
        walletService.getWalletSummary(walletId).catch(() => null),
        walletService.getWalletLedger(walletId).catch(() => null)
      ]);
      
      setSummaryData(summaryRes?.data || summaryRes || null);
      
      const rawHistory = historyRes?.data?.items || historyRes?.items || historyRes?.data || [];
      setHistoryData(Array.isArray(rawHistory) ? rawHistory : []);
    } catch (error) {
      console.error('Lỗi tải chi tiết:', error);
    } finally {
      setIsLoadingDetail(false);
    }
  };

  useEffect(() => {
    if (id) fetchWalletDetail(id);
  }, [id]);

  if (isLoadingDetail) {
    return (
      <div className="flex flex-col items-center justify-center p-20">
        <Loader2 className="w-8 h-8 animate-spin text-blue-500 mb-4"/>
        <span className="text-slate-500">Đang tải lịch sử...</span>
      </div>
    );
  }

  if (!summaryData && !isLoadingDetail) {
    return (
      <div className="p-10 text-center">
        <p className="text-slate-500 mb-4">Không tìm thấy thông tin ví.</p>
        <button onClick={() => navigate('/admin/wallets')} className="text-blue-600 underline text-sm">
          Quay lại Quản lý Ví
        </button>
      </div>
    );
  }

  return (
    <div className="w-full max-w-7xl mx-auto pb-10 px-6">
      <button onClick={() => navigate('/admin/wallets')} className="flex items-center text-slate-500 hover:text-slate-800 mb-6 font-medium transition-colors">
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại danh sách
      </button>

      <div className="space-y-6">
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
          <div className="col-span-1 lg:col-span-5 bg-slate-900 text-white p-6 rounded-2xl flex justify-between items-center shadow-lg">
            <div>
              <h2 className="text-xl font-bold flex items-center">
                <Wallet className="w-5 h-5 mr-2 text-blue-400"/> 
                {summaryData?.wallet_no || summaryData?.wallet?.wallet_no || 'Chưa có mã ví'}
              </h2>
              <p className="text-slate-400 mt-1">
                Chủ sở hữu: {summaryData?.owner?.full_name || 'N/A'}
              </p>
            </div>
            <div className="text-right">
              <p className="text-slate-400 text-sm">Số dư khả dụng hiện tại</p>
              <p className="text-3xl font-bold text-emerald-400">
                {formatVND(summaryData?.balance?.available_balance ?? summaryData?.available_balance ?? 0)}
              </p>
            </div>
          </div>
          
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowDownRight className="w-4 h-4 mr-1 text-emerald-500"/> Tổng Tiền Nạp</p>
            <p className="text-xl font-bold text-slate-800">{formatVND(summaryData?.stats?.topup_success_amount || 0)}</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowUpRight className="w-4 h-4 mr-1 text-blue-500"/> Tổng Rút Tiền</p>
            <p className="text-xl font-bold text-slate-800">{formatVND(summaryData?.stats?.withdraw_amount || 0)}</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowUpRight className="w-4 h-4 mr-1 text-red-500"/> Tổng Chuyển đi</p>
            <p className="text-xl font-bold text-slate-800">{formatVND(summaryData?.stats?.transfer_sent_amount || 0)}</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowUpRight className="w-4 h-4 mr-1 text-orange-500"/> Tổng Thanh Toán</p>
            <p className="text-xl font-bold text-slate-800">{formatVND(summaryData?.stats?.payment_amount || 0)}</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowDownRight className="w-4 h-4 mr-1 text-purple-500"/> Tổng Hoàn Tiền</p>
            <p className="text-xl font-bold text-slate-800">{formatVND(summaryData?.stats?.refund_amount || 0)}</p>
          </div>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden flex flex-col">
          <div className="p-5 border-b border-slate-100 flex items-center">
            <List className="w-5 h-5 mr-2 text-blue-600" />
            <h3 className="text-lg font-bold text-slate-800">Sao kê ví</h3>
          </div>
          <div className="overflow-x-auto w-full">
            <table className="w-full text-left border-collapse whitespace-nowrap">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-sm font-semibold text-slate-600">
                  <th className="p-4">Thời gian</th>
                  <th className="p-4">Loại GD</th>
                  <th className="p-4">Mã tham chiếu</th>
                  <th className="p-4 text-right">Biến động</th>
                  <th className="p-4 text-right">Số dư sau GD</th>
                  <th className="p-4 text-center">Trạng thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {historyData.length === 0 ? (
                  <tr><td colSpan={6} className="p-8 text-center text-slate-500">Chưa có dữ liệu biến động số dư.</td></tr>
                ) : (
                  historyData.map((entry) => (
                    <tr key={entry.id} className="hover:bg-slate-50">
                      <td className="p-4 text-slate-600 text-xs font-mono">{formatDateTime(entry.created_at)}</td>
                      <td className="p-4 font-semibold text-slate-700">{entry.transaction_type || '—'}</td>
                      <td className="p-4"><span className="px-2 py-1 bg-slate-100 text-slate-600 rounded font-mono text-xs">{entry.transaction_no || entry.transaction_id || entry.id}</span></td>
                      <td className={`p-4 text-right font-bold ${entry.entry_type === 'CREDIT' ? 'text-emerald-600' : 'text-red-600'}`}>
                        {entry.entry_type === 'CREDIT' ? '+' : '-'}{formatVND(entry.amount)}
                      </td>
                      <td className="p-4 text-right font-semibold text-slate-800">{formatVND(entry.balance_after ?? entry.post_balance ?? 0)}</td>
                      <td className="p-4 text-center">
                        <span className={`px-2 py-1 rounded text-xs font-bold ${getStatusVariant(entry.status).className}`}>
                          {getStatusVariant(entry.status).label}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
