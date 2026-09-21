import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useSyncExternalStore,
} from 'react'
import { useQueryClient } from '@tanstack/react-query'

import { useAuth } from '@/auth/useAuth'
import { FOOD_ITEMS_QUERY_KEY } from '@/food-items/queries'

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
 *
 * É aqui também que a confirmação da fila avisa o cache do servidor, e é aqui
 * porque a fila é daqui. O aviso já existiu dentro das telas, e o teste de
 * ponta a ponta mostrou o buraco: a fila confirma o dia enquanto a tela aberta
 * é a **do dia**, então o aviso da visão do mês não estava montado para
 * ouvi-lo — e ela voltava mostrando como vazio o dia que a merendeira acabou
 * de registrar, até os trinta segundos de `staleTime` vencerem. Quem avisa tem
 * de viver onde o fato acontece.
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

  useSettledInvalidation(state.pending)

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

  const pendingDays = useCallback(
    async (prefix: string) => (engine ? engine.pendingDays(prefix) : []),
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
    () => ({
      state,
      save,
      load,
      pendingCount,
      pendingDays,
      flush,
      dismissConflict,
    }),
    [state, save, load, pendingCount, pendingDays, flush, dismissConflict]
  )

  return <SyncContext value={value}>{children}</SyncContext>
}

/**
 * A fila confirmou alguma coisa: o que o servidor tem agora é diferente do que
 * o cache leu.
 *
 * A conta é a fila encolhendo — um dia a menos guardado no aparelho é um dia a
 * mais gravado lá. Vão junto os três que `save_meal_map` mexe na mesma
 * operação: o mês, o dia e o catálogo, porque o gênero cadastrado no meio do
 * registro só nasce quando o dia sobe.
 *
 * Invalida todos os meses e todos os dias, e não só o que está aberto: a fila
 * pode ter subido um dia de outro mês enquanto ela olhava este.
 */
function useSettledInvalidation(pending: number) {
  const queryClient = useQueryClient()
  const settled = useRef(pending)

  useEffect(() => {
    if (pending < settled.current) {
      void queryClient.invalidateQueries({ queryKey: ['month'] })
      void queryClient.invalidateQueries({ queryKey: ['day'] })
      void queryClient.invalidateQueries({ queryKey: FOOD_ITEMS_QUERY_KEY })
    }
    settled.current = pending
  }, [pending, queryClient])
}
