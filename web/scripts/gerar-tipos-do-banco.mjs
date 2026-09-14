// Gera os tipos TypeScript das tabelas a partir das migrations (decisão 8 da
// E5): tipo escrito à mão envelhece em silêncio até o dia em que mente.
//
//   npm run types:db      regera o arquivo
//   npm run types:db:check falha se o arquivo versionado estiver defasado
//
// Precisa do banco local de pé (`supabase start` na raiz do repositório).
import { execFileSync } from 'node:child_process'
import { readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import process from 'node:process'

const raizDoProjeto = path.resolve(import.meta.dirname, '..')
const raizDoRepositorio = path.resolve(raizDoProjeto, '..')
const destino = path.join(raizDoProjeto, 'src/lib/database.types.ts')

const cabecalho = `// Arquivo gerado por \`npm run types:db\` a partir das migrations em
// supabase/migrations/. Não editar à mão: mudou o schema, regera.
`

function gerar() {
  const saida = execFileSync(
    'supabase',
    ['gen', 'types', 'typescript', '--local', '--schema', 'public'],
    { cwd: raizDoRepositorio, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 }
  )
  return cabecalho + saida
}

const conferir = process.argv.includes('--check')
const gerado = gerar()

if (!conferir) {
  writeFileSync(destino, gerado)
  console.log(`Tipos gerados em ${path.relative(raizDoRepositorio, destino)}`)
  process.exit(0)
}

const versionado = readFileSync(destino, 'utf8')
if (versionado === gerado) {
  console.log('Os tipos versionados estão iguais aos do schema.')
  process.exit(0)
}

console.error(
  'Os tipos versionados estão defasados em relação às migrations.\n' +
    'Rode `npm run types:db` e versione o resultado.'
)
process.exit(1)
