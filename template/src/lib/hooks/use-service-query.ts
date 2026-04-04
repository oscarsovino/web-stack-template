import { useQuery, useMutation, useQueryClient, type UseQueryOptions } from "@tanstack/react-query"

/**
 * Standard query hook for service methods.
 * Usage: const { data, isLoading } = useServiceQuery(['listings', page], () => listingService.getAll(page))
 */
export function useServiceQuery<T>(
  queryKey: unknown[],
  queryFn: () => Promise<T>,
  options?: Omit<UseQueryOptions<T>, "queryKey" | "queryFn">,
) {
  return useQuery<T>({
    queryKey,
    queryFn,
    ...options,
  })
}

/**
 * Standard mutation hook with automatic cache invalidation.
 * Usage: const mutation = useServiceMutation(() => service.update(id, data), { invalidateKeys: [['listings']] })
 */
export function useServiceMutation<TData, TVariables>(
  mutationFn: (variables: TVariables) => Promise<TData>,
  options?: {
    invalidateKeys?: unknown[][]
    onSuccess?: (data: TData) => void
    onError?: (error: Error) => void
  },
) {
  const queryClient = useQueryClient()

  return useMutation<TData, Error, TVariables>({
    mutationFn,
    onSuccess: (data) => {
      if (options?.invalidateKeys) {
        options.invalidateKeys.forEach((key) => {
          queryClient.invalidateQueries({ queryKey: key })
        })
      }
      options?.onSuccess?.(data)
    },
    onError: options?.onError,
  })
}
