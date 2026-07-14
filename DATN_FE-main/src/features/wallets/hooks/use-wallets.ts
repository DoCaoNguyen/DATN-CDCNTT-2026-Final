import { useQuery } from '@tanstack/react-query';
import { walletService } from '../services/wallet.service';
import type { WalletQueryParams } from '../types/wallet.type';

export const useWallets = (params: WalletQueryParams) => {
  return useQuery({
    queryKey: ['wallets', params],
    queryFn: () => walletService.getWallets(params),
    placeholderData: (prev) => prev,
  });
};

export const useWalletSummary = (walletId: string | null) => {
  return useQuery({
    queryKey: ['wallet-summary', walletId],
    queryFn: () => walletService.getWalletSummary(walletId as string),
    enabled: !!walletId,
  });
};

export const useWalletLedger = (walletId: string | null, page = 1) => {
  return useQuery({
    queryKey: ['wallet-ledger', walletId, page],
    queryFn: () => walletService.getWalletLedger(walletId as string, page),
    enabled: !!walletId,
  });
};
