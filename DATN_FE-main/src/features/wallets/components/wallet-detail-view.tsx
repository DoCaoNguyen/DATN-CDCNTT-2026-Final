import { ArrowLeft, Wallet as WalletIcon, ArrowDownRight, ArrowUpRight, List } from 'lucide-react';
import { Button } from '../../../components/ui/button';
import { MoneyAmount } from '../../../components/common/money-amount';
import { WalletLedgerTable } from './wallet-ledger-table';
import { useWalletSummary, useWalletLedger } from '../hooks/use-wallets';
import { LoadingState } from '../../../components/common/loading-state';
import type { Wallet } from '../types/wallet.type';

interface WalletDetailViewProps {
  wallet: Wallet;
  onBack: () => void;
}

export function WalletDetailView({ wallet, onBack }: WalletDetailViewProps) {
  const { data: summary, isLoading: isLoadingSummary } = useWalletSummary(wallet.id);
  const { data: ledger = [], isLoading: isLoadingLedger } = useWalletLedger(wallet.id);

  if (isLoadingSummary) {
    return <div className="py-20"><LoadingState message="Đang tải thông tin chi tiết ví..." /></div>;
  }

  const availableBalance = summary?.balance?.available_balance ?? wallet.balance?.available_balance ?? wallet.available_balance ?? 0;
  const ownerName = summary?.owner?.full_name || wallet.user?.full_name || wallet.full_name || 'N/A';

  return (
    <div className="space-y-6 animate-in slide-in-from-right-4 duration-300">
      <Button variant="ghost" onClick={onBack} className="text-slate-500 hover:text-slate-800 -ml-4 mb-2">
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại danh sách
      </Button>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <div className="col-span-1 lg:col-span-5 bg-slate-900 text-white p-6 rounded-2xl flex justify-between items-center shadow-lg">
          <div>
            <h2 className="text-xl font-bold flex items-center">
              <WalletIcon className="w-5 h-5 mr-2 text-blue-400"/> 
              {summary?.wallet?.wallet_no || wallet.wallet_no}
            </h2>
            <p className="text-slate-400 mt-1">Chủ sở hữu: {ownerName}</p>
          </div>
          <div className="text-right">
            <p className="text-slate-400 text-sm">Số dư khả dụng hiện tại</p>
            <p className="text-3xl font-bold text-emerald-400">
              <MoneyAmount amount={availableBalance} />
            </p>
          </div>
        </div>
        
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowDownRight className="w-4 h-4 mr-1 text-emerald-500"/> Tổng Tiền Nạp</p>
          <p className="text-xl font-bold text-slate-800"><MoneyAmount amount={summary?.stats?.topup_success_amount || 0} /></p>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowUpRight className="w-4 h-4 mr-1 text-blue-500"/> Tổng Rút Tiền</p>
          <p className="text-xl font-bold text-slate-800"><MoneyAmount amount={summary?.stats?.withdraw_amount || 0} /></p>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowUpRight className="w-4 h-4 mr-1 text-red-500"/> Tổng Chuyển đi</p>
          <p className="text-xl font-bold text-slate-800"><MoneyAmount amount={summary?.stats?.transfer_sent_amount || 0} /></p>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowUpRight className="w-4 h-4 mr-1 text-orange-500"/> Tổng Thanh Toán</p>
          <p className="text-xl font-bold text-slate-800"><MoneyAmount amount={summary?.stats?.payment_amount || 0} /></p>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <p className="text-slate-500 text-sm font-semibold flex items-center mb-2"><ArrowDownRight className="w-4 h-4 mr-1 text-purple-500"/> Tổng Hoàn Tiền</p>
          <p className="text-xl font-bold text-slate-800"><MoneyAmount amount={summary?.stats?.refund_amount || 0} /></p>
        </div>
      </div>

      <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center">
          <List className="w-5 h-5 mr-2 text-blue-600" />
          <h3 className="text-lg font-bold text-slate-800">Lịch sử biến động sổ cái (Ledger)</h3>
        </div>
        <WalletLedgerTable ledger={ledger} isLoading={isLoadingLedger} />
      </div>
    </div>
  );
}
