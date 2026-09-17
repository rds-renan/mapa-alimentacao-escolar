import { useContext } from 'react'

import { SyncContext } from './sync-context'

export function useSync() {
  const value = useContext(SyncContext)

  if (!value) {
    throw new Error('useSync precisa estar dentro de <SyncProvider>.')
  }

  return value
}
