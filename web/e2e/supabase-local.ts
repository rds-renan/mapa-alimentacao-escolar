import { execFileSync } from 'node:child_process'
import path from 'node:path'
import process from 'node:process'

/*
 * De onde o teste de ponta a ponta tira o endereço e as chaves do Supabase.
 *
 * O teste corre contra o Supabase **local** — o mesmo que `supabase start`
 * sobe e que a CI levanta no runner —, nunca contra o projeto na nuvem. Os
 * valores saem de `supabase status`, que é a única fonte que não envelhece: as
 * chaves locais são impressas pela CLI e são iguais em qualquer máquina, então
 * não são segredo (é o que o `.env.example` já diz), mas elas mudaram de
 * formato uma vez e escrevê-las aqui à mão seria assinar a próxima vez.
 *
 * As variáveis de ambiente têm precedência para o caso de alguém apontar o
 * teste para outro Supabase de teste — e é só para isso: apontá-lo para um
 * ambiente com dado real seria gravar mapa de mentira num lugar de verdade.
 */

export interface SupabaseLocal {
  url: string
  /** A chave publicável: é ela que vai ao navegador. */
  publishableKey: string
  /**
   * A chave secreta, que ignora as políticas de acesso. Fica **fora** do
   * navegador: quem a usa é a preparação, em Node, para pôr o modelo no balde
   * e limpar o rastro da rodada anterior. Nada disto é papel da merendeira, e
   * por isso nada disto passa pela tela.
   */
  secretKey: string
}

const repositorio = path.resolve(import.meta.dirname, '../..')

interface StatusDaCli {
  API_URL?: string
  PUBLISHABLE_KEY?: string
  ANON_KEY?: string
  SECRET_KEY?: string
  SERVICE_ROLE_KEY?: string
}

function perguntarACli(): StatusDaCli {
  try {
    const saida = execFileSync('supabase', ['status', '-o', 'json'], {
      cwd: repositorio,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    })

    // A CLI imprime uma linha de serviços parados antes do JSON quando algum
    // contêiner foi excluído do `supabase start`, que é o caso na CI.
    const inicio = saida.indexOf('{')
    return inicio === -1 ? {} : (JSON.parse(saida.slice(inicio)) as StatusDaCli)
  } catch {
    return {}
  }
}

let lido: SupabaseLocal | null = null

export function supabaseLocal(): SupabaseLocal {
  if (lido) return lido

  const status = perguntarACli()

  const url = process.env.SUPABASE_URL ?? status.API_URL
  const publishableKey =
    process.env.SUPABASE_PUBLISHABLE_KEY ??
    status.PUBLISHABLE_KEY ??
    status.ANON_KEY
  const secretKey =
    process.env.SUPABASE_SECRET_KEY ??
    status.SECRET_KEY ??
    status.SERVICE_ROLE_KEY

  if (!url || !publishableKey || !secretKey) {
    throw new Error(
      'O Supabase local não respondeu. Suba-o antes do teste de ponta a ponta:\n' +
        '  supabase start && supabase db reset\n' +
        'Para apontar o teste a outro Supabase de teste, defina SUPABASE_URL, ' +
        'SUPABASE_PUBLISHABLE_KEY e SUPABASE_SECRET_KEY.'
    )
  }

  lido = { url, publishableKey, secretKey }
  return lido
}
