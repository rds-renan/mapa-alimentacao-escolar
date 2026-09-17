/*
 * Preparação comum dos testes de componente (decisão 11 da E5). Os testes não
 * usam as funções globais do Vitest — cada arquivo importa o que usa —, e é
 * por isso que a limpeza entre casos é declarada aqui à mão: sem globais, a
 * Testing Library não tem onde se pendurar sozinha.
 */
/*
 * O jsdom não implementa IndexedDB, e a fila de envio vive acima das rotas —
 * então qualquer tela montada num teste passa por ela. Entra aqui, e não em
 * cada arquivo, para que nenhum teste de tela precise saber que a fila existe.
 */
import 'fake-indexeddb/auto'

import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { IDBFactory } from 'fake-indexeddb'
import { afterEach, beforeEach } from 'vitest'

import { closeLocalDatabase } from '@/local/store'

// Aparelho novo a cada caso: nenhum teste herda o que o anterior guardou.
beforeEach(() => {
  globalThis.indexedDB = new IDBFactory()
  void closeLocalDatabase()
})

afterEach(() => {
  cleanup()
})
