import type { DaySyncState } from './sync'

/*
 * Quando o aviso da nuvem aparece (issue #178) — o mesmo de
 * `app/lib/local/cloud_notices.dart`.
 *
 * Até a E7 os avisos eram uma faixa no alto do dia, e a faixa acompanhava o
 * estado a cada tecla: com rede, cada gravação punha o dia em "Salvo neste
 * aparelho…" e, logo depois, em "Salvo na nuvem.". A faixa aparecia, sumia e
 * empurrava a tela enquanto ela digitava. Agora o aviso é um toast no canto
 * superior direito, e esta peça decide quando ele sobe:
 *
 * - **só quando a frase muda.** Digitando com rede, "Salvo na nuvem." aparece
 *   uma vez; as gravações seguintes, que terminam na mesma frase, ficam
 *   caladas. Caiu a rede, a frase muda e o aviso sobe; voltou, sobe de novo.
 * - **"Salvo neste aparelho…" espera `pendingDelay`.** É o estado de passagem
 *   de toda gravação com rede, e anunciar que a internet caiu quando ela não
 *   caiu seria mentir. Se ele durar, é porque o envio não aconteceu, e aí a
 *   frase é verdade.
 */
export class CloudNotices {
  private readonly show: (text: string) => void
  private readonly pendingDelay: number
  private shown: string | null = null
  private current: string | null = null
  private timer: ReturnType<typeof setTimeout> | null = null

  constructor(show: (text: string) => void, pendingDelay = 3000) {
    this.show = show
    this.pendingDelay = pendingDelay
  }

  /**
   * O estado do dia, a cada mudança da fila. Dia que ela ainda não tocou nesta
   * sessão vem nulo e não tem o que dizer.
   */
  update(state: DaySyncState | null): void {
    if (!state) return

    const text = noticeText(state)
    // O estado deste dia não mudou: nada muda — senão a espera do "Salvo
    // neste aparelho…" recomeçaria à toa.
    if (text === this.current) return
    this.current = text

    this.cancel()
    if (text === this.shown) return

    if (state.status === 'pending') {
      this.timer = setTimeout(() => this.announce(text), this.pendingDelay)
    } else {
      this.announce(text)
    }
  }

  dispose(): void {
    this.cancel()
  }

  private announce(text: string): void {
    this.timer = null
    this.shown = text
    this.show(text)
  }

  private cancel(): void {
    if (this.timer !== null) clearTimeout(this.timer)
    this.timer = null
  }
}

/**
 * A frase do aviso: a do estado e, quando o banco recusou com explicação
 * própria, a explicação dele depois.
 */
export function noticeText(state: DaySyncState): string {
  return state.detail ? `${state.message} ${state.detail}` : state.message
}
