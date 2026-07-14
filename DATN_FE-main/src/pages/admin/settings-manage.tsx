import { useEffect, useState } from 'react';
import { Settings, Edit2, History, Loader2, ArrowLeft } from 'lucide-react';
import toast from 'react-hot-toast';
import { settingsService } from '../../features/settings/settings.service';
import { AdminTable, PageShell } from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import type { ColumnDef } from '@tanstack/react-table';

export default function SettingsManage() {
  const [settings, setSettings] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [showEditModal, setShowEditModal] = useState(false);
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [currentSetting, setCurrentSetting] = useState<any>(null);
  const [newValue, setNewValue] = useState('');
  
  const [historyLogs, setHistoryLogs] = useState<any[]>([]);
  const [isHistoryLoading, setIsHistoryLoading] = useState(false);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    setIsLoading(true);
    try {
      const res = await settingsService.getSettings();
      // Extract items based on standard API wrapper
      const data = res?.data || res || [];
      setSettings(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Lỗi tải settings:', error);
      toast.error('Không thể tải cấu hình hệ thống');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenEdit = (setting: any) => {
    setCurrentSetting(setting);
    setNewValue(
      typeof setting.setting_value === 'object' 
        ? JSON.stringify(setting.setting_value, null, 2) 
        : String(setting.setting_value)
    );
    setShowEditModal(true);
  };

  const handleOpenHistory = async (key: string) => {
    setCurrentSetting({ setting_key: key });
    setShowHistoryModal(true);
    setIsHistoryLoading(true);
    try {
      const res = await settingsService.getHistory(key, { page: 1, limit: 50 });
      const data = res?.data?.items || res?.items || [];
      setHistoryLogs(Array.isArray(data) ? data : []);
    } catch (error) {
      toast.error('Không thể tải lịch sử');
    } finally {
      setIsHistoryLoading(false);
    }
  };

  const handleSubmitEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentSetting) return;
    
    setIsProcessing(true);
    try {
      let payloadValue: any = newValue;
      
      // Parse if JSON or boolean
      if (currentSetting.value_type === 'JSON') {
        try {
          payloadValue = JSON.parse(newValue);
        } catch {
          toast.error('Giá trị JSON không hợp lệ');
          setIsProcessing(false);
          return;
        }
      } else if (currentSetting.value_type === 'BOOLEAN') {
        payloadValue = newValue === 'true';
      } else if (currentSetting.value_type === 'NUMBER') {
        payloadValue = Number(newValue);
        if (isNaN(payloadValue)) {
          toast.error('Giá trị số không hợp lệ');
          setIsProcessing(false);
          return;
        }
      } else if (currentSetting.value_type === 'STRING' && !newValue.trim()) {
        toast.error('Giá trị chuỗi không được để trống');
        setIsProcessing(false);
        return;
      }

      await settingsService.updateSetting(currentSetting.setting_key, payloadValue);
      toast.success('Cập nhật thành công!');
      setShowEditModal(false);
      fetchSettings();
    } catch (error) {
      toast.error('Lỗi khi cập nhật cấu hình');
    } finally {
      setIsProcessing(false);
    }
  };

  const columns: ColumnDef<any>[] = [
    {
      accessorKey: 'setting_key',
      header: 'Mã cấu hình',
      cell: ({ row }) => <span className="font-medium text-slate-700">{row.original.setting_key}</span>,
    },
    {
      accessorKey: 'setting_group',
      header: 'Nhóm',
      cell: ({ row }) => (
        <span className="px-2 py-1 bg-slate-100 text-slate-600 rounded text-xs font-medium uppercase">
          {row.original.setting_group}
        </span>
      ),
    },
    {
      accessorKey: 'description',
      header: 'Mô tả',
      cell: ({ row }) => <span className="text-slate-500">{row.original.description}</span>,
    },
    {
      accessorKey: 'setting_value',
      header: 'Giá trị',
      cell: ({ row }) => {
        const val = row.original.setting_value;
        const type = row.original.value_type;
        const display = typeof val === 'object' ? JSON.stringify(val) : String(val);
        
        return (
          <div className="max-w-[200px] truncate" title={display}>
            {row.original.is_sensitive ? '********' : display}
            <span className="ml-2 text-xs text-slate-400">({type})</span>
          </div>
        );
      },
    },
    {
      accessorKey: 'updated_at',
      header: 'Cập nhật lần cuối',
      cell: ({ row }) => (
        <span className="text-sm text-slate-500">
          {row.original.updated_at ? new Date(row.original.updated_at).toLocaleString('vi-VN') : '-'}
        </span>
      ),
    },
    {
      id: 'actions',
      header: 'Thao tác',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => handleOpenEdit(row.original)}
            className="text-blue-600 hover:bg-blue-50"
            title="Chỉnh sửa"
          >
            <Edit2 className="w-4 h-4" />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            onClick={() => handleOpenHistory(row.original.setting_key)}
            className="text-slate-500 hover:bg-slate-100"
            title="Lịch sử"
          >
            <History className="w-4 h-4" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <PageShell
      title="Cài đặt chung"
      description="Quản lý các tham số hệ thống và cấu hình kinh doanh"
    >
      <div className="bg-white rounded-xl shadow-sm border border-slate-200">
        <AdminTable
          columns={columns}
          data={settings}
          isLoading={isLoading}
        />
      </div>

      {/* MODAL SỬA */}
      {showEditModal && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
              <h3 className="font-semibold text-lg text-slate-800">Cập nhật cấu hình</h3>
              <Button variant="ghost" size="icon" onClick={() => setShowEditModal(false)} className="text-slate-400">×</Button>
            </div>
            <form onSubmit={handleSubmitEdit} className="p-6">
              <div className="mb-4">
                <label className="block text-sm font-medium text-slate-700 mb-1">Mã cấu hình</label>
                <input type="text" value={currentSetting?.setting_key || ''} disabled className="w-full px-3 py-2 border rounded-lg bg-slate-50 text-slate-500" />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-slate-700 mb-1">Kiểu dữ liệu</label>
                <input type="text" value={currentSetting?.value_type || ''} disabled className="w-full px-3 py-2 border rounded-lg bg-slate-50 text-slate-500" />
              </div>
              <div className="mb-6">
                <label className="block text-sm font-medium text-slate-700 mb-1">Giá trị mới <span className="text-red-500">*</span></label>
                {currentSetting?.value_type === 'JSON' ? (
                  <textarea
                    required
                    value={newValue}
                    onChange={(e) => setNewValue(e.target.value)}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 h-32 font-mono text-sm"
                  />
                ) : currentSetting?.value_type === 'NUMBER' ? (
                  <input
                    type="number"
                    step="any"
                    required
                    value={newValue}
                    onChange={(e) => setNewValue(e.target.value)}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                ) : currentSetting?.value_type === 'BOOLEAN' ? (
                  <select
                    required
                    value={newValue}
                    onChange={(e) => setNewValue(e.target.value)}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="true">True (Bật)</option>
                    <option value="false">False (Tắt)</option>
                  </select>
                ) : (
                  <input
                    type="text"
                    required
                    value={newValue}
                    onChange={(e) => setNewValue(e.target.value)}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                )}
                {currentSetting?.is_sensitive && (
                  <p className="text-xs text-orange-500 mt-1">Đây là cấu hình nhạy cảm. Giá trị sẽ bị ẩn sau khi lưu.</p>
                )}
              </div>
              
              <div className="flex justify-end gap-3">
                <Button variant="outline" type="button" onClick={() => setShowEditModal(false)}>
                  Hủy
                </Button>
                <Button variant="primary" type="submit" disabled={isProcessing}>
                  {isProcessing && <Loader2 className="w-4 h-4 mr-2 animate-spin" />} Lưu thay đổi
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL LỊCH SỬ */}
      {showHistoryModal && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[80vh] flex flex-col">
            <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
              <h3 className="font-semibold text-lg text-slate-800">Lịch sử thay đổi: {currentSetting?.setting_key}</h3>
              <Button variant="ghost" size="icon" onClick={() => setShowHistoryModal(false)} className="text-slate-400">×</Button>
            </div>
            <div className="p-6 overflow-y-auto flex-1">
              {isHistoryLoading ? (
                <div className="flex justify-center p-8"><Loader2 className="w-6 h-6 animate-spin text-slate-400" /></div>
              ) : historyLogs.length === 0 ? (
                <p className="text-center text-slate-500 py-8">Chưa có lịch sử thay đổi nào</p>
              ) : (
                <div className="space-y-4">
                  {historyLogs.map((log: any, idx) => (
                    <div key={idx} className="border border-slate-100 p-4 rounded-lg bg-slate-50">
                      <div className="flex justify-between items-center mb-2">
                        <span className="font-medium text-slate-700 text-sm">Bởi Admin: {log.actor_id}</span>
                        <span className="text-xs text-slate-500">{new Date(log.created_at).toLocaleString('vi-VN')}</span>
                      </div>
                      <div className="grid grid-cols-2 gap-4 text-sm mt-3">
                        <div className="bg-red-50 p-3 rounded border border-red-100 overflow-x-auto">
                          <p className="text-red-700 font-semibold mb-1 text-xs">Giá trị cũ</p>
                          <pre className="text-xs text-slate-700">{JSON.stringify(log.old_data?.setting_value, null, 2)}</pre>
                        </div>
                        <div className="bg-green-50 p-3 rounded border border-green-100 overflow-x-auto">
                          <p className="text-green-700 font-semibold mb-1 text-xs">Giá trị mới</p>
                          <pre className="text-xs text-slate-700">{JSON.stringify(log.new_data?.setting_value, null, 2)}</pre>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </PageShell>
  );
}
