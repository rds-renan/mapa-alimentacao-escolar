import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'

import App from './App'

/*
 * Teste de fumaça da fundação (issue #57): garante que a aplicação monta e
 * que a variante escura dos tokens é alcançável. Vale enquanto a página de
 * conferência existir — quando a autenticação entrar (issue #59) e ela sair,
 * este arquivo sai junto, e o lugar dos testes passa a ser a fila de envio,
 * a convergência e as regras de estado do mapa (decisão 11 da E5).
 */
describe('App', () => {
  it('monta a página de conferência dos tokens', () => {
    render(<App />)

    expect(screen.getByText('Fundação da web')).toBeInTheDocument()
  })

  it('alterna entre o tema claro e o escuro', () => {
    const { container } = render(<App />)
    const raiz = container.firstElementChild

    expect(raiz).not.toHaveClass('dark')

    fireEvent.click(screen.getByRole('button', { name: 'Ver no escuro' }))
    expect(raiz).toHaveClass('dark')

    fireEvent.click(screen.getByRole('button', { name: 'Ver no claro' }))
    expect(raiz).not.toHaveClass('dark')
  })
})
