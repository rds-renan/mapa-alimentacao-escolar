import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'

import { SYNC_MESSAGES } from './messages'
import { SyncBanner } from './sync-banner'

/*
 * A faixa de salvamento existe porque não há botão "Salvar". O texto exato faz
 * parte da decisão — é o da tabela da decisão 3 da E3 —, e por isso ele é
 * comparado aqui palavra por palavra, e não por pedaço.
 */
describe('a faixa de salvamento', () => {
  it('diz que está salvo no aparelho e sobe sozinho', () => {
    render(
      <SyncBanner
        status={{
          status: 'pending',
          message: SYNC_MESSAGES.pending,
          detail: null,
        }}
      />
    )

    expect(screen.getByRole('status')).toHaveTextContent(
      'Salvo no aparelho. Envia sozinho quando houver internet.'
    )
  })

  it('diz que foi enviado e já dá para gerar o documento', () => {
    render(
      <SyncBanner
        status={{ status: 'sent', message: SYNC_MESSAGES.sent, detail: null }}
      />
    )

    expect(screen.getByRole('status')).toHaveTextContent(
      'Enviado. Este mapa já está disponível para gerar o documento.'
    )
  })

  it('diz, antes de tudo, que nada foi perdido', () => {
    render(
      <SyncBanner
        status={{
          status: 'failed',
          message: SYNC_MESSAGES.failed,
          detail: null,
        }}
      />
    )

    expect(screen.getByRole('status')).toHaveTextContent(
      'Ainda não deu para enviar. Nada foi perdido, vamos tentar de novo.'
    )
  })

  it('acrescenta a frase do servidor quando a recusa tem explicação própria', () => {
    render(
      <SyncBanner
        status={{
          status: 'failed',
          message: SYNC_MESSAGES.failed,
          detail:
            'Este mapa já está em um documento gerado e não pode ser alterado.',
        }}
      />
    )

    expect(screen.getByRole('status')).toHaveTextContent(
      'Este mapa já está em um documento gerado e não pode ser alterado.'
    )
  })

  it('não diz nada sobre o dia que ela ainda não tocou', () => {
    render(<SyncBanner status={null} />)

    expect(screen.queryByRole('status')).toBeNull()
  })
})
