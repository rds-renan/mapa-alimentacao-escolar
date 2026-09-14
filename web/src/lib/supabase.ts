import { createClient } from '@supabase/supabase-js'

import type { Database } from './database.types'

/*
 * Cliente único do Supabase. Só entram aqui a URL do projeto e a chave
 * publicável, que é pública por construção: o que cada perfil pode ler e
 * escrever é decidido pelas políticas de RLS no banco (decisão 10 da E5).
 * A chave secreta não existe no navegador — ela vive apenas no ambiente das
 * Edge Functions.
 */
const url = import.meta.env.VITE_SUPABASE_URL
const publishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!url || !publishableKey) {
  throw new Error(
    'Configuração ausente: defina VITE_SUPABASE_URL e ' +
      'VITE_SUPABASE_PUBLISHABLE_KEY em web/.env. O modelo está em ' +
      'web/.env.example.'
  )
}

export const supabase = createClient<Database>(url, publishableKey)
