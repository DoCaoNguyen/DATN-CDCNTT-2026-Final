import { useEffect, useState, useMemo } from 'react';
import { Plus, Edit2, Trash2, Shield, Loader2, ArrowLeft, Info } from 'lucide-react';
import toast from 'react-hot-toast';
import { roleService } from '../../features/role-management/role.service';
import { AdminTable, PageShell } from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { SearchFilterBar } from '../../components/organisms/filters/search-filter-bar';
import { SplitFormLayout, SplitFormMain, SplitFormSidebar, FormSectionCard, FormSidebarCard, FormActionsBar } from '../../components/organisms/form-layout';
import { PermissionMatrix } from '../../features/roles/components/permission-matrix';
import { ConfirmDialog } from '../../components/common/confirm-dialog';
import type { ColumnDef } from '@tanstack/react-table';

export default function RoleManage() {
  const { params, setQueryParams } = useApiQueryParams();
  const [roles, setRoles] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [permissionsList, setPermissionsList] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState<{ open: boolean; id: string; name: string }>({ open: false, id: '', name: '' });
  
  const [currentRole, setCurrentRole] = useState({ id: '', name: '', description: '', permissions: [] as string[] });

  useEffect(() => {
    fetchRolesAndPermissions();
  }, []);

  const fetchRolesAndPermissions = async () => {
    setIsLoading(true);
    try {
      const [rolesRes, permsRes] = await Promise.all([
        roleService.getRoles().catch(() => null),
        roleService.getPermissions().catch(() => null)
      ]);
      
      const rolesData = rolesRes?.data?.items || rolesRes?.items || rolesRes?.data || rolesRes || [];
      const permsData = permsRes?.data || permsRes || [];
      
      setRoles(Array.isArray(rolesData) ? rolesData : []);
      
      if (Array.isArray(permsData) && permsData.length > 0) {
        const codes = permsData.map(p => typeof p === 'string' ? p : p.code);
        setPermissionsList(codes);
      } else {
        setPermissionsList([
          'user.read', 'user.lock', 'user.unlock', 'user.reset_password',
          'wallet.read', 'wallet.lock', 'wallet.unlock',
          'merchant.read', 'merchant.approve', 'merchant.reject', 'merchant.suspend', 'merchant.activate',
          'transaction.read', 'transaction.reconcile',
          'webhook.read', 'webhook.retry',
          'role.read', 'role.create', 'role.update', 'role.delete'
        ]);
      }
    } catch (error) {
      console.error('Lỗi khi tải dữ liệu Role:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenCreate = () => {
    setCurrentRole({ id: '', name: '', description: '', permissions: [] });
    setIsEditing(false);
    setShowModal(true);
  };

  const handleOpenEdit = (role: any) => {
    setCurrentRole({ id: role.id, name: role.name, description: role.description, permissions: role.permissions || [] });
    setIsEditing(true);
    setShowModal(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsProcessing(true);
    try {
      if (isEditing) {
        await roleService.updateRole(currentRole.id, {
          name: currentRole.name,
          description: currentRole.description,
          permissions: currentRole.permissions
        });
        toast.success('Cập nhật Role thành công!');
      } else {
        await roleService.createRole({
          name: currentRole.name,
          description: currentRole.description,
          permissions: currentRole.permissions
        });
        toast.success('Tạo Role thành công!');
      }
      setShowModal(false);
      fetchRolesAndPermissions();
    } catch (error) {
      toast.error('Lỗi lưu Role. Vui lòng thử lại.');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleConfirmDelete = async () => {
    if (!confirmDelete.id) return;
    setIsProcessing(true);
    try {
      await roleService.deleteRole(confirmDelete.id);
      toast.success('Xóa Role thành công!');
      fetchRolesAndPermissions();
    } catch (error) {
      toast.error('Lỗi xóa Role. Role có thể đang được sử dụng.');
    } finally {
      setIsProcessing(false);
      setConfirmDelete({ open: false, id: '', name: '' });
    }
  };

  const togglePermission = (perm: string) => {
    setCurrentRole(prev => {
      const perms = prev.permissions.includes(perm)
        ? prev.permissions.filter(p => p !== perm)
        : [...prev.permissions, perm];
      return { ...prev, permissions: perms };
    });
  };

  const filteredRoles = useMemo(() => {
    let result = roles;
    if (params.search) {
      const s = params.search.toLowerCase();
      result = result.filter(r => 
        r.name?.toLowerCase().includes(s) || r.description?.toLowerCase().includes(s)
      );
    }
    return result;
  }, [roles, params.search]);

  useEffect(() => {
    setTotal(filteredRoles.length);
  }, [filteredRoles]);

  const paginatedRoles = useMemo(() => {
    const startIndex = (params.page - 1) * params.limit;
    return filteredRoles.slice(startIndex, startIndex + params.limit);
  }, [filteredRoles, params.page, params.limit]);

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'name',
      header: 'Tên Role',
      cell: ({ row }) => <span className="font-bold text-slate-800">{row.original.name}</span>
    },
    {
      accessorKey: 'description',
      header: 'Mô tả',
      cell: ({ row }) => <span className="text-slate-600">{row.original.description}</span>
    },
    {
      id: 'permissions',
      header: 'Quyền hạn (Permissions)',
      cell: ({ row }) => {
        const perms = row.original.permissions || [];
        if (perms.length === 0) return <span className="text-slate-400 italic text-xs">Chưa có quyền</span>;
        
        return (
          <div className="flex flex-wrap gap-1.5">
            {perms.map((p: string) => (
              <span key={p} className="px-2 py-1 bg-slate-100 text-slate-600 rounded text-[10px] font-mono font-medium border border-slate-200">
                {p}
              </span>
            ))}
          </div>
        );
      }
    },
    {
      id: 'actions',
      header: () => <div className="text-center">Thao tác</div>,
      cell: ({ row }) => (
        <div className="flex justify-center space-x-2">
          <Button variant="ghost" size="icon" onClick={() => handleOpenEdit(row.original)} className="text-blue-600 hover:bg-blue-50" title="Chỉnh sửa">
            <Edit2 className="w-4 h-4" />
          </Button>
          <Button variant="ghost" size="icon" onClick={() => setConfirmDelete({ open: true, id: row.original.id, name: row.original.name })} className="text-red-600 hover:bg-red-50" title="Xóa">
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      )
    }
  ], []);

  if (showModal) {
    return (
      <div className="w-full max-w-7xl mx-auto pb-10">
        <div className="mb-6 flex items-center space-x-4">
          <Button variant="outline" size="icon" onClick={() => setShowModal(false)}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div>
            <h2 className="text-2xl font-bold text-slate-800">{isEditing ? 'Chỉnh sửa Role' : 'Tạo Role mới'}</h2>
            <p className="text-slate-500 mt-1">Định nghĩa vai trò và ma trận quyền hạn cho hệ thống.</p>
          </div>
        </div>

        <form onSubmit={(e) => { e.preventDefault(); }}>
          <SplitFormLayout>
            <SplitFormMain>
              <FormSectionCard title="Thông tin Role">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-sm font-semibold text-slate-700 mb-1">Tên Role <span className="text-red-500">*</span></label>
                    <input required type="text" value={currentRole.name} onChange={e => setCurrentRole({...currentRole, name: e.target.value})} placeholder="VD: ADMIN, SUPPORT..." className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500/20 outline-none uppercase" />
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-slate-700 mb-1">Mô tả</label>
                    <input type="text" value={currentRole.description} onChange={e => setCurrentRole({...currentRole, description: e.target.value})} placeholder="Mô tả quyền hạn..." className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500/20 outline-none" />
                  </div>
                </div>
              </FormSectionCard>

              <FormSectionCard title="Ma trận Phân quyền">
                <div className="mb-4">
                  <p className="text-sm text-slate-500">Tích chọn các quyền truy cập tương ứng cho role này.</p>
                </div>
                <PermissionMatrix 
                  permissionsList={permissionsList}
                  selectedPermissions={currentRole.permissions}
                  onChange={togglePermission}
                />
              </FormSectionCard>
            </SplitFormMain>
            
            <SplitFormSidebar>
              <FormSidebarCard title="Tóm tắt">
                <div className="space-y-3 text-sm mb-4">
                  <div className="flex justify-between">
                    <span className="text-slate-500">Tên Role:</span>
                    <span className="font-semibold text-slate-800">{currentRole.name || '---'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Số quyền đã chọn:</span>
                    <span className="font-semibold text-indigo-600">{currentRole.permissions.length} quyền</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Trạng thái:</span>
                    <span className="font-semibold text-emerald-600">{isEditing ? 'Đang cập nhật' : 'Sẵn sàng tạo'}</span>
                  </div>
                </div>

                <div className="pt-4 border-t border-slate-100">
                  <p className="text-xs text-slate-500">Lưu ý: Mọi thay đổi quyền hạn sẽ có hiệu lực ngay lập tức với tất cả các tài khoản đang gắn role này.</p>
                </div>
              </FormSidebarCard>
            </SplitFormSidebar>
          </SplitFormLayout>
          
          <FormActionsBar 
            onCancel={() => setShowModal(false)}
            onSubmit={() => {
              const event = new Event('submit', { bubbles: true, cancelable: true });
              handleSubmit(event as any);
            }}
            isProcessing={isProcessing}
            submitText={isEditing ? 'Lưu thay đổi' : 'Tạo Role'}
          />
        </form>
      </div>
    );
  }

  return (
    <PageShell 
      title="Quản lý Roles & Permissions" 
      description="Phân quyền chuẩn RBAC, gán quyền hạt mịn (Granular Permissions)."
      actions={
        <Button onClick={handleOpenCreate}>
          <Plus className="w-4 h-4 mr-2" /> Tạo Role Mới
        </Button>
      }
    >
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 flex justify-end">
        <SearchFilterBar 
          searchPlaceholder="Tìm kiếm role..."
          searchValue={params.search}
          onSearchChange={(val) => setQueryParams({ search: val, page: 1 })}
        />
      </div>

      <AdminTable 
        columns={columns}
        data={paginatedRoles}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={Math.ceil(total / params.limit) || 1}
        onPageChange={(page) => setQueryParams({ page })}
        onLimitChange={(limit) => setQueryParams({ limit, page: 1 })}
      />
      
      <ConfirmDialog
        open={confirmDelete.open}
        onClose={() => setConfirmDelete({ open: false, id: '', name: '' })}
        onConfirm={handleConfirmDelete}
        title="Xóa Role"
        description={`Bạn có chắc chắn muốn xóa role "${confirmDelete.name}"? Hành động này không thể hoàn tác.`}
        variant="danger"
        confirmText="Xóa"
        isLoading={isProcessing}
      />
    </PageShell>
  );
}

