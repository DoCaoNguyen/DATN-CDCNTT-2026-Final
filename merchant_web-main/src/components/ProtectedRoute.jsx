
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import useAuthStore from '../store/useAuthStore';

const ProtectedRoute = () => {
  const { token, isMerchant, isForceChangePassword } = useAuthStore();
  const location = useLocation();

  if (!token) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (!isMerchant()) {
    // Nếu có token nhưng không phải merchant, logout và đá về login
    useAuthStore.getState().logout();
    return <Navigate to="/login" replace />;
  }

  const isChangingPassword = location.pathname === '/merchant/change-password';

  if (isForceChangePassword() && !isChangingPassword) {
    return <Navigate to="/merchant/change-password" replace />;
  }

  if (!isForceChangePassword() && isChangingPassword) {
    return <Navigate to="/merchant/dashboard" replace />;
  }

  return <Outlet />;
};

export default ProtectedRoute;
