import { Users, Store, ArrowRightLeft, CreditCard, AlertTriangle } from 'lucide-react';
import { formatVND } from '../../../utils/formatters';

interface DashboardKpiGridProps {
  data: any;
}

export function DashboardKpiGrid({ data }: DashboardKpiGridProps) {
  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-8">
      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center transition-all duration-300 hover:shadow-md hover:border-blue-100">
        <div className="w-12 h-12 rounded-full bg-blue-50 flex items-center justify-center text-blue-600 mr-3 shrink-0">
          <Users className="w-6 h-6" />
        </div>
        <div className="overflow-hidden">
          <p className="text-xs font-medium text-slate-500 mb-1">Người dùng ví</p>
          <h3 className="text-xl font-bold text-slate-800 transition-all duration-500">{data?.total_users || 0}</h3>
        </div>
      </div>

      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center transition-all duration-300 hover:shadow-md hover:border-indigo-100">
        <div className="w-12 h-12 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 mr-3 shrink-0">
          <Store className="w-6 h-6" />
        </div>
        <div className="overflow-hidden">
          <p className="text-xs font-medium text-slate-500 mb-1">Merchant</p>
          <h3 className="text-xl font-bold text-slate-800 transition-all duration-500">{data?.total_merchants || 0}</h3>
        </div>
      </div>

      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center transition-all duration-300 hover:shadow-md hover:border-emerald-100">
        <div className="w-12 h-12 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600 mr-3 shrink-0">
          <ArrowRightLeft className="w-6 h-6" />
        </div>
        <div className="overflow-hidden">
          <p className="text-xs font-medium text-slate-500 mb-1">Giao dịch</p>
          <h3 className="text-xl font-bold text-slate-800 transition-all duration-500">{data?.total_transactions || 0}</h3>
        </div>
      </div>

      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center transition-all duration-300 hover:shadow-md hover:border-amber-100">
        <div className="w-12 h-12 rounded-full bg-amber-50 flex items-center justify-center text-amber-600 mr-3 shrink-0">
          <CreditCard className="w-6 h-6" />
        </div>
        <div className="overflow-hidden">
          <p className="text-xs font-medium text-slate-500 mb-1">Dòng tiền</p>
          <h3 className="text-lg font-bold text-slate-800 transition-all duration-500 truncate" title={formatVND(data?.total_amount || 0)}>
            {formatVND(data?.total_amount || 0)}
          </h3>
        </div>
      </div>

      <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center transition-all duration-300 hover:shadow-md hover:border-red-100">
        <div className="w-12 h-12 rounded-full bg-red-50 flex items-center justify-center text-red-600 mr-3 shrink-0">
          <AlertTriangle className="w-6 h-6" />
        </div>
        <div className="overflow-hidden">
          <p className="text-xs font-medium text-slate-500 mb-1">Tỷ lệ lỗi (GD)</p>
          <h3 className="text-xl font-bold text-red-600 transition-all duration-500">{data?.error_rate || 0}%</h3>
        </div>
      </div>
    </div>
  );
}
