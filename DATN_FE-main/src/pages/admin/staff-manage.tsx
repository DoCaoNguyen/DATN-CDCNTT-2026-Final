import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, UserCog } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { staffService } from '../../features/user-management/staff.service';
import {
  AdminTable, PageShell, SearchBar, FilterSelect, StatusBadge,
} from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { ActionMenu, ActionMenuItem } from '../../components/ui/action-menu';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import type { ColumnDef } from '@tanstack/react-table';
import { formatDateTime, getStatusVariant, formatDisplayPhone } from '../../utils/formatters';

const ROLE_OPTIONS = [
  { value: 'SUPER_ADMIN', label: 'Super Admin' },
  { value: 'ADMIN', label: 'Admin' },
  { value: 'SUPPORT_STAFF', label: 'Support Staff' },
];

function useStaffs(params: any) {
  return useQuery({
    queryKey: ['admin-staffs', params],
    queryFn: () => staffService.getStaffs(params.search, params.page, params.limit, params.type),
  });
}

export default function StaffManage() {
  const navigate = useNavigate();
  const { params, setQueryParams } = useApiQueryParams();
  const { data, isLoading } = useStaffs(params);

  const items = data?.items ?? (Array.isArray(data) ? data : []);
  const total = data?.pagination?.total ?? data?.total ?? 0;
  const totalPages = data?.pagination ? Math.ceil(total / params.limit) : (data?.total_pages ?? 1);

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'full_name',
      header: 'Nhân viên',
      cell: ({ row }) => (
        <div>
          <p className="font-medium text-gray-900">{row.original.full_name}</p>
          <p className="text-xs font-mono text-gray-500">{row.original.username || '—'}</p>
        </div>
      ),
    },
    {
      accessorKey: 'phone',
      header: 'SĐT',
      cell: ({ getValue }) => {
        const phoneStr = getValue<string>();
        return <span className="text-sm text-gray-700">{phoneStr ? formatDisplayPhone(phoneStr) : '—'}</span>;
      },
    },
    {
      accessorKey: 'email',
      header: 'Email',
      cell: ({ getValue }) => <span className="text-sm text-gray-700">{getValue<string>() || '—'}</span>,
    },
    {
      id: 'roles',
      header: 'Vai trò',
      cell: ({ row }) => {
        const roles: string[] = row.original.roles || row.original.role_codes || [];
        return (
          <div className="flex flex-wrap gap-1">
            {roles.length ? roles.map((r: string) => (
              <span key={r} className="text-xs px-2 py-0.5 bg-blue-50 text-blue-700 rounded font-medium">{r}</span>
            )) : '—'}
          </div>
        );
      },
    },
    {
      accessorKey: 'status',
      header: 'Trạng thái',
      cell: ({ getValue }) => <StatusBadge status={getValue<string>()} />,
    },
    {
      accessorKey: 'created_at',
      header: 'Ngày tạo',
      cell: ({ getValue }) => <span className="text-sm text-gray-500">{formatDateTime(getValue<string>())}</span>,
    },
    {
      id: 'actions',
      header: () => <div className="text-center">Thao tác</div>,
      cell: ({ row }) => (
        <div className="flex justify-center">
          <ActionMenu>
            <ActionMenuItem 
              icon={<UserCog className="w-4 h-4" />} 
              label="Xem chi tiết" 
              onClick={() => navigate(`/admin/staffs/${row.original.id}`)} 
            />
          </ActionMenu>
        </div>
      ),
    },
  ], [navigate]);

  return (
    <PageShell
      title="Nhân viên"
      description="Quản lý tài khoản nhân viên và phân quyền hệ thống."
      actions={
        <Button onClick={() => navigate('/admin/staffs/create')}>
          <Plus className="w-4 h-4 mr-2" /> Tạo nhân viên
        </Button>
      }
    >
      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tìm theo tên, username..."
        />
        <FilterSelect
          value={params.type || ''}
          onChange={(v) => setQueryParams({ type: v, page: 1 })}
          options={ROLE_OPTIONS}
          placeholder="Vai trò"
        />
      </div>

      <AdminTable
        columns={columns}
        data={items}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={totalPages}
        onPageChange={(p) => setQueryParams({ page: p })}
        onLimitChange={(l) => setQueryParams({ limit: l, page: 1 })}
        emptyIcon={<UserCog className="w-10 h-10 text-gray-300 mx-auto" />}
        emptyText="Chưa có nhân viên nào"
      />
    </PageShell>
  );
}
