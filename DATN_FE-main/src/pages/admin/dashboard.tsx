import { useEffect, useState } from 'react';
import { Loader2 } from 'lucide-react';
import { axiosInstance } from '../../config/axios-instance';
import { DashboardKpiGrid } from '../../features/dashboard/components/dashboard-kpi-grid';
import { DashboardChartCard } from '../../features/dashboard/components/dashboard-chart-card';
import { RecentTransactionCard } from '../../features/dashboard/components/recent-transaction-card';
import { io } from 'socket.io-client';

export default function Dashboard() {
  const [data, setData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    let socket: ReturnType<typeof io> | null = null;

    const fetchDashboard = async () => {
      try {
        const res = await axiosInstance.get('/admin/dashboard/kpis');
        if (isMounted) {
          const payload = res.data?.data || res.data;
          setData(payload);
        }
      } catch (error: any) {
        if (isMounted) {
          console.error("Lỗi tải Dashboard:", error);
        }
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    };

    fetchDashboard();

    // Kết nối Socket.io để nhận realtime KPI update
    const token = localStorage.getItem('access_token');
    const baseUrl = import.meta.env.VITE_API_URL || import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';
    const socketUrl = baseUrl.replace('/api/v1', '');
    
    socket = io(socketUrl, {
      auth: { token }
    });

    socket.on('connect', () => {
      console.log('Socket connected to Admin Dashboard');
    });

    socket.on('DASHBOARD_UPDATE', (update: any) => {
      console.log('Real-time Dashboard Update:', update);
      if (!isMounted) return;
      
      setData((prev: any) => {
        if (!prev) return prev;
        
        // Thêm transaction mới vào đầu danh sách (tối đa 5 phần tử)
        const newTx = {
            transaction_no: update.transaction_no || ('TX-' + Math.floor(Math.random() * 1000000)), 
            transaction_type: update.type,
            amount: update.amount,
            currency: 'VND',
            status: update.status,
            created_at: update.timestamp || new Date().toISOString()
        };
        const recent = [newTx, ...(prev.recent_transactions || [])].slice(0, 5);
        const isSuccess = update.status === 'SUCCESS';

        // Update chart_data cho ngày hôm nay nếu giao dịch THÀNH CÔNG
        const newChartData = [...(prev.chart_data || [])];
        if (isSuccess) {
            const todayStr = new Date().toLocaleDateString('en-GB', { day: '2-digit', month: '2-digit' }); // "DD/MM"
            const todayIndex = newChartData.findIndex((c: any) => c.time === todayStr);
            if (todayIndex >= 0) {
                newChartData[todayIndex] = {
                    ...newChartData[todayIndex],
                    amount: newChartData[todayIndex].amount + update.amount
                };
            } else {
                newChartData.push({ time: todayStr, amount: update.amount });
            }
        }

        return {
          ...prev,
          total_transactions: prev.total_transactions + 1,
          total_amount: prev.total_amount + (isSuccess ? update.amount : 0),
          recent_transactions: recent,
          chart_data: newChartData
        };
      });
    });

    return () => {
      isMounted = false;
      if (socket) {
        socket.disconnect();
      }
    };
  }, []);

  if (isLoading) {
    return (
      <div className="w-full h-[80vh] flex items-center justify-center">
        <Loader2 className="w-10 h-10 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="w-full max-w-7xl mx-auto pb-10">
      <div className="mb-8 flex flex-col xl:flex-row xl:items-end justify-between gap-4">
        <div>
          <div className="flex items-center space-x-3">
            <h2 className="text-3xl font-bold text-slate-800">Tổng quan Hệ thống</h2>
            <div className="flex items-center px-2.5 py-1 bg-emerald-50 border border-emerald-100 rounded-full mt-1">
              <span className="relative flex h-2.5 w-2.5 mr-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
              </span>
              <span className="text-[10px] font-bold text-emerald-600 tracking-wider">LIVE</span>
            </div>
          </div>
          <p className="text-slate-500 mt-1">Theo dõi các chỉ số quan trọng và luồng tiền của ví điện tử hôm nay.</p>
        </div>
      </div>

      <DashboardKpiGrid data={data} />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <DashboardChartCard chartData={data?.chart_data || []} />
        <RecentTransactionCard transactions={data?.recent_transactions || []} />
      </div>
    </div>
  );
}
