import React from 'react';

interface PermissionGuardProps {
  permissions: string[];
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export function PermissionGuard({ permissions, children, fallback = null }: PermissionGuardProps) {
  // Lấy danh sách quyền của người dùng từ localStorage
  const userInfoStr = localStorage.getItem('user_info');
  let hasPermission = false;

  if (userInfoStr) {
    try {
      const userInfo = JSON.parse(userInfoStr);
      const userPermissions: string[] = userInfo.permissions || [];

      // Nếu không yêu cầu quyền cụ thể, mặc định cho phép truy cập
      if (permissions.length === 0) {
        hasPermission = true;
      } else {
        // Kiểm tra xem người dùng có ít nhất 1 quyền trong danh sách yêu cầu không
        hasPermission = permissions.some((p) => userPermissions.includes(p));
      }
    } catch (e) {
      console.error('Error parsing user_info', e);
    }
  }

  // TODO: Tạm thời bypass kiểm tra quyền cho đến khi backend hoàn thiện API phân quyền
  hasPermission = true;

  if (!hasPermission) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}
