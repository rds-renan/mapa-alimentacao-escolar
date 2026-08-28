# CLAUDE.md — Convenções do projeto

Sistema **MAE (Mapa da Alimentação Escolar)**: app para merendeiras de uma escola de turno integral registrarem o mapa de merenda, gerando o documento oficial ao final. Também é o Projeto Integrado Transdisciplinar (PIT) de Sistemas de Informação — Cruzeiro do Sul Virtual.

## Idioma

Tudo em **português brasileiro**: documentação, commits, issues, PRs e comentários de código.

## Regra de sigilo (CRÍTICA)

- **Nunca** versionar documentos oficiais da prefeitura, templates com brasão/símbolo, mapas reais preenchidos, dados pessoais ou credenciais. O `.gitignore` bloqueia `*.docx` e afins de propósito — não contornar com `git add -f` sem decisão explícita do autor.
- A pasta `_privado/` é local e **jamais** entra no repositório. Se existir, ler `_privado/contexto.md` no início da sessão — é o contexto completo de trabalho.
- Pessoas entrevistadas são anonimizadas na documentação pública ("Merendeira 1", "Merendeira 2").
- Antes de qualquer commit/PR, revisar se o diff vaza algo sensível.



## Etapas

O projeto avança em etapas sequenciais, cada uma com milestone e issues próprias:

E0 fundação ✅ → E1 Design Thinking ✅ → **E2 requisitos/backlog (atual)** → E3 UX → E4 modelagem de dados → E5 web MVP → E6 Flutter → E7 testes/laudo → E8 entrega.

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
- Estrutura por etapa: `docs/01-design-thinking/`, `docs/02-requisitos/`, `docs/03-ux/`, `docs/04-banco-de-dados/`, `docs/05-testes/` (+ `docs/assets/` para imagens).



## Stack

Monorepo: Supabase (Postgres, Auth, Storage, Edge Functions) em `supabase/`, web React em `web/`, Android Flutter em `app/`. Detalhes de libs são decididos quando a necessidade surge — não adicionar dependências por antecipação.