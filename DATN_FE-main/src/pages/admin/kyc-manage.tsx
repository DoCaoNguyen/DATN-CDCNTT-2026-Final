import { useEffect, useState, useMemo } from 'react';
import { Eye, ArrowLeft } from 'lucide-react';
import { kycService } from '../../features/kyc-management/kyc.service';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { AdminTable, PageShell, SearchBar, FilterSelect, StatusBadge } from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { ActionMenu, ActionMenuItem } from '../../components/ui/action-menu';
import type { ColumnDef } from '@tanstack/react-table';
import { formatDateTime } from '../../utils/formatters';
import { SplitFormLayout, SplitFormMain, SplitFormSidebar, FormSectionCard, FormSidebarCard, FormActionsBar } from '../../components/organisms/form-layout';

export default function KycManage() {
  const [kycRequests, setKycRequests] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [total, setTotal] = useState(0);
  
  const { params, setQueryParams } = useApiQueryParams();

  const [selectedKyc, setSelectedKyc] = useState<any>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  useEffect(() => {
    fetchKycList();
  }, [JSON.stringify(params)]);

  const fetchKycList = async () => {
    try {
      setIsLoading(true);
      const res = await kycService.getKycList(params.page, params.limit, params.status);
      if (res?.success) {
        setKycRequests(res.data?.items || res.items || (Array.isArray(res.data) ? res.data : []));
        setTotal(res.data?.pagination?.total || res.pagination?.total || 0);
      } else {
        setKycRequests([]);
        setTotal(0);
      }
    } catch (error) {
      console.error('Failed to fetch KYC:', error);
      setKycRequests([]);
      setTotal(0);
    } finally {
      setIsLoading(false);
    }
  };

  const getImageUrl = (path: string) => {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    let baseURL = import.meta.env.VITE_API_URL || import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_BASE_URL || 'http://localhost:3000/api/v1';
    if (baseURL.endsWith('/api/v1')) {
      baseURL = baseURL.replace('/api/v1', '');
    }
    return `${baseURL}/${path.replace(/\\/g, '/')}`;
  };

  const handleApprove = async () => {
    if (!selectedKyc) return;
    try {
      setIsProcessing(true);
      await kycService.approveKyc(selectedKyc.id);
      setSelectedKyc(null);
      fetchKycList();
    } catch (error) {
      console.error('Failed to approve:', error);
      alert('Duyệt thất bại. Vui lòng thử lại.');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleReject = async () => {
    if (!selectedKyc) return;
    try {
      setIsProcessing(true);
      await kycService.rejectKyc(selectedKyc.id);
      setSelectedKyc(null);
      fetchKycList();
    } catch (error) {
      console.error('Failed to reject:', error);
      alert('Từ chối thất bại. Vui lòng thử lại.');
    } finally {
      setIsProcessing(false);
    }
  };

  const columns = useMemo<ColumnDef<any>[]>(
    () => [
      {
        id: 'user',
        header: 'Người dùng',
        cell: ({ row }) => {
          const k = row.original;
          return (
            <div>
              <p className="font-bold text-slate-800">{k.full_name}</p>
              <p className="text-xs text-slate-500">{k.user_id}</p>
            </div>
          );
        }
      },
      {
        accessorKey: 'id_number',
        header: 'CCCD/CMND',
        cell: ({ getValue }) => <span className="font-mono text-sm">{getValue<string>()}</span>
      },
      {
        id: 'face_match',
        header: 'Face Match',
        cell: ({ row }) => {
          const score = Number(row.original.face_match_score);
          const colorClass = score > 80 ? 'text-emerald-600' : 'text-orange-500';
          return <span className={`font-bold ${colorClass}`}>{score}%</span>;
        }
      },
      {
        accessorKey: 'kyc_status',
        header: 'Trạng thái',
        cell: ({ getValue }) => <StatusBadge status={getValue<string>()} />
      },
      {
        accessorKey: 'created_at',
        header: 'Ngày yêu cầu',
        cell: ({ getValue }) => <span className="text-sm">{formatDateTime(getValue<string>())}</span>
      },
      {
        id: 'actions',
        header: () => <div className="text-center">Thao tác</div>,
        cell: ({ row }) => (
          <div className="flex justify-center">
            <ActionMenu>
              <ActionMenuItem 
                icon={<Eye className="w-4 h-4" />} 
                label="Xem chi tiết" 
                onClick={() => setSelectedKyc(row.original)} 
              />
            </ActionMenu>
          </div>
        )
      }
    ],
    []
  );

  if (selectedKyc) {
    return (
      <div className="w-full max-w-7xl mx-auto pb-10">
        <div className="mb-6 flex items-center space-x-4">
          <Button variant="outline" size="icon" onClick={() => setSelectedKyc(null)}>
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <div>
            <h2 className="text-2xl font-bold text-slate-800">Chi tiết hồ sơ định danh (KYC)</h2>
            <p className="text-slate-500 mt-1">Kiểm tra và đối chiếu thông tin khuôn mặt với giấy tờ tùy thân.</p>
          </div>
        </div>

        <SplitFormLayout>
          <SplitFormMain>
            <FormSectionCard title="Hình ảnh cung cấp">
              <div className="grid grid-cols-2 gap-5 mb-5">
                <div className="space-y-2">
                  <p className="text-sm font-semibold text-slate-700 text-center">Mặt trước CCCD</p>
                  <div className="aspect-[1.6/1] bg-slate-100 rounded-xl overflow-hidden border border-slate-200">
                    {selectedKyc.id_front_image ? (
                      <img src={getImageUrl(selectedKyc.id_front_image)} alt="ID Front" className="w-full h-full object-contain bg-black/5" />
                    ) : <div className="w-full h-full flex items-center justify-center text-slate-400">Không có ảnh</div>}
                  </div>
                </div>
                <div className="space-y-2">
                  <p className="text-sm font-semibold text-slate-700 text-center">Mặt sau CCCD</p>
                  <div className="aspect-[1.6/1] bg-slate-100 rounded-xl overflow-hidden border border-slate-200">
                    {selectedKyc.id_back_image ? (
                      <img src={getImageUrl(selectedKyc.id_back_image)} alt="ID Back" className="w-full h-full object-contain bg-black/5" />
                    ) : <div className="w-full h-full flex items-center justify-center text-slate-400">Không có ảnh</div>}
                  </div>
                </div>
              </div>
              <div className="space-y-2 max-w-[250px] mx-auto pt-4 border-t border-slate-100">
                <p className="text-sm font-semibold text-slate-700 text-center">Ảnh khuôn mặt (Selfie)</p>
                <div className="aspect-[3/4] bg-slate-100 rounded-xl overflow-hidden border border-slate-200 shadow-sm">
                  {selectedKyc.face_image ? (
                    <img src={getImageUrl(selectedKyc.face_image)} alt="Selfie" className="w-full h-full object-contain bg-black/5" />
                  ) : <div className="w-full h-full flex items-center justify-center text-slate-400">Không có ảnh</div>}
                </div>
              </div>
            </FormSectionCard>
          </SplitFormMain>
          
          <SplitFormSidebar>
            <FormSidebarCard title="Kết quả đối chiếu">
              <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center mb-6">
                <span className="text-slate-500 font-medium text-sm mb-1">Tỷ lệ trùng khớp (Face Match)</span>
                <span className={`text-4xl font-extrabold ${Number(selectedKyc.face_match_score) > 80 ? 'text-emerald-600' : 'text-orange-500'}`}>
                  {selectedKyc.face_match_score}%
                </span>
              </div>

              <h4 className="text-sm font-bold text-slate-800 uppercase tracking-wider mb-4 border-b border-slate-100 pb-2">Thông tin OCR</h4>
              <div className="space-y-4 text-sm">
                <div><p className="text-slate-500 text-xs">Họ và tên</p><p className="font-bold text-slate-800">{selectedKyc.full_name}</p></div>
                <div><p className="text-slate-500 text-xs">Số CCCD</p><p className="font-bold text-slate-800 font-mono">{selectedKyc.id_number}</p></div>
                <div className="grid grid-cols-2 gap-4">
                  <div><p className="text-slate-500 text-xs">Ngày sinh</p><p className="font-medium text-slate-700">{selectedKyc.dob}</p></div>
                  <div><p className="text-slate-500 text-xs">Giới tính</p><p className="font-medium text-slate-700">{selectedKyc.gender}</p></div>
                </div>
                <div><p className="text-slate-500 text-xs">Địa chỉ</p><p className="font-medium text-slate-700">{selectedKyc.address}</p></div>
              </div>
              
              <div className="mt-6 pt-4 border-t border-slate-100 flex justify-between items-center">
                <span className="text-sm text-slate-500">Trạng thái hiện tại:</span>
                <StatusBadge status={selectedKyc.kyc_status} />
              </div>
            </FormSidebarCard>
          </SplitFormSidebar>
        </SplitFormLayout>
        
        {selectedKyc.kyc_status === 'PENDING' && (
          <FormActionsBar 
            onCancel={handleReject}
            onSubmit={handleApprove}
            isProcessing={isProcessing}
            cancelText="Từ chối hồ sơ (Không hợp lệ)"
            submitText="Duyệt hồ sơ (Hợp lệ)"
          />
        )}
      </div>
    );
  }

  return (
    <PageShell
      title="Xét duyệt KYC"
      description="Quản lý và phê duyệt yêu cầu định danh điện tử của người dùng."
    >
      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tìm theo CCCD, tên..."
        />
        <FilterSelect
          value={params.status || ''}
          onChange={(v) => setQueryParams({ status: v, page: 1 })}
          options={[
            { value: 'PENDING', label: 'Chờ duyệt' },
            { value: 'APPROVED', label: 'Đã duyệt' },
            { value: 'REJECTED', label: 'Từ chối' },
          ]}
          placeholder="Tất cả trạng thái"
        />
      </div>

      <AdminTable 
        columns={columns}
        data={kycRequests}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={Math.ceil(total / params.limit) || 1}
        onPageChange={(page) => setQueryParams({ page })}
        onLimitChange={(limit) => setQueryParams({ limit, page: 1 })}
      />
    </PageShell>
  );
}
