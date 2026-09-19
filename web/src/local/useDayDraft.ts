import { useCallback, useEffect, useRef, useState } from 'react'

import type { DayPayload } from './day'
import type { DaySyncState } from './sync'
import { useSync } from './useSync'

/*
 * O dia em edição, do ponto de vista da tela do registro (issue #62).
 *
 * `draft` é o que está guardado no aparelho e ainda não foi confirmado. Nulo
 * quer dizer que não há rascunho — e aí quem tem o dia é o servidor, que é a
 * fronteira da decisão 4 da E5. `update` é o autosave: escreve no aparelho na
 * hora e deixa o envio por conta da fila.
 */
export function useDayDraft(mapDate: string): {
  draft: DayPayload | null
  loading: boolean
  status: DaySyncState | null
  update(day: DayPayload): Promise<void>
  reload(): void
} {
  const { state, save, load } = useSync()
  const [draft, setDraft] = useState<DayPayload | null>(null)
  const [loading, setLoading] = useState(true)
  /** Sobe quando alguém pede a releitura do disco — a convergência, hoje. */
  const [reloads, setReloads] = useState(0)
  /*
   * Quantas vezes ela já digitou. A leitura do disco leva alguns quadros, e uma
   * tecla dada nesse meio-tempo é mais nova que qualquer coisa que a leitura
   * vá trazer — deixar a resposta atrasada cair por cima apagaria da tela o que
   * ela acabou de escrever.
   */
  const edits = useRef(0)

  useEffect(() => {
    let active = true
    const editsBefore = edits.current

    void (async () => {
      setLoading(true)
      const stored = await load(mapDate)
      if (!active || edits.current !== editsBefore) return
      setDraft(stored)
      setLoading(false)
    })()

    return () => {
      active = false
    }
  }, [mapDate, load, reloads])

  /*
   * Relê o disco. Quem chama é a convergência: perdido o conflito, o rascunho
   * some do aparelho e o que vale passa a ser o dia do servidor — e a tela
   * ainda está com o texto dela na mão. O contador de edições volta a zero de
   * propósito: é o único caso em que a leitura atrasada **deve** ganhar do que
   * está na tela.
   */
  const reload = useCallback(() => {
    edits.current = 0
    setReloads((count) => count + 1)
  }, [])

  const update = useCallback(
    async (day: DayPayload) => {
      edits.current += 1
      // A tela vê a mudança antes de o disco confirmar: esperar o IndexedDB
      // para desenhar a tecla seria o travamento que a decisão 3 evita.
      setDraft(day)
      setLoading(false)
      await save(day)
    },
    [save]
  )

  return {
    draft,
    loading,
    status: state.days[mapDate] ?? null,
    update,
    reload,
  }
}
