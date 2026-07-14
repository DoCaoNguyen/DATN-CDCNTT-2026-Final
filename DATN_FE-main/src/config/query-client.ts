import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false, // Không tự động gọi lại API khi switch tab
      retry: 1,                    // Chỉ retry 1 lần nếu API fail
      staleTime: 1000 * 60 * 5,    // Dữ liệu coi là fresh trong 5 phút
    },
  },
});
