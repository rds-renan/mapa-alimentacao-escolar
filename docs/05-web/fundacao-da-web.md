# A fundação da web

O projeto em [`web/`](../../web/): Vite com React e TypeScript, os tokens da E3
no tema e o cliente do Supabase. É a montagem que a
[decisão 1](decisoes-tecnicas.md) descreveu, e o chão de onde saem todas as
telas da etapa.

A ordem importa. Os tokens entram **antes** da primeira tela porque o alvo de
toque de 44 px e os tamanhos de controle elevados são o que separa este
aplicativo de uma interface de desktop — se as telas nascessem sobre o padrão
da biblioteca, cada uma delas teria de ser corrigida depois, uma a uma.

## Como rodar

Precisa do Node na versão de [`.node-version`](../../web/.node-version) — a
mesma que a CI e o build da Cloudflare usam. O banco local é o mesmo de
[`supabase/`](../../supabase/README.md).

```bash
supabase start              # na raiz do repositório: sobe o banco
cd web
cp .env.example .env        # e preencha com o que o supabase start imprimiu
npm install
npm run dev
```

| Comando | O que faz |
|---|---|
| `npm run dev` | servidor de desenvolvimento |
| `npm run build` | checagem de tipos e pacote de produção em `dist/` |
| `npm run lint` | ESLint |
| `npm run format` | Prettier, escrevendo |
| `npm run format:check` | Prettier, só conferindo |
| `npm test` | os testes, uma vez |
| `npm run test:watch` | os testes, acompanhando as mudanças |
| `npm run typecheck` | só a checagem de tipos |
| `npm run types:db` | regera os tipos do banco a partir das migrations |
| `npm run types:db:check` | falha se os tipos versionados estiverem defasados |
| `npm run check:secrets` | confere que nenhum segredo entrou no `dist/` |

## O que tem dentro

```
web/
├── public/
│   ├── logo.png                # o logo do MAE, também como ícone da aba
│   ├── robots.txt              # fora dos buscadores, de propósito
│   └── _headers                # cabeçalhos das respostas, lidos pela Cloudflare
├── scripts/
│   ├── gerar-tipos-do-banco.mjs
│   └── conferir-segredos-do-pacote.mjs
├── src/
│   ├── auth/                   # sessão, perfil e guardas de rota (issue #59)
│   ├── components/             # os componentes do MAE
│   │   └── ui/                 # componentes do shadcn/ui, já ajustados ao dedo
│   ├── day/                    # o registro do dia (issue #62)
│   ├── lib/
│   │   ├── database.types.ts   # gerado — não editar
│   │   ├── local-data.ts       # o que sair do aplicativo apaga
│   │   ├── supabase.ts         # o cliente, por variáveis de ambiente
│   │   └── utils.ts
│   ├── local/                  # rascunho, fila de envio e convergência (issue #60)
│   ├── month/                  # a visão do mês e o estado de cada dia (issue #61)
│   ├── pages/                  # uma tela por arquivo, com o nome do desenho
│   ├── test/                   # preparação comum e o Supabase de mentira
│   ├── App.tsx                 # o mapa de rotas
│   ├── env.d.ts                # as variáveis de ambiente que a web lê
│   ├── index.css               # o tema: todos os tokens moram aqui
│   ├── main.tsx
│   └── routes.ts               # os caminhos, num lugar só
├── .env.example
├── .node-version               # a versão do Node, para a CI e o Cloudflare
├── components.json             # configuração do shadcn/ui
├── eslint.config.js
├── vite.config.ts              # build e configuração do Vitest
└── wrangler.jsonc              # o que é publicado, e como as rotas se comportam
```

Os arquivos em `src/` são kebab-case, com uma exceção declarada: as telas em
`src/pages/` levam o nome do componente, que é o nome da tela no desenho da E3.
A primeira coisa que entrou nesta estrutura foi a autenticação — a página de
conferência dos tokens, que ocupava o `App.tsx` da fundação, saiu junto com ela,
como estava previsto. O que cada peça faz está na
[autenticação, sessão e rotas por perfil](autenticacao-e-sessao.md) e, para o
que se guarda no aparelho, na
[camada local](camada-local.md).

## Os tokens

Todos em [`src/index.css`](../../web/src/index.css), num lugar só, vindos da
[decisão 6 da E3](../03-ux/decisoes-de-design.md). Quem muda a aparência do
produto mexe ali e em mais lugar nenhum.

| Grupo | O que ficou |
|---|---|
| Acento | `#397ba1`, o azul do logo; `#2c5f7e` no toque e `#eaf2f8` como fundo suave |
| Neutros | escala zinc — fundo `#fafafa`, cartão branco, texto `#09090b`, apoio `#71717a`, borda `#e4e4e7` |
| Semânticos | confirmação `#15803d`, atenção `#a16207`, erro `#dc2626`, cada um com fundo e borda próprios |
| Dados (US017) | aceitação `#2a78d6` → `#f0efec` → `#e34948`, e o azul de dados sozinho no ranking |
| Tipografia | Geist; 11, 12, 13, **14 (corpo)**, 16, 17, 22 e 30 px |
| Espaçamento | grade de 4 px, como as telas foram desenhadas |
| Raios | 6, 8, **10** e 12 px — o cartão é 12, o botão e o campo são 8 |
| Alvo de toque | 44 px, no token `touch` (`h-touch`, `size-touch`, `min-h-touch`) |

A **variante escura** (US024) é o mesmo conjunto de tokens com outra paleta,
já no tema: o azul do logo clareia para `#7fb3d0`, porque `#397ba1` sobre fundo
escuro não alcança o contraste AA, e passa a levar texto escuro em cima. O que
ainda não existe é a preferência — gravar a escolha e seguir a do aparelho é a
issue do tema escuro. Aqui a variante entrou para que nenhuma tela nasça sem
ela e precise ser revisitada depois.

## Os controles são maiores que o padrão da biblioteca

O shadcn/ui entrega botão de 32 px e campo de 32 px: tamanhos de mouse. No MAE
o tamanho normal é o alvo de toque — botão e campo de 44 px, ícone de 44 px,
texto de 16 px dentro do campo. Os tamanhos menores continuam existindo, mas
com um papel declarado: são para a área de administração, que é de desktop
(decisão 1 da E3). No fluxo da merendeira, nada que se toca desce do normal.

O texto de 16 px no campo não é estética: abaixo disso o navegador do aparelho
dá zoom ao focar a entrada, e a tela salta debaixo do dedo. No desktop ele volta
para o corpo de 14 px.

Isso tem um preço conhecido: componente novo copiado do shadcn/ui vem com os
tamanhos da biblioteca e precisa ser ajustado ao entrar. É o custo de a
biblioteca entregar o componente como arquivo do projeto — e é também o que
torna o ajuste possível.

## Os tipos do banco

`npm run types:db` roda `supabase gen types typescript` contra o banco local e
escreve [`src/lib/database.types.ts`](../../web/src/lib/database.types.ts), que
fica versionado. `npm run types:db:check` regera e compara: se o schema mudou e
o arquivo não, ele falha. É esse par que a CI usa
([decisão 8](decisoes-tecnicas.md)) para que a interface nunca acredite numa
coluna que o banco não tem mais — o fluxo está descrito na
[integração contínua e publicação](integracao-continua-e-publicacao.md).

O arquivo é gerado, e por isso fica fora do ESLint e do Prettier: arquivo
gerado não se corrige à mão, se regera.

## Os testes

Vitest com jsdom e a Testing Library, como a
[decisão 11](decisoes-tecnicas.md) previu, configurados dentro do próprio
[`vite.config.ts`](../../web/vite.config.ts) — mesma resolução de caminhos,
mesmo `@/`, nenhuma segunda configuração para manter em dia.

Os testes **não** usam as funções globais do Vitest: cada arquivo importa
`describe`, `it` e `expect`. O preço é uma linha de importação; o ganho é que
não existe nome mágico no ar e o editor mostra de onde cada coisa vem. Como não
há globais, a limpeza entre casos é declarada à mão em
[`src/test/setup.ts`](../../web/src/test/setup.ts), junto dos comparadores do
jest-dom.

O entorno entrou na fundação porque a CI precisa de um passo de testes que possa
**reprovar de verdade** — e para que as issues seguintes escrevam teste em vez
de montar entorno. O teste de fumaça que ocupava esse lugar saiu com a página
provisória; hoje o peso está onde a [decisão 11](decisoes-tecnicas.md) previu
que estaria, na autenticação e na fila de envio.

O IndexedDB é a única coisa que precisou de biblioteca só para o teste: o jsdom
não o implementa, e `fake-indexeddb` entra como dependência de desenvolvimento
para que a [camada local](camada-local.md) seja exercitada contra um banco de
verdade, com transações de verdade — que é onde estava o defeito que os testes
dela encontraram.

## As chaves

O cliente em [`src/lib/supabase.ts`](../../web/src/lib/supabase.ts) lê a URL do
projeto e a chave publicável de variáveis de ambiente, e falha alto se
faltarem. Só variáveis com o prefixo `VITE_` chegam ao navegador — e é
justamente por isso que nada sensível usa esse prefixo. A chave secreta, que
ignora as políticas de acesso, não existe na web: ela vive apenas no ambiente
das Edge Functions.

**Qual par de chaves a web usa**, que a issue da gravação do dia deixou em
aberto: o formato novo, `sb_publishable_…`, na variável
`VITE_SUPABASE_PUBLISHABLE_KEY`. É o que a CLI imprime hoje e o que o painel
oferece, e não é JWT — não expira nem carrega papel dentro de si; quem decide o
que ela alcança continua sendo a RLS. O par antigo (`anon` e `service_role`)
ocupa exatamente o mesmo lugar e continua funcionando, então adotar o novo não
custa nada e evita trocar isto depois.

O [`.env.example`](../../.env.example) da raiz acompanha: passou a falar em
`SUPABASE_PUBLISHABLE_KEY` e `SUPABASE_SECRET_KEY`, para que o projeto inteiro
chame as chaves pelo mesmo nome. Dentro de uma edge function nenhum dos dois
precisa ser configurado — o runtime injeta `SUPABASE_PUBLISHABLE_KEYS` e
`SUPABASE_SECRET_KEYS`, no plural porque são dicionários JSON e a chave em uso é
a `default`, ao lado dos nomes antigos, que continuam existindo. Vale lembrar
disso na issue da geração do documento, para não procurar ali uma variável que
já está no ambiente.

O modelo da web está em [`web/.env.example`](../../web/.env.example); o `.env` é
bloqueado pelo `.gitignore`.

## Duas escolhas pequenas, registradas para não virarem dúvida

**ESLint, e não o oxlint.** O modelo atual do Vite já vem com oxlint no lugar do
ESLint. A [decisão 1](decisoes-tecnicas.md) diz ESLint e Prettier, e foi o que
ficou: o ecossistema de regras do React e do TypeScript é mais completo ali, e a
etapa não tem volume de código que justifique otimizar tempo de lint.

**A página que abre hoje é provisória.** `App.tsx` mostra a paleta, a escala
tipográfica e os controles nos dois temas — serve para conferir que os tokens
fecham, com olho humano, antes de existir tela de verdade. Ela sai quando a
autenticação entrar.
