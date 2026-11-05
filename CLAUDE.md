# CLAUDE.md — Convenções do projeto

Sistema **MAE (Mapa da Alimentação Escolar)**: as merendeiras de uma escola de turno integral registram o mapa da merenda e geram o documento oficial ao final. Nasceu como o Projeto Integrado Transdisciplinar (PIT) de Sistemas de Informação — Cruzeiro do Sul Virtual, entregue em novembro de 2026 com a web no ar e o aplicativo na versão 0.1.5. O histórico por etapa (E0–E8) está nas milestones e no [plano de projeto](docs/planodeprojeto.md).

## Idioma

Tudo em **português brasileiro**: documentação, commits, issues, PRs e comentários de código.

**Exceção — identificadores de código são em inglês**, no singular: tabelas, colunas, tipos, variáveis, funções e componentes. O conteúdo — textos de interface, dados cadastrados, comentários — fica em português. Glossário domínio → banco na [decisão 13 da E4](docs/04-banco-de-dados/decisoes-de-modelagem.md).

## Regra de sigilo (CRÍTICA)

- **Nunca** versionar documentos oficiais da prefeitura, modelos com brasão/símbolo, mapas reais preenchidos, dados pessoais ou credenciais. O `.gitignore` bloqueia `*.docx` e afins de propósito — não contornar com `git add -f` sem decisão explícita do autor.
- A pasta `_privado/` é local e **jamais** entra no repositório. Se existir, ler `_privado/contexto.md` no início da sessão.
- Pessoas entrevistadas e testadoras são anonimizadas na documentação pública ("Merendeira 1", "Merendeira 2").
- Antes de qualquer commit/PR, revisar se o diff vaza algo sensível.

## Fluxo Git/GitHub

- `main` protegida: mudanças só via PR. Branch curta por assunto (`docs/...`, `feat/...`, `fix/...`), **squash merge** com exclusão da branch; o título do PR vira a mensagem do commit, em conventional commit.
- Vincular issues com `closes #N` ou `refs #N`.

## Documentação

- Markdown em `docs/` é a **fonte da verdade**, uma pasta por etapa (`01-design-thinking` … `07-testes`, + `assets/`). `docs/05-web/` documenta `web/`; `docs/06-app/` documenta `app/`.
- As telas têm fonte em `design/telas/` e imagens em `docs/assets/`, geradas por `python3 design/exportar-telas.py`; os diagramas são Mermaid nos Markdown, exportados por `python3 design/exportar-diagramas.py`. O desenho também vive num canvas fora do repositório, e a sincronia vale **nos dois sentidos**: mexeu no canvas, atualizar `design/telas/` antes de exportar; mexeu em `design/telas/`, republicar o canvas.

## Stack

Monorepo: Supabase (Postgres com RLS, Auth, Storage, Edge Functions) em `supabase/`, web React em `web/`, Android Flutter em `app/`. O porquê de cada escolha está nas decisões técnicas [da web](docs/05-web/decisoes-tecnicas.md) e [do app](docs/06-app/decisoes-tecnicas.md).

- **O app é só da merendeira** e funciona sem rede no registro e no mapa; a direção fica na web, que também é o plano B da merendeira. Web e app gravam o dia pela mesma `save_meal_map`.
- **Migrations rodam sobre dados existentes**: toda mudança de schema preserva o que já está gravado.
- **Release do app**: tag `app-v*` na `main` → a CI compila, assina e publica o APK. Se o formato do que o app manda mudar, a versão mínima sobe por migration **depois** da release publicada (ver [versão mínima](docs/06-app/versao-minima.md)).
- Não adicionar dependências por antecipação.
