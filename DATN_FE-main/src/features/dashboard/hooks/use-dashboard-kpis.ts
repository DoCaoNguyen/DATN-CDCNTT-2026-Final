import { useQuery } from '@tanstack/react-query';
import { dashboardService } from '../services/dashboard.service';

export const useDashboardKpis = () => {
  return useQuery({
    queryKey: ['dashboardKpis'],
    queryFn: dashboardService.getKpis,
    // Refetch every 5 seconds as requested
    refetchInterval: 5000,
    // Keep previous data while refetching to avoid flickering
    placeholderData: (prev) => prev,
  });
};
