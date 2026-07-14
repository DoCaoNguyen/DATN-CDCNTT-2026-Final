
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  CreditCard,
  Key,
  ArrowLeftRight,
  Webhook,
  Wallet,
  LogOut,
  User
} from 'lucide-react';
import useAuthStore from '../store/useAuthStore';
import clsx from 'clsx';
import styles from './MainLayout.module.css';

const navigation = [
  { name: 'Tổng quan', href: '/merchant/dashboard', icon: LayoutDashboard },
  { name: 'Số dư', href: '/merchant/balance', icon: Wallet },
  { name: 'Đơn hàng', href: '/merchant/payment-orders', icon: CreditCard },
  { name: 'Giao dịch', href: '/merchant/transactions', icon: ArrowLeftRight },
  { name: 'API Keys', href: '/merchant/api-keys', icon: Key },
  { name: 'Webhooks', href: '/merchant/webhooks', icon: Webhook },
];

const MainLayout = () => {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className={styles.layout}>
      {/* Sidebar */}
      <aside className={styles.sidebar}>
        <div className={styles.logoContainer}>
          <div className={styles.logoIcon}>M</div>
          <span className={styles.logoText}>Merchant Portal</span>
        </div>

        <nav className={styles.nav}>
          <div className={styles.navGroup}>Chung</div>
          {navigation.map((item) => (
            <NavLink
              key={item.name}
              to={item.href}
              className={({ isActive }) =>
                clsx(styles.navItem, { [styles.active]: isActive })
              }
            >
              <item.icon className={styles.navIcon} />
              {item.name}
            </NavLink>
          ))}
        </nav>
      </aside>

      {/* Main Content Area */}
      <div className={styles.main}>
        {/* Header */}
        <header className={styles.header}>
          <div className={styles.headerLeft}>
            {/* Can put breadcrumbs or search here */}
          </div>
          <div className={styles.headerRight}>
            <div className={styles.userInfo} onClick={() => navigate('/merchant/profile')}>
              <div className={styles.avatar}>
                <User size={18} />
              </div>
              <div className={styles.userDetails}>
                <span className={styles.userName}>{user?.full_name || 'Merchant User'}</span>
                <span className={styles.userRole}>{user?.email || ''}</span>
              </div>
            </div>
            <button className={styles.logoutBtn} onClick={handleLogout} title="Đăng xuất">
              <LogOut size={18} />
            </button>
          </div>
        </header>

        {/* Page Content */}
        <Outlet />
      </div>
    </div>
  );
};

export default MainLayout;
