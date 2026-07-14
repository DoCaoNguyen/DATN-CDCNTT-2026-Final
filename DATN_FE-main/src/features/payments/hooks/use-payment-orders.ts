import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { paymentOrderService, qrPaymentService } from '../services/payment-order.service';

export const usePaymentOrders = (params: any) => {
  return useQuery({
    queryKey: ['admin-payment-orders', params],
    queryFn: () => paymentOrderService.getPaymentOrders(params),
  });
};

export const usePaymentOrderDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-payment-order-detail', id],
    queryFn: () => paymentOrderService.getPaymentOrderDetail(id),
    enabled: !!id,
  });
};

export const usePaymentTimeline = (id: string) => {
  return useQuery({
    queryKey: ['admin-payment-timeline', id],
    queryFn: () => paymentOrderService.getPaymentTimeline(id),
    enabled: !!id,
  });
};

export const usePaymentLedger = (id: string) => {
  return useQuery({
    queryKey: ['admin-payment-ledger', id],
    queryFn: () => paymentOrderService.getPaymentLedger(id),
    enabled: !!id,
  });
};

export const usePaymentCallbacks = (id: string) => {
  return useQuery({
    queryKey: ['admin-payment-callbacks', id],
    queryFn: () => paymentOrderService.getPaymentCallbacks(id),
    enabled: !!id,
  });
};

// --- QR Payments ---
export const useQrPayments = (params: any) => {
  return useQuery({
    queryKey: ['admin-qr-payments', params],
    queryFn: () => qrPaymentService.getQrPayments(params),
  });
};

export const useQrPaymentDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-qr-payment-detail', id],
    queryFn: () => qrPaymentService.getQrPaymentDetail(id),
    enabled: !!id,
  });
};

export const useExpireQrJob = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: qrPaymentService.expireQrJob,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-qr-payments'] });
    },
  });
};
