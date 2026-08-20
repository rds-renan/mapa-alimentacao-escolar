# Plano de Projeto — Mapa da Alimentação Escolar

> Repositório: `rds-renan/mapa-alimentacao-escolar` · Destino no repo: `docs/plano-de-projeto.md`

## 1. Visão geral

Sistema para registro diário da alimentação escolar (mapa de merenda) de uma escola integral, substituindo o preenchimento manual do documento `.doc` enviado semanalmente à prefeitura.

O projeto tem dupla finalidade:

1. **Produto real** — usado pelas merendeiras e pela direção da escola.
2. **Trabalho de conclusão (PIT)** — curso de Sistemas de Informação, com entrega do documento da atividade preenchido, repositório público, sistema no ar e vídeo narrado de no mínimo 5 minutos.

### O problema

Hoje as merendeiras editam manualmente (ou pelo celular) um arquivo `.doc` com o cardápio realizado de cada dia da semana. O processo é lento, sujeito a erro, sem histórico consultável e sem qualquer aproveitamento dos dados. O documento final é enviado via WhatsApp para impressão, coleta de assinaturas e envio físico à prefeitura.

### A solução

CRUD simples e amigável onde a merendeira registra, por dia: as três refeições (lanche da manhã, almoço, lanche da tarde), grau de aceitação, número de refeições, mudanças de cardápio com justificativa e gêneros utilizados — ou marca o dia como **não letivo** com observação. A partir dos registros, ela seleciona os dias desejados e o sistema **gera o documento oficial no servidor**, servindo um link de download temporário (arquivo e link expiram em até 7 dias; regerar é barato).

## 2. Decisões já tomadas

| Tema | Decisão |
|---|---|
| Backend | Supabase (BaaS): Postgres, Auth, Storage, Edge Functions |
| Front web | React |
| App mobile | Flutter (Android) |
| Perfis | `admin` (vê tudo, cadastra merendeiras) e `user`/merendeira (CRUD completo do mapa) |
| Cardápio | O cardápio semanal da nutricionista é a referência oficial; o mapa da merenda registra o que foi de fato executado, com justificativa quando houver alteração |
| Dia não letivo | Registro apenas com observação (ex.: conselho de classe) |
| Aceitação e nº de refeições | Grau de aceitação é por refeição; nº de refeições é único por dia (escola de turno integral — as professoras informam a presença do dia). Ambos preenchidos pela merendeira |
| Documento gerado | Gerado no servidor a partir do template oficial armazenado no Supabase Storage (bucket privado, gerenciado pelo admin); link temporário, sem armazenamento permanente (máx. 7 dias) |
| Sigilo | Nenhum documento oficial (template com símbolo/nome da prefeitura), dado pessoal ou credencial entra no repositório — vale desde o primeiro commit |
| Licença | Repositório público sem licença: todos os direitos reservados (leitura/avaliação apenas; ninguém pode usar, modificar ou distribuir) |
| Metodologia de descoberta | Design Thinking (substitui o Canvas da PIT I) |
| Documentação | Markdown no repositório (`docs/`) como fonte de verdade; o `.docx` da faculdade é gerado ao final como "export" |
| Repositório | Monorepo: web, app e banco no mesmo repo (facilita a entrega única da faculdade) |
| Prazo máximo | ~3 meses (meados de novembro/2026) |

## 3. Metodologia de trabalho

- **Descoberta**: Design Thinking (empatia → definição → ideação → prototipação → teste), com relatos reais das merendeiras.
- **Gestão**: iterativo e incremental, inspirado em Scrum — backlog priorizado por histórias de usuário com pontos, trabalho fatiado em milestones (uma por etapa do plano).
- **Rastreabilidade**: cada artefato/funcionalidade nasce de uma issue, é desenvolvido em branch, revisado em Pull Request e fechado com referência à issue. O histórico do repositório conta a cronologia real do projeto.

## 4. Ecossistema GitHub

Estrutura para aprender e usar o GitHub além do commit/push/pull:

- **Issues** — cada entregável ou funcionalidade vira uma issue com descrição e critérios de aceite. Commits e PRs fecham issues com `closes #N`.
- **Labels** — `docs`, `design-thinking`, `requisitos`, `banco-de-dados`, `web`, `mobile`, `infra`, `bug`, `melhoria`.
- **Milestones** — uma por etapa (E1…E8), com data alvo. O progresso da milestone mostra o avanço da etapa.
- **Projects (v2)** — um board Kanban do repositório com colunas `Backlog → A fazer → Em andamento → Concluído`, alimentado pelas issues. É a visão de gestão do projeto (e evidência de gestão para a faculdade).
- **Branches e PRs** — `main` protegida como linha oficial; trabalho em branches `feat/...`, `docs/...`, `fix/...`; merge via Pull Request (self-review com descrição do que foi feito).
- **Conventional Commits** — `feat:`, `fix:`, `docs:`, `chore:` etc., mantendo o histórico legível.
- **Actions (CI/CD)** — lint/build automático dos apps e deploy contínuo do front (Vercel ou similar) a partir da `main`.
- **README + Releases** — README como vitrine do projeto; ao final de cada etapa relevante, uma tag/release (ex.: `v0.1-docs`, `v0.2-mvp-web`).

## 5. Estrutura do repositório

```
mapa-alimentacao-escolar/
├── README.md
├── docs/
│   ├── plano-de-projeto.md
│   ├── 01-design-thinking/      # empatia, personas, POV, ideação, mapa de afinidade
│   ├── 02-requisitos/           # histórias de usuário, backlog priorizado
│   ├── 03-ux/                   # wireframes e mockups
│   ├── 04-banco-de-dados/       # diagrama de classes, conceitual, ER, projeto físico
│   ├── 05-testes/               # testes com colegas, laudo de qualidade
│   └── assets/                  # imagens/diagramas exportados
├── supabase/                    # migrations, policies (RLS), seed, edge functions
├── web/                         # aplicação React
└── app/                         # aplicativo Flutter
```

## 6. Etapas, entregáveis e critérios de conclusão

Cada etapa vira uma **milestone** no GitHub, com suas issues, e é commitada/mergeada ao terminar — mantendo a cronologia natural de um projeto.

### E0 — Fundação do projeto (semana 1)

**Entregáveis:** README novo (cabeçalho acadêmico com autor/RGM/universidade, contexto e problema — sem seção de licença, já que todos os direitos são reservados), este plano em `docs/`, estrutura de pastas, `.gitignore` preventivo + diretriz de sigilo (templates oficiais, `.env`, credenciais e dados pessoais nunca versionados), labels, milestones e board do GitHub Projects configurados.
**Concluída quando:** repo organizado, board ativo e plano commitado.

### E1 — Descoberta: Design Thinking (semanas 1–2)

**Entregáveis (`docs/01-design-thinking/`):**
- Empatia: roteiro e síntese das conversas com as merendeiras e direção (relatos reais).
- Mapa de afinidade (agrupamento das dores e observações).
- Personas (merendeira e direção/admin).
- Definição do problema (POV / "Como poderíamos…").
- Ideação: alternativas consideradas e solução escolhida.
- Protótipo de baixa fidelidade (rascunho) para validar com elas.

**Concluída quando:** artefatos revisados e validados com as usuárias reais.

### E2 — Requisitos e backlog (semanas 2–3)

**Entregáveis (`docs/02-requisitos/`):**
- Mínimo de 15 histórias de usuário no template da faculdade (ID, título, requerente, ação, comentários, CA, RN, RNF, prioridade A–E, pontos).
- Backlog priorizado em tabela, organizado por tema.

**Concluída quando:** backlog fechado e priorizado (prioridade A = escopo mínimo do produto).

### E3 — UX: wireframes e mockups (semanas 3–4)

**Entregáveis (`docs/03-ux/`):** fluxo de telas, wireframes das telas principais (login, lista de dias/mapa, registro do dia, dia não letivo, geração do documento, admin) e mockups de média/alta fidelidade para web e mobile.
**Concluída quando:** telas cobrem todas as histórias prioridade A e foram validadas com as merendeiras.

### E4 — Modelagem de dados (semana 5)

**Entregáveis (`docs/04-banco-de-dados/`):**
- Diagrama de classes.
- Modelo conceitual → Modelo ER → Projeto físico (SQL das migrations do Supabase/Postgres, incluindo políticas RLS por perfil).

**Concluída quando:** migrations aplicadas em projeto Supabase de desenvolvimento.

### E5 — Desenvolvimento web MVP (semanas 6–9)

**Entregáveis (`web/` + `supabase/`):**
- Autenticação (admin e merendeira) e gestão de usuárias pelo admin.
- CRUD do registro diário (refeições, aceitação, nº de refeições, mudança de cardápio, dia não letivo).
- Seleção de dias + geração do documento oficial no servidor (Edge Function) a partir do template armazenado no Supabase Storage, link temporário com expiração ≤ 7 dias e limpeza automática.
- Área do admin para gerenciar o template oficial no Storage.
- Deploy contínuo (CI) com sistema acessível por URL pública.

**Concluída quando:** fluxo completo real — registrar a semana e baixar o documento pronto para impressão.

### E6 — App mobile Flutter (semanas 9–11)

**Entregáveis (`app/`):** app Android com login, registro do dia e geração/compartilhamento do documento (mesmo backend). APK de distribuição.
**Concluída quando:** merendeira consegue fazer o fluxo completo pelo celular.

### E7 — Validação: testes e qualidade (semana 11)

**Entregáveis (`docs/05-testes/`):**
- Testes com 5 colegas no template da faculdade (nome, data, o que funcionou, o que corrigir, o que faltou).
- Correções derivadas dos feedbacks (issues `bug`/`melhoria`).
- Laudo de qualidade com evidências (prints antes/depois, erros e correções).

**Concluída quando:** correções pertinentes aplicadas e laudo fechado.

### E8 — Entrega da faculdade (semana 12)

**Entregáveis:**
- `PIT_atividade.docx` preenchido: documentação completa, banco de dados, tabela de codificação (linguagem, BD, hospedagem, plataforma, modo tradicional, links), testes, laudo.
- Repositório público revisado (README caprichado, release final).
- Sistema no ar com link estável.
- Vídeo narrado de no mínimo 5 minutos (roteiro incluído).

**Concluída quando:** pacote de entrega completo e revisado.

## 7. Cronograma resumido (referência: início 18/08/2026)

| Etapa | Período alvo |
|---|---|
| E0 Fundação | 18–22 ago |
| E1 Design Thinking | 18–30 ago |
| E2 Requisitos e backlog | 24 ago – 06 set |
| E3 Wireframes e mockups | 31 ago – 13 set |
| E4 Modelagem de dados | 14–20 set |
| E5 Web MVP | 21 set – 18 out |
| E6 App Flutter | 12 out – 01 nov |
| E7 Testes e laudo | 02–08 nov |
| E8 Entrega final | 09–15 nov |

As datas são linha de referência, não contrato: etapas podem fechar antes do previsto e isso é desejável — o objetivo é concluir com folga antes do prazo máximo (~18/nov) para haver margem de correção caso algo dê errado na avaliação.

## 8. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Geração do `.doc/.docx` fiel ao modelo oficial ser mais difícil que o previsto | Gerar a partir do template oficial (preenchimento de campos), não do zero; prototipar cedo (spike técnico na E4/E5); alternativa: PDF idêntico ao layout |
| Exposição indevida de documentos oficiais da prefeitura | Template só no Supabase Storage (bucket privado); `.gitignore` e revisão de PR impedem versionamento acidental |
| Indisponibilidade das merendeiras para validação | Validar por WhatsApp com prints; o contato é direto e frequente |
| Escopo crescer (relatórios, estoque etc.) | Tudo que não é prioridade A vira backlog pós-entrega |
| Prazo da faculdade | Web MVP é o caminho crítico; Flutter começa só com web estável |
