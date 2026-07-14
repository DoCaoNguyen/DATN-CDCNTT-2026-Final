import { useQuery } from '@tanstack/react-query';
import { transactionService } from '../services/transaction.service';

export const useTransactionDetail = (transactionId: string | null) => {
  return useQuery({
    queryKey: ['transaction-entries', transactionId],
    queryFn: () => transactionService.getTransactionEntries(transactionId as string),
    enabled: !!transactionId,
  });
};
