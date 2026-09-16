/// <reference types="vite/client" />

// Só o que a web lê do ambiente. O prefixo VITE_ é o que faz a variável
// chegar ao navegador — e é por isso que nada sensível pode usá-lo.
interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_PUBLISHABLE_KEY: string
  /*
   * A chave pública do desafio contra robôs. Opcional: sem ela, o desafio
   * simplesmente não aparece — é o que permite rodar o desenvolvimento e os
   * testes sem depender de serviço externo.
   */
  readonly VITE_TURNSTILE_SITE_KEY?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
