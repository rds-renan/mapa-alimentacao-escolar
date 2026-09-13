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

Precisa de Node 22 ou mais novo. O banco local é o mesmo de
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
| `npm run typecheck` | só a checagem de tipos |
| `npm run types:db` | regera os tipos do banco a partir das migrations |
| `npm run types:db:check` | falha se os tipos versionados estiverem defasados |

## O que tem dentro

```
web/
├── public/logo.png             # o logo do MAE, também como ícone da aba
├── scripts/
│   └── gerar-tipos-do-banco.mjs
├── src/
│   ├── components/ui/          # componentes do shadcn/ui, já ajustados ao dedo
│   ├── lib/
│   │   ├── database.types.ts   # gerado — não editar
│   │   ├── supabase.ts         # o cliente, por variáveis de ambiente
│   │   └── utils.ts
│   ├── App.tsx                 # conferência dos tokens (temporária)
│   ├── env.d.ts                # as variáveis de ambiente que a web lê
│   ├── index.css               # o tema: todos os tokens moram aqui
│   └── main.tsx
├── .env.example
├── components.json             # configuração do shadcn/ui
└── eslint.config.js
```

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
o arquivo não, ele falha. É esse par que a CI vai usar
([decisão 8](decisoes-tecnicas.md)) para que a interface nunca acredite numa
coluna que o banco não tem mais.

O arquivo é gerado, e por isso fica fora do ESLint e do Prettier: arquivo
gerado não se corrige à mão, se regera.

## As chaves

O cliente em [`src/lib/supabase.ts`](../../web/src/lib/supabase.ts) lê a URL do
projeto e a chave anônima de variáveis de ambiente, e falha alto se faltarem.
Só variáveis com o prefixo `VITE_` chegam ao navegador — e é justamente por isso
que nada sensível usa esse prefixo. A chave de serviço, que ignora as políticas
de acesso, não existe na web: ela vive apenas no ambiente das Edge Functions.

O modelo está em [`web/.env.example`](../../web/.env.example); o `.env` é
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
