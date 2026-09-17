import { createContext } from 'react'

import type { DayPayload } from './day'
import type { SyncState } from './sync'

/*
 * A camada local vista de dentro da interface. É a fronteira da decisão 4 da
 * E5: o que vem do servidor é assunto da TanStack Query, e o que ainda não subiu
 * é assunto daqui. As duas coisas não se misturam — a tela do dia lê o rascunho
 * quando ele existe e o servidor quando não existe.
 */
export interface SyncContextValue {
  state: SyncState
  /** Grava o dia no aparelho e agenda o envio. Não existe botão "salvar". */
  save(day: DayPayload): Promise<void>
  /** O rascunho do dia, ou nulo quando ele já está confirmado no servidor. */
  load(mapDate: string): Promise<DayPayload | null>
  /** Quantos dias estão guardados agora, perguntando ao disco. */
  pendingCount(): Promise<number>
  /** Tenta enviar tudo agora, sem esperar a rede avisar que voltou. */
  flush(): Promise<void>
  /** A usuária viu o aviso de conflito. */
  dismissConflict(mapDate: string): void
}

export const SyncContext = createContext<SyncContextValue | null>(null)
