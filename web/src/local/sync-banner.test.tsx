import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'

import { REJECTED_MESSAGE, SYNC_MESSAGES } from './messages'
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
      'Salvo neste aparelho. A gente atualiza na nuvem quando a internet voltar.'
    )
  })

  it('diz só que está salvo na nuvem, sem prometer o documento', () => {
    render(
      <SyncBanner
        status={{ status: 'sent', message: SYNC_MESSAGES.sent, detail: null }}
      />
    )

    expect(screen.getByRole('status')).toHaveTextContent('Salvo na nuvem.')
  })

  it('diz que espera a internet e que nada se perdeu', () => {
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
      'Aguardando internet para salvar na nuvem. Seus dados estão seguros no aparelho.'
    )
  })

  it('acrescenta a frase do servidor quando a recusa tem explicação própria', () => {
    render(
      <SyncBanner
        status={{
          status: 'failed',
          message: REJECTED_MESSAGE,
          detail:
            'Este mapa já está em um documento gerado e não pode ser alterado.',
        }}
      />
    )

    expect(screen.getByRole('status')).toHaveTextContent(
      'Ainda não foi para a nuvem. Seus dados estão seguros no aparelho.'
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
