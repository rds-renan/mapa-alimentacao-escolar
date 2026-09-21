import path from 'node:path'

import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(import.meta.dirname, './src'),
    },
  },
  build: {
    rolldownOptions: {
      output: {
        // Duas peças em vez de uma: de um lado as dependências, do outro o
        // nosso código (issue #84). O nome de cada arquivo carrega o hash do
        // seu conteúdo, então um merge que só mexe nas telas troca o hash do
        // nosso pedaço — cerca de 7% do peso — e deixa o resto onde está, no
        // cache do navegador, com o `immutable` que o #82 configurou. Sem esta
        // separação, todo deploy rebaixava React e Supabase de novo, sem que
        // uma linha deles tivesse mudado.
        //
        // `tags: ['$initial']` é o que faz a decisão 14 valer também para as
        // dependências, e ele entrou na issue #70. Sem a etiqueta, o grupo
        // varre **todo** o `node_modules` para um pedaço só, que é carga
        // inicial — e aí a biblioteca que só a direção usa chega no celular da
        // merendeira mesmo que ela nunca abra `/admin`. O `lazy()` das rotas
        // dela não protegia disso: ele separava o nosso código e a dependência
        // continuava vindo junto. Foi assim que o menu suspenso do painel
        // custou 17 kB gzip na carga inicial e estourou o teto.
        //
        // Com a etiqueta, o grupo captura só o que está no grafo estático da
        // entrada; o que é alcançável apenas por uma rota carregada sob demanda
        // cai no pedaço dela. Não mexer nela sem medir com `npm run check:size`
        // — ela é a diferença entre 203,8 kB e 221,0 kB de carga inicial.
        codeSplitting: {
          groups: [
            {
              name: 'vendor',
              test: /node_modules[\\/]/,
              tags: ['$initial'],
            },
          ],
        },
      },
    },
    // O aviso de pacote grande do Vite dispara acima de um número fixo de
    // 500 kB crus, e o chunk de terceiros vive acima dele por natureza — React
    // e Supabase sozinhos passam disso. Quem vigia o peso aqui é
    // `npm run check:size`, que mede o que o navegador de fato baixa, em gzip,
    // e reprova na CI. Dois alarmes para a mesma coisa, um deles sempre aceso,
    // é o mesmo que nenhum.
    chunkSizeWarningLimit: Infinity,
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
})
