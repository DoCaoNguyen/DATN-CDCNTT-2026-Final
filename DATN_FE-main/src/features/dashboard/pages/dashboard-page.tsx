import { useNavigate } from 'react-router-dom';
import { Users, Store, ArrowRightLeft, CreditCard, Activity, AlertTriangle } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useDashboardKpis } from '../hooks/use-dashboard-kpis';
import { PageHeader } from '../../../components/common/page-header';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { MoneyAmount } from '../../../components/common/money-amount';
import { LoadingState } from '../../../components/common/loading-state';
import { ErrorState } from '../../../components/common/error-state';
import { StatusBadge } from '../../../components/common/status-badge';
import { Button } from '../../../components/ui/button';

export default function DashboardPage() {
  const navigate = useNavigate();
  const { data, isLoading, isError, error, refetch } = useDashboardKpis();

  if (isLoading) {
    return (
      <div className="h-[80vh] flex items-center justify-center">
        <LoadingState message="Đang tải dữ liệu tổng quan..." />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="h-[80vh] flex items-center justify-center">
        <ErrorState error={error?.message} onRetry={() => refetch()} />
      </div>
    );
  }

  const liveBadge = (
    <div className="flex items-center px-2.5 py-1 bg-emerald-50 border border-emerald-100 rounded-full">
      <span className="relative flex h-2.5 w-2.5 mr-2">
        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
      </span>
      <span className="text-[10px] font-bold text-emerald-600 tracking-wider">LIVE</span>
    </div>
  );

  return (
    <div className="w-full max-w-7xl mx-auto pb-10 space-y-8 animate-in fade-in duration-500">
      <PageHeader
        title="Tổng quan Hệ thống"
        description="Theo dõi các chỉ số quan trọng và luồng tiền của ví điện tử."
        action={liveBadge}
      />

      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-5 flex items-center">
            <div className="w-12 h-12 rounded-full bg-blue-50 flex items-center justify-center text-blue-600 mr-3 shrink-0">
              <Users className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500 mb-1">Người dùng</p>
              <h3 className="text-xl font-bold text-slate-800">{data?.total_users || 0}</h3>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-5 flex items-center">
            <div className="w-12 h-12 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 mr-3 shrink-0">
              <Store className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500 mb-1">Merchant</p>
              <h3 className="text-xl font-bold text-slate-800">{data?.total_merchants || 0}</h3>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-5 flex items-center">
            <div className="w-12 h-12 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600 mr-3 shrink-0">
              <ArrowRightLeft className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500 mb-1">Giao dịch</p>
              <h3 className="text-xl font-bold text-slate-800">{data?.total_transactions || 0}</h3>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-5 flex items-center">
            <div className="w-12 h-12 rounded-full bg-amber-50 flex items-center justify-center text-amber-600 mr-3 shrink-0">
              <CreditCard className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500 mb-1">Dòng tiền (VNĐ)</p>
              <h3 className="text-lg font-bold text-slate-800">
                <MoneyAmount amount={data?.total_amount || 0} />
              </h3>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-5 flex items-center">
            <div className="w-12 h-12 rounded-full bg-red-50 flex items-center justify-center text-red-600 mr-3 shrink-0">
              <AlertTriangle className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs font-medium text-slate-500 mb-1">Tỷ lệ lỗi (Giao dịch)</p>
              <h3 className="text-xl font-bold text-red-600">{data?.error_rate || 0}%</h3>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Biểu đồ khối lượng giao dịch */}
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg">Khối lượng giao dịch</CardTitle>
            <Activity className="text-slate-400 w-5 h-5" />
          </CardHeader>
          <CardContent>
            <div className="h-[350px] w-full mt-4">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data?.chart_data || []}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 12 }} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 12 }}
                    tickFormatter={(value) => value === 0 ? '0' : `${(value / 1000000).toFixed(0)}M`}
                  />
                  <Tooltip
                    cursor={{ fill: '#f8fafc' }}
                    formatter={(value: any) => [
                      new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value),
                      'Doanh số'
                    ]}
                  />
                  <Bar dataKey="amount" fill="#3b82f6" radius={[4, 4, 0, 0]} maxBarSize={40} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Giao dịch gần đây */}
        <Card className="flex flex-col h-full">
          <CardHeader>
            <CardTitle className="text-lg">Giao dịch gần đây</CardTitle>
          </CardHeader>
          <CardContent className="flex-1 flex flex-col">
            <div className="space-y-4 flex-1">
              {(data?.recent_transactions || []).map((tx, idx) => (
                <div key={idx} className="flex items-center justify-between p-2 hover:bg-slate-50 rounded-xl transition-colors cursor-pointer group">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center group-hover:bg-white group-hover:shadow-sm transition-all">
                      <ArrowRightLeft className="w-4 h-4 text-slate-500" />
                    </div>
                    <div>
                      <p className="font-semibold text-slate-800 text-sm">{tx.transaction_type}</p>
                      <p className="text-[11px] text-slate-500 font-mono mt-0.5">{tx.transaction_no}</p>
                    </div>
                  </div>
                  <div className="text-right flex flex-col items-end gap-1">
                    <MoneyAmount amount={tx.amount} className={tx.status === 'FAILED' ? 'text-slate-400 line-through text-sm' : 'text-sm'} />
                    <StatusBadge status={tx.status} />
                  </div>
                </div>
              ))}
            </div>
            <Button
              variant="outline"
              className="w-full mt-6"
              onClick={() => navigate('/admin/ledger')}
            >
              Xem tất cả giao dịch
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
