import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const useAuthStore = create(
  persist(
    (set, get) => ({
      token: null,
      user: null,
      
      setAuth: (token, user) => set({ token, user }),
      
      logout: () => {
        set({ token: null, user: null });
      },

      isMerchant: () => {
        const { user } = get();
        if (!user) return false;
        
        const hasMerchantRole = user.roles && user.roles.some(r => r === 'MERCHANT_OWNER' || r === 'MERCHANT_STAFF');
        return user.user_type === 'MERCHANT_USER' || hasMerchantRole;
      },

      isForceChangePassword: () => {
        const { user } = get();
        return user?.is_force_change_password === true;
      }
    }),
    {
      name: 'auth-storage',
    }
  )
);

export default useAuthStore;
