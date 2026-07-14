import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { webhookService } from '../services/webhook.service';

export const useWebhooks = (params: any) => {
  return useQuery({
    queryKey: ['admin-webhooks', params],
    queryFn: () => webhookService.getWebhooks(params),
  });
};

export const useWebhookDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-webhook-detail', id],
    queryFn: () => webhookService.getWebhookDetail(id),
    enabled: !!id,
  });
};

export const useRetryWebhook = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: webhookService.retryWebhook,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-webhooks'] });
      queryClient.invalidateQueries({ queryKey: ['admin-webhook-detail'] });
    },
  });
};
