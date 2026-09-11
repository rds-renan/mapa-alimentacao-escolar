# CLAUDE.md — Convenções do projeto

Sistema **MAE (Mapa da Alimentação Escolar)**: app para merendeiras de uma escola de turno integral registrarem o mapa de merenda, gerando o documento oficial ao final. Também é o Projeto Integrado Transdisciplinar (PIT) de Sistemas de Informação — Cruzeiro do Sul Virtual.

## Idioma

Tudo em **português brasileiro**: documentação, commits, issues, PRs e comentários de código.

**Exceção — identificadores de código são em inglês.** Tabelas, colunas, tipos do banco, variáveis, funções e componentes seguem o inglês, no singular, porque convivem com uma stack que é inglês por construção. O que fica em português é o conteúdo: textos de interface, dados cadastrados e comentários. A fronteira e o glossário domínio → banco estão na [decisão 13 da E4](docs/04-banco-de-dados/decisoes-de-modelagem.md).

## Regra de sigilo (CRÍTICA)

- **Nunca** versionar documentos oficiais da prefeitura, templates com brasão/símbolo, mapas reais preenchidos, dados pessoais ou credenciais. O `.gitignore` bloqueia `*.docx` e afins de propósito — não contornar com `git add -f` sem decisão explícita do autor.
- A pasta `_privado/` é local e **jamais** entra no repositório. Se existir, ler `_privado/contexto.md` no início da sessão — é o contexto completo de trabalho.
- Pessoas entrevistadas são anonimizadas na documentação pública ("Merendeira 1", "Merendeira 2").
- Antes de qualquer commit/PR, revisar se o diff vaza algo sensível.



## Etapas

O projeto avança em etapas sequenciais, cada uma com milestone e issues próprias:

E0 fundação ✅ → E1 Design Thinking ✅ → E2 requisitos/backlog ✅ → E3 UX ✅ → E4 modelagem de dados ✅ → **E5 web MVP (atual)** → E6 Flutter → E7 testes/laudo → E8 entrega.

**Trabalhar apenas na etapa atual** — não antecipar entregáveis de etapas futuras, mesmo que pareça eficiente.

## Fluxo Git/GitHub

- `main` protegida: mudanças só via PR (0 aprovações exigidas, mas PR obrigatório).
- Branch curta por assunto (ex.: `docs/historias-de-usuario`, `feat/registro-diario`).
- **Squash merge** com exclusão da branch. O título do PR vira a mensagem do commit — escrever em conventional commit.
- Conventional commits: `docs:`, `feat:`, `fix:`, `chore:`, etc.
- Vincular issues com `closes #N` (encerra) ou `refs #N` (referencia).
- Issues em milestones (E0–E8), com labels existentes e board no Projects v2.



## Documentação

- Markdown em `docs/` é a **fonte da verdade**; os `.docx` da faculdade são gerados ao final como export.
- Estrutura por etapa, e o número da pasta é o número da etapa: `docs/01-design-thinking/`, `docs/02-requisitos/`, `docs/03-ux/`, `docs/04-banco-de-dados/`, `docs/05-web/`, `docs/06-app/`, `docs/07-testes/` (+ `docs/assets/` para imagens). As pastas de código acompanham as de documentação: `docs/05-web/` para o que está em `web/`, `docs/06-app/` para o que está em `app/`.
- A ordem das pastas acompanha a ordem em que o documento da faculdade é preenchido: Design Thinking → histórias e backlog → mockups → banco de dados → **codificação** → testes e laudo. A seção de codificação é uma tabela e não tem pasta própria — quem a alimenta são a E5 e a E6, e é por isso que elas ocupam os números entre banco de dados e testes.
- As telas do produto têm fonte em `design/telas/` e imagens em `docs/assets/`, geradas por `python3 design/exportar-telas.py`. O desenho é editado num canvas fora do repositório, e a sincronia vale **nos dois sentidos**: mexeu no canvas, atualizar `design/telas/` antes de exportar — senão a exportação traz de volta o desenho antigo; mexeu em `design/telas/`, republicar o canvas — senão a próxima edição feita lá sobrescreve a correção.



## Stack

Monorepo: Supabase (Postgres, Auth, Storage, Edge Functions) em `supabase/`, web React em `web/`, Android Flutter em `app/`.

A stack da web foi fechada no início da E5 e está em [decisões técnicas](docs/05-web/decisoes-tecnicas.md): Vite + React + TypeScript, Tailwind + shadcn/ui sobre os tokens da E3, React Router, TanStack Query sobre `supabase-js`, rascunho e fila de envio em IndexedDB, Cloudflare Pages com CI no GitHub Actions, Vitest + Testing Library e um E2E em Playwright. **A web garante que nada se perde; o offline integral é do aplicativo, na E6.**

O resto dos detalhes de libs continua sendo decidido quando a necessidade surge — não adicionar dependências por antecipação.