import { Navigate, useLocation } from 'react-router-dom';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const token = localStorage.getItem('access_token');
  const location = useLocation();

  if (!token) {
    // Lưu lại vị trí người dùng muốn truy cập để redirect sau khi login
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
