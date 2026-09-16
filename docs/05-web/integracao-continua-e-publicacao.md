# Integração contínua e publicação

O que verifica cada Pull Request e como a web chega ao ar. É a
[decisão 10](decisoes-tecnicas.md) implementada, e ela separa duas coisas de
propósito: **a CI é o lugar onde o erro aparece, e a publicação é o lugar onde
o produto aparece**. Quem publica é a Cloudflare, ligada ao repositório;
quem verifica são as GitHub Actions, em [`.github/workflows/`](../../.github/workflows/).

Isto entrou antes das telas de propósito: quanto mais cedo a verificação
existe, menos retrabalho acumula, e cada Pull Request passa a ter um endereço
navegável desde o começo da etapa.

## O que roda em cada Pull Request

| Fluxo | Dispara quando o PR toca | O que faz |
|---|---|---|
| [`web.yml`](../../.github/workflows/web.yml) | `web/` | ESLint, Prettier conferindo, checagem de tipos, testes, build e a conferência de que nenhum segredo entrou no pacote |
| [`banco.yml`](../../.github/workflows/banco.yml) | `supabase/`, o arquivo de tipos ou o script que o gera | sobe o Supabase local, reconstrói o banco das migrations, roda os cenários em pgTAP e confere se os tipos versionados continuam iguais aos do schema |
| [`spikes.yml`](../../.github/workflows/spikes.yml) | `supabase/spikes/` | formatação, lint, checagem de tipos e testes dos protótipos de servidor, em Deno |

Os três rodam de novo na `main` depois do merge. Não é zelo excessivo: o
*squash merge* produz um commit que **não existia** enquanto o PR era
verificado — é a junção do trabalho com o que entrou na `main` no meio do
caminho, e é exatamente esse commit que o Cloudflare vai publicar.

**Por que três fluxos e não um.** O filtro de caminho é o que separa: um PR só
de documentação não paga nada, um PR de tela paga o Node, um PR de spike paga o
Deno, e só quem mexe no banco paga o minuto de contêiner. Juntá-los num fluxo
só faria todo PR pagar o preço do mais caro. É também por isso que
`supabase/spikes/` é **excluído** do fluxo do banco: o que vive ali roda em
Deno e não toca o schema, e mexer num protótipo não deveria custar uma
reconstrução do banco.

**Por que as duas verificações do banco vivem no mesmo emprego.** Tanto o
pgTAP quanto a checagem de tipos precisam do banco de pé. Subir o Supabase duas
vezes, em dois empregos paralelos, custaria o dobro para provar o mesmo.

O mesmo, na sua máquina, antes de abrir o PR:

```bash
cd web && npm run lint && npm run format:check && npm run typecheck && npm test && npm run build && npm run check:secrets
supabase db reset && supabase test db   # na raiz, quando o banco mudou
cd web && npm run types:db:check
cd supabase/spikes/template-oficial && deno fmt --check && deno lint && deno check *.ts && deno test --allow-read
```

## As versões são fixas, e isso é a metade do valor da CI

A versão do Node está em [`web/.node-version`](../../web/.node-version), num
lugar só: é o que as Actions leem e é o que a Cloudflare lê ao construir
o pacote. A CLI do Supabase está presa a uma versão exata em `banco.yml` — ela
é quem **gera** os tipos, então uma CLI que se atualizasse sozinha passaria a
acusar defasagem que não existe, num PR que não tem nada a ver com o assunto.

Atualizar qualquer uma das duas é mudar a linha e ver a CI passar — que é
precisamente o que se quer de uma atualização de ferramenta: ela vira um PR
visível, e não um dia em que "a CI começou a falhar sozinha".

## O que a CI ainda não verifica

- **O teste ponta a ponta em Playwright** entra quando houver caminho crítico
  para percorrer — registrar um dia, sincronizar, gerar o documento. É a
  [decisão 11](decisoes-tecnicas.md), e tem issue própria na etapa.
- **A Edge Function da geração do documento** nasce depois do *spike* do
  template oficial; a verificação dela entra junto.
- **Os testes de componente cobrem hoje a autenticação** — login, sessão
  persistida, saída, rotas por perfil e a senha esquecida, contra um Supabase
  de mentira. O peso previsto pela decisão 11 continua à frente: a fila de
  envio, a convergência e as regras de estado do mapa, que ainda não existem.

## A publicação

A web é publicada como um **Worker da Cloudflare servindo assets estáticos**,
ligado ao repositório: cada commit que entra na `main` é construído e publicado,
e cada branch ganha uma **prévia** com endereço próprio, que a Cloudflare posta
como comentário no Pull Request.

O endereço de produção é **<https://mae.rds.dev.br>**, declarado como *custom
domain* em [`web/wrangler.jsonc`](../../web/wrangler.jsonc). Fica no arquivo, e
não no painel, pela mesma razão que o resto do roteamento: endereço é coisa que
se lê no repositório e se revisa num Pull Request. Como o domínio já vive na
Cloudflare, ela cuida do DNS e do certificado sozinha.

O endereço `workers.dev` **continua ligado**, de propósito: é nele que vivem as
prévias por branch. Vale um aviso que já custou caro em outros projetos —
declarar `routes` sem dizer nada sobre `workers_dev` faz o Wrangler deduzir
`false` e derrubar as prévias junto com o endereço antigo.

**Por que Workers e não Pages**, que era o nome na decisão original: a própria
Cloudflare passou a dizer que Workers é a plataforma principal e que projetos
novos devem começar por lá. O porquê da troca está na
[decisão 10](decisoes-tecnicas.md); aqui interessa o efeito prático, que é
quase nenhum — a aplicação é estática e as duas serviriam.

**Por que pelo painel, e não por um fluxo do GitHub Actions.** Publicar pelas
Actions exigiria guardar um token da Cloudflare nos segredos do GitHub e
reescrever à mão o comentário de prévia que a integração já faz. A integração
direta entrega o mesmo resultado sem mover credencial de lugar nenhum — e
credencial que não existe não vaza.

O que é publicado e como as rotas se comportam **não** mora no painel: está em
[`web/wrangler.jsonc`](../../web/wrangler.jsonc), versionado, revisável em Pull
Request. São três coisas: o nome, que define o endereço; a data de
compatibilidade, que congela o comportamento da plataforma para que uma
atualização futura do runtime não mude sozinha o que está no ar; e o
`not_found_handling: "single-page-application"`, que devolve o `index.html` para
qualquer caminho que não seja um arquivo. É esse último que mantém de pé uma
rota do React Router aberta direto na barra de endereço ou recarregada com F5 —
sem ele, tudo que não fosse a raiz daria 404, e **só em produção**, onde o
servidor de desenvolvimento não está lá para disfarçar.

No painel ficam apenas as ligações com o repositório:

| Campo | Valor |
|---|---|
| Branch de produção | `main` |
| Diretório raiz | `web` |
| Comando de build | `npm run build` |
| Comando de deploy | `npx wrangler deploy` |
| Versão do Node | lida de `web/.node-version` |

As prévias por branch exigem ligar as **build branches** de não-produção em
Settings → Build → Branch control; sem isso, só a `main` é construída.

### Para que serve a prévia, já que o desenvolvimento é local

Quem desenvolve testa na própria máquina, e para isso a prévia não acrescenta
nada. Ela existe para **quem não tem a máquina**: é o que permite mandar uma
tela para as merendeiras tocarem no celular delas antes de a mudança entrar na
`main` — a evolução natural do que foi feito na E3, quando a validação
aconteceu por imagens enviadas por mensagem. Na E7 isso deixa de ser
conveniência e vira método.

### Uma coisa registrada com todas as letras

**A prévia vai falar com o mesmo banco da produção.** O plano é um projeto
Supabase só, com as variáveis da prévia apontando para ele. Na prática isto
significa que a prévia de um Pull Request serve para conferir tela e fluxo, não
para exercitar dado à vontade: o que for gravado ali é gravado de verdade.
Enquanto os dados forem fictícios e o produto não estiver em uso real na
escola, o custo disso é zero e um segundo projeto seria cerimônia. No dia em
que houver dado real, a saída é um projeto de homologação com as mesmas
migrations — e este parágrafo existe para que aquele dia não chegue como
surpresa.

### As variáveis de ambiente

Ficam no painel, nos dois ambientes (produção e prévia): `VITE_SUPABASE_URL` e
`VITE_SUPABASE_PUBLISHABLE_KEY`. São as mesmas de
[`web/.env.example`](../../web/.env.example), e a explicação de por que são
públicas está na [fundação da web](fundacao-da-web.md#as-chaves).

**O dia previsto aqui chegou com a autenticação.** A web publicada agora abre
no login e fala com o Supabase desde a primeira tela, então as duas variáveis
passaram a ser obrigatórias nos dois ambientes do painel — sem elas, o
aplicativo carrega e não sobe, porque o cliente recusa a configuração ausente
em vez de tentar falar com endereço nenhum.

A CI continua sem segredo nenhum configurado, e isso não mudou: o build não
precisa das variáveis para compilar, só o navegador precisa delas para
funcionar. O que a CI ganhou foi o passo inverso — conferir que **nada além**
delas entrou no pacote (ver [autenticação, sessão e rotas por perfil](autenticacao-e-sessao.md)).

Junto com as variáveis, o projeto do Supabase na nuvem precisa de duas coisas
declaradas no painel, que o `config.toml` só resolve no ambiente local: os
endereços permitidos para o link de senha nova, em *Authentication > URL
Configuration*, e o texto em português do e-mail de senha nova, em
*Authentication > Emails*.

## O que nunca entra no pacote publicado

Só variáveis com o prefixo `VITE_` chegam ao navegador, e só duas existem: a
URL do projeto e a chave publicável, que é pública por construção e só alcança
o que as políticas de RLS deixarem. A chave secreta — a que ignora as políticas
— não tem nome no painel da Cloudflare, não tem nome nos segredos do GitHub e
não existe em lugar nenhum do que é construído aqui: ela vive apenas no
ambiente das Edge Functions, no Supabase.
