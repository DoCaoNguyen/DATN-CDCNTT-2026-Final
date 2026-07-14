import { useMemo } from 'react';
import { Shield } from 'lucide-react';

interface PermissionMatrixProps {
  permissionsList: string[];
  selectedPermissions: string[];
  onChange: (perm: string) => void;
  disabled?: boolean;
}

export function PermissionMatrix({ permissionsList, selectedPermissions, onChange, disabled }: PermissionMatrixProps) {
  const groupedPermissions = useMemo(() => {
    return permissionsList.reduce((acc, perm) => {
      const [module] = perm.split('.');
      if (!acc[module]) acc[module] = [];
      acc[module].push(perm);
      return acc;
    }, {} as Record<string, string[]>);
  }, [permissionsList]);

  const toggleModule = (module: string) => {
    if (disabled) return;
    const modulePerms = groupedPermissions[module];
    const allSelected = modulePerms.every(p => selectedPermissions.includes(p));
    
    if (allSelected) {
      // Remove all
      modulePerms.forEach(p => {
        if (selectedPermissions.includes(p)) onChange(p);
      });
    } else {
      // Add all missing
      modulePerms.forEach(p => {
        if (!selectedPermissions.includes(p)) onChange(p);
      });
    }
  };

  return (
    <div className="space-y-4">
      {Object.entries(groupedPermissions).map(([module, perms]) => {
        const isAllSelected = perms.every(p => selectedPermissions.includes(p));
        const isIndeterminate = !isAllSelected && perms.some(p => selectedPermissions.includes(p));

        return (
          <div key={module} className="border border-slate-200 rounded-xl overflow-hidden bg-white">
            <div className="bg-slate-50 p-3 border-b border-slate-200 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Shield className="w-4 h-4 text-indigo-500" />
                <h4 className="font-semibold text-slate-800 uppercase text-sm">{module}</h4>
              </div>
              <label className="flex items-center space-x-2 cursor-pointer">
                <span className="text-xs font-medium text-slate-500">Chọn tất cả</span>
                <input
                  type="checkbox"
                  disabled={disabled}
                  checked={isAllSelected}
                  ref={input => {
                    if (input) input.indeterminate = isIndeterminate;
                  }}
                  onChange={() => toggleModule(module)}
                  className="w-4 h-4 text-indigo-600 rounded focus:ring-indigo-500 disabled:opacity-50"
                />
              </label>
            </div>
            <div className="p-4 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
              {perms.map(perm => (
                <label key={perm} className={`flex items-center space-x-2 p-2 rounded-lg border transition-colors ${
                  selectedPermissions.includes(perm) ? 'border-indigo-200 bg-indigo-50/50' : 'border-transparent hover:bg-slate-50'
                } ${disabled ? 'opacity-70 cursor-not-allowed' : 'cursor-pointer'}`}>
                  <input
                    type="checkbox"
                    disabled={disabled}
                    checked={selectedPermissions.includes(perm)}
                    onChange={() => onChange(perm)}
                    className="w-4 h-4 text-indigo-600 rounded focus:ring-indigo-500 disabled:opacity-50"
                  />
                  <span className="text-xs font-mono text-slate-700 font-medium break-all">{perm}</span>
                </label>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}
