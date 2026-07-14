export type SidebarItem = {
  name: string;
  path: string;
};

export type SidebarMenu = {
  name: string;
  icon: string;
  path?: string;           // Menu đơn (flat), không có sub-items
  items?: SidebarItem[];   // Menu có thể đóng/mở
};

export type SidebarSection = {
  section: string;
  menus: SidebarMenu[];
};

export const SIDEBAR_CONFIG: SidebarSection[] = [
  {
    section: 'Chung',
    menus: [
      { name: 'Tổng quan', path: '/admin/dashboard', icon: 'LayoutDashboard' },
      {
        name: 'Người dùng',
        icon: 'Users',
        items: [
          { name: 'Người dùng ví', path: '/admin/users' },
          { name: 'Merchants', path: '/admin/merchants' },
          { name: 'Xác minh KYC', path: '/admin/kyc' },
        ]
      },
      {
        name: 'Giao dịch',
        icon: 'ArrowRightLeft',
        items: [
          { name: 'Đơn thanh toán Merchant', path: '/admin/payments/payment-orders' },
          { name: 'Hoàn tiền', path: '/admin/payments/refunds' },
          { name: 'Thanh toán QR', path: '/admin/payments/qr' },
        ]
      },
      { name: 'Quản lý Ví', path: '/admin/wallets', icon: 'Wallet' },
      { name: 'Sổ cái giao dịch', path: '/admin/ledger', icon: 'BookOpen' },
    ]
  },
  {
    section: 'Báo cáo',
    menus: [
      {
        name: 'Báo cáo',
        icon: 'BarChart3',
        items: [
          { name: 'Báo cáo nạp tiền', path: '/admin/reports?type=topups' },
          { name: 'Báo cáo chuyển tiền', path: '/admin/reports?type=transfers' },
          { name: 'Báo cáo thanh toán', path: '/admin/reports?type=payments' },
          { name: 'Báo cáo hoàn tiền', path: '/admin/reports?type=refunds' },
          { name: 'Báo cáo đối tác', path: '/admin/reports?type=merchants' },
          { name: 'Báo cáo phí MDR', path: '/admin/reports?type=fees' },
        ]
      },
    ]
  },
  {
    section: 'Cài đặt',
    menus: [
      {
        name: 'Thiết lập',
        icon: 'Settings',
        items: [
          { name: 'Webhooks', path: '/admin/webhooks' },
          { name: 'Audit Logs', path: '/admin/logs' },
          { name: 'Phân quyền', path: '/admin/roles' },
          { name: 'Nhân viên', path: '/admin/staffs' },
          { name: 'Cài đặt chung', path: '/admin/settings' },
        ]
      }
    ]
  }
];
