import { useCallback, useEffect, useMemo, useSyncExternalStore } from 'react'

import { useAuth } from '@/auth/useAuth'

import type { DayPayload } from './day'
import { createSyncEngine, EMPTY_SYNC_STATE, type SyncState } from './sync'
import { SyncContext, type SyncContextValue } from './sync-context'

/*
 * A fila viva, ligada à sessão.
 *
 * Ela fica acima das rotas de propósito: o envio não é assunto da tela do dia,
 * é assunto do aplicativo. A merendeira preenche o dia, volta para a visão do
 * mês e fecha o navegador — o que estava por enviar sobe assim que houver
 * internet, esteja ela em que tela estiver (CA#1 da US011).
 *
 * O motor nasce por usuária. As duas merendeiras se revezam no mesmo aparelho,
 * e o rascunho de uma não pode aparecer para a outra: trocando quem está
 * logada, troca o motor, e o anterior para.
 */

const noopSubscribe = () => () => {}
const emptyState = () => EMPTY_SYNC_STATE

export function SyncProvider({ children }: { children: React.ReactNode }) {
  const { profile } = useAuth()
  const userId = profile?.id ?? null

  const engine = useMemo(
    () => (userId ? createSyncEngine(userId) : null),
    [userId]
  )

  useEffect(() => {
    if (!engine) return
    engine.start()
    return () => engine.stop()
  }, [engine])

  const state: SyncState = useSyncExternalStore(
    engine ? engine.subscribe : noopSubscribe,
    engine ? engine.getState : emptyState
  )

  const save = useCallback(
    async (day: DayPayload) => {
      // Sem sessão não há onde gravar: o dia é de alguém. Na prática não
      // acontece — as telas que gravam estão todas atrás da guarda de sessão.
      if (!engine) return
      await engine.save(day)
    },
    [engine]
  )

  const load = useCallback(
    async (mapDate: string) => (engine ? engine.load(mapDate) : null),
    [engine]
  )

  const pendingCount = useCallback(
    async () => (engine ? engine.pendingCount() : 0),
    [engine]
  )

  const flush = useCallback(async () => {
    if (engine) await engine.flush()
  }, [engine])

  const dismissConflict = useCallback(
    (mapDate: string) => engine?.dismissConflict(mapDate),
    [engine]
  )

  const value = useMemo<SyncContextValue>(
    () => ({ state, save, load, pendingCount, flush, dismissConflict }),
    [state, save, load, pendingCount, flush, dismissConflict]
  )

  return <SyncContext value={value}>{children}</SyncContext>
}
