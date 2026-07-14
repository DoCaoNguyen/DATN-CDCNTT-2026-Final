
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

import AdminLogin from '../pages/auth/login';
import ChangePassword from '../pages/auth/change-password';
import AdminLayout from '../layouts/admin-layout';
import DashboardPage from '../pages/admin/dashboard';
import UserManagementPage from '../pages/admin/user-manage';
import UserCreatePage from '../pages/admin/user-create';
import UserDetailPage from '../pages/admin/user-detail';
import StaffManagePage from '../pages/admin/staff-manage';
import StaffCreatePage from '../pages/admin/staff-create';
import StaffDetailPage from '../pages/admin/staff-detail';
import MerchantManagementPage from '../pages/admin/merchant-manage';
import MerchantDetailPage from '../pages/admin/merchant-detail';
import LogManagementPage from '../pages/admin/log-manage';
import TransactionManagementPage from '../pages/admin/transaction-manage';
import WalletManagementPage from '../pages/admin/wallet-manage';
import WalletDetail from '../pages/admin/wallet-detail';
import PaymentOrderManage from '../pages/admin/payment-order-manage';
import PaymentOrderDetail from '../pages/admin/payment-order-detail';
import RefundManage from '../pages/admin/refund-manage';
import QrPaymentManage from '../pages/admin/qr-payment-manage';
import QrPaymentDetail from '../pages/admin/qr-payment-detail';
import WebhookManage from '../pages/admin/webhook-manage';
import LedgerManage from '../pages/admin/ledger-manage';
import LedgerDetail from '../pages/admin/ledger-detail';
import ReportManage from '../pages/admin/report-manage';
import KycManage from '../pages/admin/kyc-manage';
import RoleManage from '../pages/admin/role-manage';
import ProfilePage from '../pages/admin/profile';
import SettingsManage from '../pages/admin/settings-manage';

const PlaceholderPage = ({ title }: { title: string }) => (
  <div className="flex flex-col items-center justify-center h-[60vh]">
    <h2 className="text-2xl font-bold text-slate-800">{title}</h2>
    <p className="text-slate-500 mt-2">Tính năng đang được phát triển...</p>
  </div>
);

export default function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<AdminLogin />} />
        <Route path="/change-password" element={<ChangePassword />} />

        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="profile" element={<ProfilePage />} />

          {/* Người dùng ví */}
          <Route path="users" element={<UserManagementPage />} />
          <Route path="users/create" element={<UserCreatePage />} />
          <Route path="users/:id" element={<UserDetailPage />} />

          {/* Nhân viên — tách riêng */}
          <Route path="staffs" element={<StaffManagePage />} />
          <Route path="staffs/create" element={<StaffCreatePage />} />
          <Route path="staffs/:id" element={<StaffDetailPage />} />

          <Route path="merchants" element={<MerchantManagementPage />} />
          <Route path="merchants/:id" element={<MerchantDetailPage />} />
          <Route path="logs" element={<LogManagementPage />} />
          <Route path="transactions" element={<TransactionManagementPage />} />
          <Route path="wallets" element={<WalletManagementPage />} />
          <Route path="wallets/:id" element={<WalletDetail />} />
          <Route path="reports" element={<ReportManage />} />
          <Route path="kyc" element={<KycManage />} />
          <Route path="roles" element={<RoleManage />} />

          <Route path="topups" element={<PlaceholderPage title="Nạp tiền" />} />
          <Route path="transfers" element={<PlaceholderPage title="Chuyển tiền" />} />
          <Route path="settings" element={<SettingsManage />} />

          <Route path="payments">
            <Route path="payment-orders" element={<PaymentOrderManage />} />
            <Route path="payment-orders/:id" element={<PaymentOrderDetail />} />
            <Route path="refunds" element={<RefundManage />} />
            <Route path="qr" element={<QrPaymentManage />} />
            <Route path="qr/:id" element={<QrPaymentDetail />} />
          </Route>

          <Route path="webhooks" element={<WebhookManage />} />
          <Route path="ledger" element={<LedgerManage />} />
          <Route path="ledger/:id" element={<LedgerDetail />} />
        </Route>

        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  );
}