import { useQuery } from '@tanstack/react-query';
import { userService } from '../services/user.service';
import type { UserQueryParams } from '../types/user.type';

export const useUsers = (params: UserQueryParams) => {
  return useQuery({
    queryKey: ['users', params],
    queryFn: () => userService.getUsers(params),
    placeholderData: (prev) => prev,
  });
};
