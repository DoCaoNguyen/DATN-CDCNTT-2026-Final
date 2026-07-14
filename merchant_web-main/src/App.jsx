import { Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'sonner';
import ProtectedRoute from './components/ProtectedRoute';
import AuthLayout from './layouts/AuthLayout';
import MainLayout from './layouts/MainLayout';
import Login from './pages/Login';
import ChangePassword from './pages/ChangePassword';
import Dashboard from './pages/Dashboard';
import Profile from './pages/Profile';
import ApiKeys from './pages/ApiKeys';
import PaymentOrders from './pages/PaymentOrders';
import PaymentOrderDetail from './pages/PaymentOrderDetail';
import TransactionDetail from './pages/TransactionDetail';
import Transactions from './pages/Transactions';
import Balance from './pages/Balance';
import WebhookDetail from './pages/WebhookDetail';
import Webhooks from './pages/Webhooks';

function App() {
  return (
    <>
      <Toaster position="top-right" richColors />
      <Routes>
        {/* Redirection */}
        <Route path="/" element={<Navigate to="/merchant/dashboard" replace />} />
        <Route path="/merchant/login" element={<Navigate to="/login" replace />} />

        {/* Auth Routes */}
        <Route element={<AuthLayout />}>
          <Route path="/login" element={<Login />} />
          <Route path="/merchant/change-password" element={<ChangePassword />} />
        </Route>

        {/* Protected Merchant Routes */}
        <Route element={<ProtectedRoute />}>
          <Route element={<MainLayout />}>
            <Route path="/merchant/dashboard" element={<Dashboard />} />
            <Route path="/merchant/profile" element={<Profile />} />
            <Route path="/merchant/api-keys" element={<ApiKeys />} />
            
            {/* Pages from Phase 4 and 5 */}
            <Route path="/merchant/payment-orders" element={<PaymentOrders />} />
            <Route path="/merchant/payment-orders/:id" element={<PaymentOrderDetail />} />
            <Route path="/merchant/transactions" element={<Transactions />} />`n            <Route path="/merchant/transactions/:id" element={<TransactionDetail />} />
            <Route path="/merchant/webhooks" element={<Webhooks />} />`n            <Route path="/merchant/webhooks/:id" element={<WebhookDetail />} />
            <Route path="/merchant/balance" element={<Balance />} />
          </Route>
        </Route>

        {/* 404 */}
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </>
  );
}

export default App;
