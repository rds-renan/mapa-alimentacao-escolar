import process from 'node:process'

import { defineConfig, devices } from '@playwright/test'

import { supabaseLocal } from './e2e/supabase-local'

/*
 * O teste de ponta a ponta do caminho crítico (decisão 11 da E5, issue #72).
 *
 * É **um só**, de propósito: ele existe para provar que o caminho inteiro
 * fecha — entrar, registrar um dia, sincronizar, selecionar mapas, gerar o
 * documento e chegar ao arquivo —, e vira evidência direta no laudo de
 * qualidade da E7. O que quebra em silêncio neste produto é a fila, e fila é
 * assunto dos testes de unidade, que são baratos e específicos; multiplicar
 * casos aqui custaria minutos de CI para cobrir de novo o que já está coberto
 * mais perto do defeito.
 *
 * Ele corre contra a aplicação **construída**, e não contra o servidor de
 * desenvolvimento: o que interessa provar é o que vai ao ar. E contra o
 * Supabase local, com o seed fictício — ver `e2e/supabase-local.ts`.
 */

const ENDERECO = 'http://localhost:5173'

const { url, publishableKey } = supabaseLocal()

export default defineConfig({
  testDir: './e2e',
  // Um teste só: paralelismo não tem o que dividir, e serial deixa a saída
  // legível quando ele falha.
  workers: 1,
  fullyParallel: false,

  /*
   * Nada de repetir na CI. Retentativa serve para amansar teste instável, e
   * aqui ela esconderia justamente o que este teste existe para mostrar: se o
   * caminho fechou ou não. Instabilidade aqui é defeito a investigar.
   */
  retries: 0,

  // Na CI, `test.only` esquecido num commit deixaria de rodar o resto sem que
  // ninguém percebesse.
  forbidOnly: !!process.env.CI,

  // O caminho inteiro passa por uma Edge Function que preenche um .docx.
  timeout: 90_000,
  expect: { timeout: 15_000 },

  reporter: process.env.CI
    ? [['list'], ['html', { open: 'never' }]]
    : [['list']],

  use: {
    baseURL: ENDERECO,
    // O rastro do que falhou: cada passo, com a tela e a rede de cada um. É o
    // que responde "em que passo o caminho quebrou" sem precisar reproduzir.
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      /*
       * Um celular, e não um desktop: é assim que a merendeira usa o produto,
       * e a tela estreita é a que esconde botão atrás de rolagem. Chromium
       * basta — o que se prova aqui é que o caminho fecha, não a compatibilidade
       * entre navegadores.
       */
      use: { ...devices['Pixel 7'] },
    },
  ],

  globalSetup: './e2e/preparacao.ts',

  webServer: {
    // `preview` e não `dev`: serve o `dist/`, que é o que a Cloudflare publica.
    command: 'npm run build && npm run preview -- --port 5173 --strictPort',
    url: ENDERECO,
    // Na máquina de quem desenvolve, um servidor já aberto é reaproveitado.
    reuseExistingServer: !process.env.CI,
    timeout: 180_000,
    stdout: 'pipe',
    stderr: 'pipe',
    env: {
      // O que o Vite lê no build. Só a chave publicável chega ao navegador —
      // a secreta fica na preparação, fora da tela.
      VITE_SUPABASE_URL: url,
      VITE_SUPABASE_PUBLISHABLE_KEY: publishableKey,
    },
  },
})
