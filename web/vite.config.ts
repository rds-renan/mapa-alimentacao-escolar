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
        codeSplitting: {
          groups: [{ name: 'vendor', test: /node_modules[\\/]/ }],
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
