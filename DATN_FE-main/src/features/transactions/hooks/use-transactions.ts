import { useQuery } from '@tanstack/react-query';
import { transactionService } from '../services/transaction.service';
import type { TransactionQueryParams } from '../types/transaction.type';

export const useTransactions = (params: TransactionQueryParams) => {
  return useQuery({
    queryKey: ['transactions', params],
    queryFn: () => transactionService.getTransactions(params),
    placeholderData: (prev) => prev,
  });
};
