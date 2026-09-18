// Põe um teto no peso do que o navegador baixa para abrir a aplicação
// (issue #84). O que se mede é a carga inicial em gzip: o módulo de entrada
// declarado no `index.html` mais tudo o que o próprio HTML manda pré-carregar
// — hoje o nosso pedaço, o de terceiros e o runtime do bundler.
//
//   npm run check:size        roda sobre o `dist/` que o build produziu
//
// Por que a carga inicial, e não o maior arquivo: depois da separação da
// issue #84 o pacote tem mais de um pedaço, e o que custa a quem abre a tela
// é a soma do que vem antes da primeira pintura. Um pedaço carregado sob
// demanda — uma rota que só o painel usa — não entra na conta, e é assim que
// se quer: dividir por rota é a saída quando este número apertar. A folha de
// estilo fica de fora: o que se vigia aqui é o JavaScript, que é onde uma
// dependência nova aparece de repente.
//
// O teto não é uma meta de rapidez. É um lembrete que não depende de ninguém
// lembrar: a biblioteca de gráficos do painel (issue #70) é da ordem de
// 100 kB gzip e estoura isto no primeiro commit, que é exatamente o momento
// de decidir se ela entra sob demanda. Quando a decisão for tomada e o número
// mudar de propósito, o teto se ajusta aqui, num commit visível.
import { readFileSync, statSync } from 'node:fs'
import path from 'node:path'
import process from 'node:process'
import { gzipSync } from 'node:zlib'

const pacote = path.resolve(import.meta.dirname, '../dist')

const TETO_KB = 205

// O HTML é a fonte da verdade sobre o que o navegador busca sozinho: o
// `<script type="module">` da entrada e cada `modulepreload` que o Vite
// escreve ao lado dele.
const ENTRADA = /<script[^>]+type="module"[^>]+src="([^"]+)"/g
const PRECARGA = /<link[^>]+rel="modulepreload"[^>]+href="([^"]+)"/g

function caminhosDaCargaInicial(html) {
  const urls = [
    ...[...html.matchAll(ENTRADA)].map((achado) => achado[1]),
    ...[...html.matchAll(PRECARGA)].map((achado) => achado[1]),
  ]
  return urls.map((url) => path.join(pacote, url.replace(/^\//, '')))
}

// Gzip é a régua, não a promessa: o que a Cloudflare entrega é brotli, e o
// mesmo pedaço chega ainda menor. O número daqui também não bate na casa
// decimal com o que o `vite build` imprime, porque as duas implementações de
// gzip divergem em cerca de 1%. Nada disso importa desde que a medida seja
// sempre a mesma — e é, porque é sempre esta linha.
function gzipEmKB(caminho) {
  return gzipSync(readFileSync(caminho)).length / 1000
}

function conferir() {
  const html = readFileSync(path.join(pacote, 'index.html'), 'utf8')
  const caminhos = caminhosDaCargaInicial(html)

  if (caminhos.length === 0) {
    console.error(
      'Nenhum script encontrado no `index.html`. O build mudou de forma?'
    )
    process.exit(1)
  }

  const pedacos = caminhos
    .map((caminho) => ({
      nome: path.relative(pacote, caminho),
      kb: gzipEmKB(caminho),
    }))
    .sort((a, b) => b.kb - a.kb)

  const total = pedacos.reduce((soma, pedaco) => soma + pedaco.kb, 0)

  for (const { nome, kb } of pedacos) {
    console.log(`  ${kb.toFixed(1).padStart(6)} kB  ${nome}`)
  }

  const resumo = `${total.toFixed(1)} kB gzip de carga inicial, teto de ${TETO_KB} kB`

  if (total > TETO_KB) {
    console.error(`\n✗ ${resumo} — ${(total - TETO_KB).toFixed(1)} kB acima.`)
    console.error(
      '\nNão é para subir o teto por reflexo. Antes disso: o que acabou de\n' +
        'entrar precisa estar na carga inicial, ou é uma tela que dá para\n' +
        'carregar sob demanda com `lazy()` na rota? Se precisa mesmo, o teto\n' +
        'sobe aqui, em scripts/conferir-peso-do-pacote.mjs, com o porquê no PR.'
    )
    process.exit(1)
  }

  console.log(`\n✓ ${resumo} (${(TETO_KB - total).toFixed(1)} kB de folga).`)
}

try {
  statSync(path.join(pacote, 'index.html'))
} catch {
  console.error('Não há `dist/` para conferir. Rode `npm run build` antes.')
  process.exit(1)
}

conferir()
