import { useQuery } from '@tanstack/react-query';
import { merchantService } from '../services/merchant.service';
import type { MerchantQueryParams } from '../types/merchant.type';

export const useMerchants = (params: MerchantQueryParams) => {
  return useQuery({
    queryKey: ['merchants', params],
    queryFn: () => merchantService.getMerchants(params),
    placeholderData: (prev) => prev,
  });
};
