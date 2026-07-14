import { useMutation, useQueryClient } from '@tanstack/react-query';
import { walletService } from '../services/wallet.service';

export const useLockWallet = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ walletId, reason }: { walletId: string, reason: string }) => 
      walletService.lockWallet(walletId, reason),
    onSuccess: (_, variables) => {
      // Invalidate wallets list to refresh data
      queryClient.invalidateQueries({ queryKey: ['wallets'] });
      // Invalidate specific wallet summary if it's currently open
      queryClient.invalidateQueries({ queryKey: ['wallet-summary', variables.walletId] });
    },
  });
};

export const useUnlockWallet = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (walletId: string) => walletService.unlockWallet(walletId),
    onSuccess: (_, walletId) => {
      queryClient.invalidateQueries({ queryKey: ['wallets'] });
      queryClient.invalidateQueries({ queryKey: ['wallet-summary', walletId] });
    },
  });
};
