/*
 * Preparação comum dos testes de componente (decisão 11 da E5). Os testes não
 * usam as funções globais do Vitest — cada arquivo importa o que usa —, e é
 * por isso que a limpeza entre casos é declarada aqui à mão: sem globais, a
 * Testing Library não tem onde se pendurar sozinha.
 */
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

afterEach(() => {
  cleanup()
})
