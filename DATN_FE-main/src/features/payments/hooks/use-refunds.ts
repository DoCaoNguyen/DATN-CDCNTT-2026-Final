import { useQuery } from '@tanstack/react-query';
import { refundService } from '../services/refund.service';

export const useRefunds = (params: any) => {
  return useQuery({
    queryKey: ['admin-refunds', params],
    queryFn: () => refundService.getRefunds(params),
  });
};

export const useRefundDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-refund-detail', id],
    queryFn: () => refundService.getRefundDetail(id),
    enabled: !!id,
  });
};
