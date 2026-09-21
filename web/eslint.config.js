import js from '@eslint/js'
import prettier from 'eslint-config-prettier/flat'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  // Saída do build e o arquivo de tipos gerado pelo Supabase (decisão 8 da E5):
  // arquivo gerado não se corrige à mão, se regera.
  {
    ignores: [
      'dist',
      'src/lib/database.types.ts',
      // Saída do Playwright: relatório, rastros e vídeos de uma rodada.
      'playwright-report',
      'test-results',
    ],
  },
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat['recommended-latest'],
      reactRefresh.configs.vite,
      prettier,
    ],
    languageOptions: {
      ecmaVersion: 2023,
      globals: globals.browser,
    },
  },
  {
    // O teste de ponta a ponta e a configuração dele rodam em Node, e não no
    // navegador: quem escreve ali fala com `process`, `Buffer` e o sistema de
    // arquivos, que não existem do outro lado.
    files: ['e2e/**/*.ts', 'playwright.config.ts'],
    languageOptions: { globals: globals.node },
  },
  {
    // Os componentes do shadcn/ui exportam as variantes junto do componente:
    // é o formato em que a biblioteca entrega o arquivo, e reescrever cada um
    // custaria mais do que o recarregamento rápido em desenvolvimento rende.
    files: ['src/components/ui/**/*.tsx'],
    rules: { 'react-refresh/only-export-components': 'off' },
  }
)
