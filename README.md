# Mapa da Alimentação Escolar

> **Projeto Integrado Transdisciplinar (PIT) — Sistemas de Informação**
> **Universidade:** Cruzeiro do Sul Virtual
> **Autor:** Renan Douglas de Souza — RGM 31228348

## Sobre o projeto

**MAE** (sigla de *Mapa da Alimentação Escolar*, o próprio documento que o sistema produz) é um sistema para digitalizar o preenchimento do mapa de alimentação escolar de uma escola de turno integral. Hoje o processo é manual: um documento editado no computador, enviado por WhatsApp, impresso, assinado e entregue em papel à prefeitura.

O sistema permite que as merendeiras registrem diariamente as refeições servidas (lanche da manhã, almoço e lanche da tarde), o grau de aceitação de cada refeição, o número de refeições do dia e eventuais alterações de cardápio com justificativa — tendo como referência o cardápio oficial elaborado pela nutricionista. Ao final do período, o sistema gera o documento oficial pronto para assinatura.

## Stack

| Camada | Tecnologia |
|---|---|
| Backend (BaaS) | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| Web | React |
| Mobile (Android) | Flutter |

Estrutura em **monorepo**.

## Documentação

A documentação do projeto vive em [`docs/`](docs/), tendo o Markdown como fonte de verdade. Os `.docx` da faculdade são gerados ao final, como exportação.

**Plano** — [plano de projeto](docs/planodeprojeto.md): etapas E0–E8, entregáveis, cronograma e riscos.

**E1 · Design Thinking** — [síntese](docs/01-design-thinking/design-thinking.md) (empatia, mapa de afinidade, ideação e priorização) e o [roteiro de empatia](docs/01-design-thinking/roteiro-de-empatia.md) usado nas entrevistas.

**E2 · Requisitos** — [histórias de usuário](docs/02-requisitos/historias-de-usuario.md) e [backlog priorizado](docs/02-requisitos/backlog.md).

**E3 · UX** — [telas do MVP](docs/03-ux/telas.md), [fluxo de navegação](docs/03-ux/fluxo-de-telas.md), [decisões de design](docs/03-ux/decisoes-de-design.md), [catálogo de avisos e mensagens](docs/03-ux/avisos-e-mensagens.md) e a [validação com as merendeiras](docs/03-ux/validacao-com-as-merendeiras.md).

**E4 · Banco de dados** — [diagrama de classes](docs/04-banco-de-dados/diagrama-de-classes.md) → [modelo conceitual](docs/04-banco-de-dados/modelo-conceitual.md) → [modelo ER](docs/04-banco-de-dados/modelo-er.md) → [projeto físico](docs/04-banco-de-dados/projeto-fisico.md), com as [decisões de modelagem](docs/04-banco-de-dados/decisoes-de-modelagem.md) explicando o porquê de cada escolha. O SQL está em [`supabase/`](supabase/).

### Diagramas e telas

Os diagramas são escritos em Mermaid dentro dos próprios Markdown — o GitHub os renderiza, e assim eles continuam sendo texto versionado, com histórico e diff. As imagens de `docs/assets/` são apenas exportações, para o documento da faculdade, e se regeram por comando:

```bash
python3 design/exportar-telas.py       # as telas do produto
python3 design/exportar-diagramas.py   # os diagramas da modelagem
```

## Status

🚧 Em desenvolvimento — etapa atual: **E4 (modelagem de dados)**. Concluídas: E0 (fundação), E1 (Design Thinking), E2 (requisitos e backlog) e E3 (UX).

## Direitos

Este repositório é público exclusivamente para fins de leitura e avaliação acadêmica. **Todos os direitos reservados.** Não é permitido usar, copiar, modificar ou distribuir este código, no todo ou em parte, sem autorização expressa do autor.
