import { useQuery } from '@tanstack/react-query';
import { ledgerService } from '../services/ledger.service';

export const useLedgerTransactions = (params: any) => {
  return useQuery({
    queryKey: ['admin-ledger-transactions', params],
    queryFn: () => ledgerService.getLedgerTransactions(params),
  });
};

export const useLedgerTransactionDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-ledger-transaction-detail', id],
    queryFn: () => ledgerService.getLedgerTransactionDetail(id),
    enabled: !!id,
  });
};
