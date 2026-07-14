import { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

interface QueryParams {
  page: number;
  limit: number;
  search: string;
  status: string;
  type: string;
  fromDate: string;
  toDate: string;
  sortBy: string;
  sortOrder: 'asc' | 'desc' | '';
}

export function useApiQueryParams() {
  const [searchParams, setSearchParams] = useSearchParams();

  const getParams = useCallback((): QueryParams => {
    return {
      page: Number(searchParams.get('page')) || 1,
      limit: Number(searchParams.get('limit')) || 10,
      search: searchParams.get('search') || '',
      status: searchParams.get('status') || '',
      type: searchParams.get('type') || '',
      fromDate: searchParams.get('fromDate') || '',
      toDate: searchParams.get('toDate') || '',
      sortBy: searchParams.get('sortBy') || '',
      sortOrder: (searchParams.get('sortOrder') as 'asc' | 'desc') || '',
    };
  }, [searchParams]);

  const [params, setParamsState] = useState<QueryParams>(getParams());
  const [debouncedSearch, setDebouncedSearch] = useState(params.search);

  // Debounce search
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(params.search);
    }, 300);
    return () => clearTimeout(handler);
  }, [params.search]);

  // Sync back to URL when params change
  useEffect(() => {
    const newSearchParams = new URLSearchParams();

    const setIfPresent = (key: string, value: string | number) => {
      if (value !== undefined && value !== null && value !== '') {
        newSearchParams.set(key, String(value));
      }
    };

    setIfPresent('page', params.page);
    setIfPresent('limit', params.limit);
    setIfPresent('search', debouncedSearch);
    setIfPresent('status', params.status);
    setIfPresent('type', params.type);
    setIfPresent('fromDate', params.fromDate);
    setIfPresent('toDate', params.toDate);
    setIfPresent('sortBy', params.sortBy);
    setIfPresent('sortOrder', params.sortOrder);

    if (newSearchParams.toString() !== searchParams.toString()) {
      setSearchParams(newSearchParams, { replace: true });
    }
  }, [params.page, params.limit, debouncedSearch, params.status, params.type, params.fromDate, params.toDate, params.sortBy, params.sortOrder, searchParams, setSearchParams]);

  // When URL changes from outside
  useEffect(() => {
    setParamsState((prev) => {
      const next = getParams();
      if (JSON.stringify(prev) !== JSON.stringify(next)) {
        return next;
      }
      return prev;
    });
  }, [searchParams, getParams]);

  const setQueryParams = useCallback((newParams: Partial<QueryParams>) => {
    setParamsState((prev) => {
      const updated = { ...prev, ...newParams };
      const isFilterChanged = Object.keys(newParams).some(
        (key) => key !== 'page' && key !== 'limit' && (newParams as any)[key] !== (prev as any)[key]
      );
      if (isFilterChanged) {
        updated.page = 1;
      }
      return updated;
    });
  }, []);

  return {
    params: {
      ...params,
      search: debouncedSearch
    },
    setQueryParams,
  };
}
