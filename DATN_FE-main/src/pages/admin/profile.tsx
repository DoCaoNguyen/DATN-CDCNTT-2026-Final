import { useEffect, useState } from 'react';
import { User, Mail, Phone, ShieldCheck, KeyRound } from 'lucide-react';
import { formatDateTime, formatDisplayPhone } from '../../utils/formatters';

export default function ProfilePage() {
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    try {
      const userInfoStr = localStorage.getItem('user_info');
      if (userInfoStr) {
        setUser(JSON.parse(userInfoStr));
      }
    } catch (e) {
      console.error('Lỗi parse user_info', e);
    }
  }, []);

  if (!user) {
    return <div className="p-8 text-center text-slate-500">Đang tải thông tin...</div>;
  }

  return (
    <div className="space-y-6 w-full">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Thông tin cá nhân</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý thông tin hồ sơ và bảo mật tài khoản của bạn</p>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden w-full">
        <div className="h-40 bg-gradient-to-r from-blue-500 to-indigo-600 relative w-full"></div>
        <div className="px-4 sm:px-8 pb-8">
          <div className="relative -mt-16 mb-8">
            <div className="flex flex-col gap-4">
              <div className="w-32 h-32 bg-white rounded-full p-1.5 shadow-md shrink-0">
                <div className="w-full h-full bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-5xl font-bold uppercase">
                  {user?.full_name?.charAt(0) || user?.username?.charAt(0) || 'A'}
                </div>
              </div>
              <div>
                <h2 className="text-3xl font-bold text-slate-800">{user?.full_name || user?.username || 'Admin User'}</h2>
                <div className="flex items-center gap-2 mt-2 bg-emerald-50 text-emerald-600 px-3 py-1 rounded-full w-max border border-emerald-100">
                  <ShieldCheck className="w-4 h-4" />
                  <span className="text-sm font-semibold">{user?.roles?.[0] || 'Superadmin'}</span>
                </div>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-10">
            <div className="space-y-6 bg-slate-50 p-6 rounded-xl border border-slate-100 hover:shadow-md transition-shadow">
              <h3 className="text-sm font-bold text-slate-800 uppercase tracking-wider mb-4 border-b border-slate-200 pb-2">Thông tin cơ bản</h3>
              <div className="space-y-5">
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 shrink-0">
                    <User className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="text-sm font-medium text-slate-500">Tên đăng nhập</div>
                    <div className="text-base font-semibold text-slate-800 mt-0.5">{user?.username || 'Chưa cập nhật'}</div>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 shrink-0">
                    <User className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="text-sm font-medium text-slate-500">Họ và tên</div>
                    <div className="text-base font-semibold text-slate-800 mt-0.5">{user?.full_name || 'Chưa cập nhật'}</div>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-6 bg-slate-50 p-6 rounded-xl border border-slate-100 hover:shadow-md transition-shadow">
              <h3 className="text-sm font-bold text-slate-800 uppercase tracking-wider mb-4 border-b border-slate-200 pb-2">Liên hệ & Định danh</h3>
              <div className="space-y-5">
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600 shrink-0">
                    <Mail className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="text-sm font-medium text-slate-500">Email</div>
                    <div className="text-base font-semibold text-slate-800 mt-0.5">{user?.email || 'Chưa cập nhật'}</div>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600 shrink-0">
                    <Phone className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="text-sm font-medium text-slate-500">Số điện thoại</div>
                    <div className="text-base font-semibold text-slate-800 mt-0.5">{formatDisplayPhone(user?.phone)}</div>
                  </div>
                </div>

                <div className="flex items-start gap-4">


                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
