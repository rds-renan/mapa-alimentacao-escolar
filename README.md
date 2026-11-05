<div align="center">
    <img src="web/public/logo.png" alt="Ícone do MAE" width="96">
    <h1>MAE — Mapa da Alimentação Escolar</h1>
</div>


![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2671E5?style=for-the-badge&logo=githubactions&logoColor=white)

<div align="center">
    <h4>Projeto Integrado Transdisciplinar — Sistemas de Informação</h4>
    <p>
        <b>Autor:</b> Renan Douglas de Souza &bull; <b>RGM:</b> 31228348<br>
        <b>Universidade:</b> Cruzeiro do Sul Virtual &bull; <b>Data:</b> novembro de 2026
    </p>
    <p>
        <a href="https://mae.rds.dev.br"><b>Web publicada</b></a> &bull;
        <a href="https://github.com/rds-renan/mapa-alimentacao-escolar/releases/tag/app-v0.1.5"><b>Aplicativo Android (0.1.5)</b></a> &bull;
        <a href="docs/"><b>Documentação</b></a>
    </p>
</div>

---

## 📖 Sobre o projeto

**MAE** é a sigla de *Mapa da Alimentação Escolar*, o próprio documento que o sistema produz. Todo dia letivo, as merendeiras registram nele o que foi servido no lanche da manhã, no almoço e no lanche da tarde, a aceitação de cada refeição, o número de refeições do dia, os gêneros usados e qualquer mudança no cardápio da nutricionista, com a justificativa. No fim do período o mapa vai impresso e assinado para a prefeitura.

### A dor que ele resolve

Antes do MAE, o mapa era preenchido num PDF comentado pelo celular — mais lento que escrever à mão —, normalmente em casa, à noite, porque a cozinha é úmida e a rotina não para. O aplicativo que fecha sozinho e leva junto o que já tinha sido digitado era a dor mais lembrada nas entrevistas. E a escola fica no interior, sem sinal de operadora e com Wi-Fi instável.

O MAE muda só **como o documento nasce**. O resto do caminho continua igual: o mesmo modelo oficial, compartilhado pelo WhatsApp, impresso pela secretaria e assinado em papel.

- **Nada se perde**: cada toque é gravado no aparelho, sem botão de salvar, e sobe sozinho quando a internet volta.
- **Funciona sem rede**: no aplicativo, o registro e a visão do mês funcionam sem internet.
- **Um documento só**: a merendeira escolhe os dias — avulsos, uma semana ou o mês inteiro — e o sistema gera um único documento no formato oficial.
- **Mais rápido que à mão**: um dia inteiro levava 8 min 42 s no papel e passou a levar 2 min 50 s no aplicativo, segundo a [medição feita nos testes](docs/07-testes/relato-dos-testes.md).

---

## 🛠️ Tecnologias

| Camada | Tecnologia |
|---|---|
| Backend | Supabase: PostgreSQL com políticas de acesso por linha (RLS), Auth, Storage e Edge Functions em Deno |
| Web | React + TypeScript com Vite, Tailwind CSS, shadcn/ui, React Router e TanStack Query; rascunho e fila de envio em IndexedDB |
| Aplicativo (Android) | Flutter com Material 3, Riverpod, go_router e Drift (SQLite) como banco local |
| Hospedagem da web | Cloudflare Workers, com domínio próprio |
| Integração contínua | GitHub Actions: lint, tipos, testes, build, pgTAP no banco, teste de ponta a ponta com Playwright e a release assinada do APK |

O monorepo tem o banco e as funções em [`supabase/`](supabase/), a web em [`web/`](web/) e o aplicativo em [`app/`](app/). O porquê de cada escolha está nas decisões técnicas [da web](docs/05-web/decisoes-tecnicas.md) e [do aplicativo](docs/06-app/decisoes-tecnicas.md).

---

## ✨ Funcionalidades

### 👩‍🍳 Para a merendeira — aplicativo Android (e a web, como plano B)

- [x] Visão do mês com a situação de cada dia: pendente, preenchido, não letivo, no documento ou reaberto.
- [x] Registro do dia: as três refeições com a aceitação em um toque (Ruim · Bom · Ótimo) e o número de refeições do dia.
- [x] Gêneros utilizados no dia, em quantidades inteiras na unidade padrão de cada um, com vários escolhidos de uma vez.
- [x] Alteração do cardápio com o motivo, e dia não letivo só com observação.
- [x] Catálogo de gêneros com a unidade padrão; desativar tira das sugestões sem apagar o passado.
- [x] Gravação a cada toque, sem rede, e envio automático quando a conexão volta.
- [x] Seleção de mapas (dias avulsos, semana ou mês) e geração de um único documento oficial em `.docx`.
- [x] Compartilhamento do documento pelo WhatsApp e lista dos documentos que ainda estão disponíveis (sete dias).
- [x] Aviso de documento pronto ao abrir o aplicativo.
- [x] Senha nova por código de 6 dígitos enviado por e-mail, sem sair do aplicativo.
- [x] Tema escuro, para preencher à noite.
- [x] Atualização pelo próprio aplicativo, com trava de versão mínima.

### 🏫 Para a direção — web

- [x] Painel gerencial do mês: aceitação por refeição, refeições servidas e as merendas mais bem aceitas.
- [x] Acesso das merendeiras: criar, desativar e reativar.
- [x] Modelo oficial do documento, guardado em área privada, e os dados da escola que vão no cabeçalho.
- [x] Consulta aos mapas e reabertura de um dia já entregue, com justificativa, para a merendeira corrigir e gerar o documento de novo.

---

## 🔗 Links

| O quê | Onde |
|---|---|
| Web publicada | <https://mae.rds.dev.br> |
| Aplicativo Android — versão entregue, 0.1.5 | [release `app-v0.1.5`](https://github.com/rds-renan/mapa-alimentacao-escolar/releases/tag/app-v0.1.5) ([`mae-0.1.5.apk`](https://github.com/rds-renan/mapa-alimentacao-escolar/releases/download/app-v0.1.5/mae-0.1.5.apk)) |
| Repositório | <https://github.com/rds-renan/mapa-alimentacao-escolar> |

O acesso é criado pela direção da escola — não há autocadastro. O APK é instalado direto pelo arquivo, fora da Play Store, como está em [release e distribuição](docs/06-app/release-e-distribuicao.md).

---

## 📚 Documentação

O Markdown em [`docs/`](docs/) é a fonte da verdade do projeto, organizado na ordem do trabalho. O [plano de projeto](docs/planodeprojeto.md) traz as etapas, o cronograma e os riscos.

| Etapa | Documentos |
|---|---|
| **E1 · Design Thinking** | [síntese](docs/01-design-thinking/design-thinking.md) (empatia, mapa de afinidade, ideação e priorização) · [roteiro de empatia](docs/01-design-thinking/roteiro-de-empatia.md) |
| **E2 · Requisitos** | [histórias de usuário](docs/02-requisitos/historias-de-usuario.md) · [backlog priorizado](docs/02-requisitos/backlog.md) |
| **E3 · UX** | [telas](docs/03-ux/telas.md) · [fluxo de telas](docs/03-ux/fluxo-de-telas.md) · [decisões de design](docs/03-ux/decisoes-de-design.md) · [avisos e mensagens](docs/03-ux/avisos-e-mensagens.md) · [validação com as merendeiras](docs/03-ux/validacao-com-as-merendeiras.md) |
| **E4 · Banco de dados** | [diagrama de classes](docs/04-banco-de-dados/diagrama-de-classes.md) → [modelo conceitual](docs/04-banco-de-dados/modelo-conceitual.md) → [modelo ER](docs/04-banco-de-dados/modelo-er.md) → [projeto físico](docs/04-banco-de-dados/projeto-fisico.md) · [decisões de modelagem](docs/04-banco-de-dados/decisoes-de-modelagem.md) |
| **E5 · Web** | [decisões técnicas](docs/05-web/decisoes-tecnicas.md) · [gravação do dia](docs/05-web/gravacao-do-dia.md) · [camada local](docs/05-web/camada-local.md) · [geração do documento](docs/05-web/geracao-do-documento.md) · [integração contínua e publicação](docs/05-web/integracao-continua-e-publicacao.md) · [teste de ponta a ponta](docs/05-web/teste-ponta-a-ponta.md) · e uma página por tela, na [pasta da etapa](docs/05-web/) |
| **E6 · Aplicativo** | [decisões técnicas](docs/06-app/decisoes-tecnicas.md) · [banco local](docs/06-app/banco-local.md) · [fila de envio e convergência](docs/06-app/fila-de-envio-e-convergencia.md) · [release e distribuição](docs/06-app/release-e-distribuicao.md) · [versão mínima](docs/06-app/versao-minima.md) · e uma página por tela, na [pasta da etapa](docs/06-app/) |
| **E7 · Testes** | [plano de testes](docs/07-testes/plano-de-testes.md) · [varredura técnica](docs/07-testes/varredura-tecnica.md) · [relato dos testes](docs/07-testes/relato-dos-testes.md) · [laudo de qualidade](docs/07-testes/laudo-de-qualidade.md) |

Os diagramas são escritos em Mermaid dentro dos próprios Markdown, e as telas têm a fonte em [`design/`](design/). As imagens de [`docs/assets/`](docs/assets/) são só exportações, regeradas por `python3 design/exportar-telas.py` e `python3 design/exportar-diagramas.py`.

---

## ⚙️ Como rodar localmente

### Pré-requisitos

- Git
- Docker e a [CLI do Supabase](https://supabase.com/docs/guides/cli)
- Node.js 24 (a versão exata está em `web/.node-version`), para a web
- Flutter estável com o Android configurado (`flutter doctor`), para o aplicativo
- Deno, só para exercitar a geração do documento

### 1. Banco

```bash
git clone https://github.com/rds-renan/mapa-alimentacao-escolar.git
cd mapa-alimentacao-escolar
supabase start       # sobe os contêineres e imprime as URLs e as chaves locais
supabase db reset    # migrations em ordem + dados fictícios
```

O seed cria uma escola fictícia com três contas, todas com a senha `mae-desenvolvimento`: `direcao@dominio.com.br` (direção), `merendeira1@dominio.com.br` e `merendeira2@dominio.com.br`.

### 2. Web

```bash
cd web
cp .env.example .env    # preencha com a URL e a chave publicável que o supabase start imprimiu
npm install
npm run dev
```

### 3. Aplicativo

```bash
cd app
cp env/local.example.json env/local.json    # idem, com o endereço do PC na rede se for um aparelho físico
flutter pub get
flutter run --dart-define-from-file=env/local.json
```

### 4. Geração do documento

O modelo oficial da prefeitura não está no repositório. Para gerar um documento na sua máquina, sirva as funções com `supabase functions serve` e suba o **modelo de teste** — mesma estrutura, nada da prefeitura —, como está no [README das funções](supabase/functions/README.md).

### Testes

```bash
supabase test db                 # banco, em pgTAP
cd web && npm test               # web, em Vitest
cd web && npm run test:e2e       # caminho crítico em Playwright, contra o banco local
cd app && flutter test           # aplicativo, unidade e widget
```

Os detalhes de cada parte estão em [`supabase/README.md`](supabase/README.md), na [fundação da web](docs/05-web/fundacao-da-web.md) e na [fundação do aplicativo](docs/06-app/fundacao-do-app.md).

---

## 👏 Créditos

- **As merendeiras da escola**, que deram as entrevistas, validaram as telas e testaram o aplicativo no uso real, e **quem testou a web** — todas as pessoas anonimizadas na documentação.
- **Interface da web**: componentes de [shadcn/ui](https://ui.shadcn.com) sobre os tokens de design próprios do projeto.
- **Desenvolvimento assistido por IA**: o projeto foi desenvolvido com o apoio do [Claude Code](https://claude.com/claude-code).

---

## 📄 Direitos

Este repositório é público exclusivamente para fins de leitura e avaliação acadêmica. **Todos os direitos reservados.** Não é permitido usar, copiar, modificar ou distribuir este código, no todo ou em parte, sem autorização expressa do autor.
