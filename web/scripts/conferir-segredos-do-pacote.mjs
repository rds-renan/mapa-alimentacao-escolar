// Confere que nada sensível entrou no pacote que vai para o ar (CA#6 da issue
// #59, decisão 10 da E5). Ao navegador chegam apenas a URL do projeto e a
// chave publicável, que é pública por construção e só tem o poder que as
// políticas de RLS lhe derem; a chave secreta vive somente no ambiente das
// Edge Functions.
//
//   npm run check:secrets     roda sobre o `dist/` que o build produziu
//
// Isto não substitui cuidado: é a rede embaixo dele. Um `import.meta.env`
// distraído com o nome errado seria descoberto aqui, e não em produção.
import { readdirSync, readFileSync, statSync } from 'node:fs'
import path from 'node:path'
import process from 'node:process'

const pacote = path.resolve(import.meta.dirname, '../dist')

// Marcas do que nunca pode chegar ao navegador. São expressões, e não trechos
// soltos, porque o próprio `supabase-js` carrega o texto `sb_secret_` dentro de
// si para conferir o formato da chave que recebe — o que se procura aqui é uma
// chave de verdade, com valor depois do prefixo.
const proibidos = [
  { marca: /sb_secret_[A-Za-z0-9_-]{8,}/, oQueE: 'chave secreta do Supabase' },
  { marca: /SERVICE_ROLE/, oQueE: 'chave de serviço do Supabase' },
  { marca: /service_role/, oQueE: 'chave de serviço do Supabase' },
  { marca: /BEGIN [A-Z ]*PRIVATE KEY/, oQueE: 'chave privada' },
]

// Chave no formato antigo é um JWT: o papel vai escrito dentro dele.
const JWT = /eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}/g

function arquivos(diretorio) {
  return readdirSync(diretorio).flatMap((nome) => {
    const caminho = path.join(diretorio, nome)
    return statSync(caminho).isDirectory() ? arquivos(caminho) : [caminho]
  })
}

function papelDoToken(token) {
  try {
    const corpo = token.split('.')[1]
    return JSON.parse(Buffer.from(corpo, 'base64url').toString('utf8')).role
  } catch {
    return null
  }
}

function conferir() {
  let achados = 0
  let conferidos = 0

  for (const caminho of arquivos(pacote)) {
    // Fonte é o que se lê: fonte, estilo, página e mapa. Imagem e fonte
    // tipográfica não carregam chave.
    if (!/\.(js|mjs|css|html|json|map|txt)$/.test(caminho)) continue

    const conteudo = readFileSync(caminho, 'utf8')
    conferidos += 1
    const relativo = path.relative(pacote, caminho)

    for (const { marca, oQueE } of proibidos) {
      if (marca.test(conteudo)) {
        console.error(`✗ ${relativo}: ${oQueE} (${marca})`)
        achados += 1
      }
    }

    for (const token of conteudo.match(JWT) ?? []) {
      if (papelDoToken(token) === 'service_role') {
        console.error(`✗ ${relativo}: chave de serviço do Supabase (JWT)`)
        achados += 1
      }
    }
  }

  if (achados > 0) {
    console.error(
      '\nO pacote não pode ir ao ar assim. Ao navegador vão apenas ' +
        'VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY.'
    )
    process.exit(1)
  }

  console.log(`✓ ${conferidos} arquivos do pacote, nenhum segredo dentro.`)
}

try {
  statSync(pacote)
} catch {
  console.error('Não há `dist/` para conferir. Rode `npm run build` antes.')
  process.exit(1)
}

conferir()
