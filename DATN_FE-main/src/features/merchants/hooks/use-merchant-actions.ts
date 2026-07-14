import { useMutation, useQueryClient } from '@tanstack/react-query';
import { merchantService } from '../services/merchant.service';
import type { CreateMerchantFormValues, ConfigWebhookFormValues } from '../schemas/merchant.schema';

export const useCreateMerchant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateMerchantFormValues) => merchantService.createMerchant(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] });
    },
  });
};

export const useGenerateApiKey = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (merchantId: string) => merchantService.generateApiKey(merchantId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] });
    },
  });
};

export const useConfigWebhook = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ merchantId, data }: { merchantId: string, data: ConfigWebhookFormValues }) => 
      merchantService.configWebhook(merchantId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] });
    },
  });
};

export const useApproveMerchant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (merchantId: string) => merchantService.approveMerchant(merchantId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] });
    },
  });
};

export const useRejectMerchant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ merchantId, reason }: { merchantId: string, reason: string }) => 
      merchantService.rejectMerchant(merchantId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] });
    },
  });
};

export const useSuspendMerchant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ merchantId, reason }: { merchantId: string, reason: string }) => 
      merchantService.suspendMerchant(merchantId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] });
    },
  });
};

export const useActivateMerchant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (merchantId: string) => merchantService.activateMerchant(merchantId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] });
    },
  });
};
