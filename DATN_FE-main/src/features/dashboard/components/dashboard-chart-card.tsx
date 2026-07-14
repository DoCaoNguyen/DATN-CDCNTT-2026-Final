import { Activity } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { formatVND } from '../../../utils/formatters';

interface DashboardChartCardProps {
  chartData: any[];
}

export function DashboardChartCard({ chartData }: DashboardChartCardProps) {
  const formatCurrencyLabel = (value: number) => {
    if (value === 0) return '0';
    if (value >= 1000000000) return `${(value / 1000000000).toFixed(1).replace(/\\.0$/, '')} Tỷ`;
    if (value >= 1000000) return `${(value / 1000000).toFixed(1).replace(/\\.0$/, '')} Tr`;
    if (value >= 1000) return `${(value / 1000).toFixed(0)}K`;
    return value.toString();
  };

  return (
    <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-lg font-bold text-slate-800">Khối lượng giao dịch</h3>
          <p className="text-xs text-slate-500 mt-1">Biến động dòng tiền theo thời gian</p>
        </div>
        <div className="w-10 h-10 rounded-full bg-slate-50 flex items-center justify-center">
          <Activity className="text-slate-400 w-5 h-5" />
        </div>
      </div>

      {chartData && chartData.length > 0 ? (
        <div className="h-[350px] w-full mt-auto">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorAmount" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
              <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fill: '#94a3b8', fontSize: 12 }} dy={10} />
              <YAxis
                axisLine={false}
                tickLine={false}
                tick={{ fill: '#94a3b8', fontSize: 12 }}
                tickFormatter={formatCurrencyLabel}
                width={50}
              />
              <Tooltip
                cursor={{ stroke: '#cbd5e1', strokeWidth: 1, strokeDasharray: '5 5', fill: 'transparent' }}
                contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)', padding: '12px' }}
                itemStyle={{ color: '#0f172a', fontWeight: 'bold' }}
                labelStyle={{ color: '#64748b', marginBottom: '4px' }}
                formatter={(value: any) => [formatVND(value), 'Doanh số']}
              />
              <Area type="monotone" dataKey="amount" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorAmount)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      ) : (
        <div className="h-[350px] w-full mt-auto flex items-center justify-center bg-slate-50 rounded-xl border border-dashed border-slate-200">
          <p className="text-slate-400 text-sm">Chưa có dữ liệu giao dịch</p>
        </div>
      )}
    </div>
  );
}
