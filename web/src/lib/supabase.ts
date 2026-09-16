import { createClient } from '@supabase/supabase-js'

import type { Database } from './database.types'
// Importado antes de o cliente existir de propósito: este módulo lê o endereço
// da aba no carregamento, e o cliente limpa esse endereço ao nascer.
import './recovery-link'

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

/*
 * Onde a sessão fica guardada no aparelho. O nome é nosso de propósito: o
 * padrão da biblioteca deriva o nome do endereço do projeto, e um dia em que
 * o projeto mude de endereço a sessão de todo mundo sumiria em silêncio.
 */
export const AUTH_STORAGE_KEY = 'mae.auth'

export const supabase = createClient<Database>(url, publishableKey, {
  auth: {
    // A sessão persiste entre aberturas do navegador e o token se renova
    // sozinho: é o RNF#2 da US016 — ela não redigita senha no dia a dia.
    persistSession: true,
    autoRefreshToken: true,

    // O link de redefinição de senha chega pelo e-mail com o token no próprio
    // endereço; é isto que o transforma em sessão ao abrir a tela da senha
    // nova. Sem isto, o link não faria nada.
    detectSessionInUrl: true,

    // Fluxo implícito, que é o padrão da biblioteca, e não PKCE: o PKCE exige
    // que o link do e-mail seja aberto no mesmo navegador que o pediu, e aqui
    // o caminho comum é pedir no navegador e abrir o e-mail no aplicativo do
    // celular — que abre outro navegador. O PKCE falharia justamente no
    // caminho mais provável.
    flowType: 'implicit',

    storageKey: AUTH_STORAGE_KEY,
  },
})
