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
| [`web.yml`](../../.github/workflows/web.yml) | `web/` | ESLint, Prettier conferindo, checagem de tipos, testes, build e, sobre o pacote pronto, duas conferências: que nenhum segredo entrou dentro dele e que o peso não passou do teto |
| [`banco.yml`](../../.github/workflows/banco.yml) | `supabase/`, o arquivo de tipos ou o script que o gera | sobe o Supabase local, reconstrói o banco das migrations, roda os cenários em pgTAP e confere se os tipos versionados continuam iguais aos do schema |
| [`funcoes.yml`](../../.github/workflows/funcoes.yml) | `supabase/functions/` | formatação, lint, checagem de tipos e testes das Edge Functions, em Deno |

Os três rodam de novo na `main` depois do merge. Não é zelo excessivo: o
*squash merge* produz um commit que **não existia** enquanto o PR era
verificado — é a junção do trabalho com o que entrou na `main` no meio do
caminho, e é exatamente esse commit que o Cloudflare vai publicar.

**Por que três fluxos e não um.** O filtro de caminho é o que separa: um PR só
de documentação não paga nada, um PR de tela paga o Node, um PR de Edge
Function paga o Deno, e só quem mexe no banco paga o minuto de contêiner.
Juntá-los num fluxo só faria todo PR pagar o preço do mais caro. É também por
isso que `supabase/functions/` é **excluído** do fluxo do banco: o que vive ali
roda em Deno e não toca o schema, e mexer numa função não deveria custar uma
reconstrução do banco.

**Por que as duas verificações do banco vivem no mesmo emprego.** Tanto o
pgTAP quanto a checagem de tipos precisam do banco de pé. Subir o Supabase duas
vezes, em dois empregos paralelos, custaria o dobro para provar o mesmo.

O mesmo, na sua máquina, antes de abrir o PR:

```bash
cd web && npm run lint && npm run format:check && npm run typecheck && npm test && npm run build && npm run check:secrets && npm run check:size
supabase db reset && supabase test db   # na raiz, quando o banco mudou
cd web && npm run types:db:check
cd supabase/functions && deno task verificar   # fmt, lint, tipos e testes das Edge Functions
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

## O peso do pacote tem um teto

O assunto nasceu ao medir o pacote durante a [visão do mês](visao-do-mes.md) e
rendeu duas coisas: os cabeçalhos de cache, que estão mais abaixo, e o que se
descreve aqui. O pacote pesa **623 kB crus, 185 kB em gzip**, e o que está
dentro dele é, quase tudo, dependência:

| | kB crus | % |
|---|---|---|
| React + react-dom + scheduler | 213,7 | 35,2% |
| Supabase | 203,8 | 33,6% |
| React Router | 37,7 | 6,2% |
| Radix + apoio | 35,5 | 5,9% |
| TanStack Query | 31,9 | 5,3% |
| `cn` / tailwind-merge | 25,6 | 4,2% |
| lucide (só os ícones usados) | 7,1 | 1,2% |
| **o nosso código** | **44,4** | **7,3%** |

**O problema não era rapidez.** 185 kB em gzip é leve para a internet de hoje,
e o custo de interpretar 623 kB crus cairia sobre celular barato — mas a web é
o computador da escola e o plano B; o celular é o aplicativo da E6. O problema
era outro: **um pedaço só, um hash só**. Mudar uma linha de uma tela trocava o
nome do pacote inteiro, e todo navegador rebaixava os 185 kB — React e Supabase
inclusos, sem que nada neles tivesse mudado. E o projeto publica **a cada merge
na `main`**, então isso não era custo de primeira visita: era recorrente, uma
vez por merge, para cada merendeira. O `immutable` da seção de cabeçalhos só
rende se alguma coisa de fato permanecer guardada entre dois deploys — e não
permanecia nada.

### Duas peças em vez de uma

O build agora separa o que vem de `node_modules` do que é nosso, em
[`web/vite.config.ts`](../../web/vite.config.ts). O resultado, medido:

| Pedaço | gzip | Troca de nome quando |
|---|---|---|
| `vendor` | 171,8 kB | uma dependência é atualizada |
| o nosso | 14,2 kB | qualquer tela muda |
| runtime do bundler | 0,4 kB | o Vite é atualizado |

**92% do peso agora sobrevive ao deploy.** O custo é uma requisição a mais, o
que em HTTP/2 não se mede, e cerca de 1 kB em gzip de repetição entre os dois
arquivos.

Isso se confere olhando, e foi conferido: dois builds seguidos com uma mudança
de texto no meio, e o `vendor-C7gUMEVe.js` saiu com o mesmo nome nos dois,
enquanto o nosso pedaço trocou de hash. É essa igualdade de nome que o cache do
navegador enxerga.

### O teto, que é um lembrete e não uma meta

A outra metade da história é a divisão por rota — não baixar o painel e a
administração para quem só vai registrar o almoço. Ela **não paga hoje**: as
telas candidatas ainda são telas-marco de dez linhas, esperando as suas issues.
Dividir agora não dividiria nada.

O momento certo é quando existir tela pesada que ninguém abre todo dia, e na
prática isso quer dizer a biblioteca de gráficos do painel gerencial, que
sozinha é da ordem de 100 kB em gzip. O problema é que uma issue **lembra, mas
não garante** — ela some numa limpeza de milestone ou fica esperando uma data
que ninguém sabe qual é. Quem garante é a CI:
[`npm run check:size`](../../web/scripts/conferir-peso-do-pacote.mjs) mede o
`dist/` depois do build e reprova acima de **205 kB em gzip**, ao lado da
conferência de segredos, no mesmo lugar e pelo mesmo motivo — as duas olham o
pacote pronto, e não o código-fonte.

**O que se mede é a carga inicial**, e não o maior arquivo: o módulo de entrada
declarado no `index.html` mais tudo o que o próprio HTML manda pré-carregar.
Com o pacote partido em dois, o que custa a quem abre a tela é a soma, não a
maior parcela. E é justamente por isso que um pedaço carregado sob demanda não
entra na conta: **a saída para o teto é dividir, e a régua tem de reconhecer
quando alguém dividiu.**

O número deixa cerca de 20 kB de folga sobre os 184,7 kB de hoje. O nosso
código inteiro, quinze telas, são 14 kB em gzip — então as telas que faltam da
merendeira cabem sem acender nada, e a biblioteca de gráficos estoura no
primeiro commit. Que é exatamente o momento em que se quer ser interrompido.

O custo disso é honesto e vale escrever: **é um build vermelho num momento
inconveniente, por construção.** Quem estiver na issue do painel leva o tapa
sem ter feito nada de errado. É o preço de a decisão não depender de alguém
lembrar dela, e a saída, naquele dia, é uma das duas — carregar a biblioteca na
rota, com `lazy()`, ou subir o teto num commit que diz por quê.

### Duas coisas que ficaram de fora, de propósito

**Os ~55 kB de realtime que nunca usamos.** O `supabase-js` puxa `realtime-js`
e `phoenix` incondicionalmente, e não há uma chamada a `.channel()` no
repositório. Fugir disso exigiria importar os sub-clientes direto e abrir mão
do cliente unificado — o peso é aceitável e a refatoração não se paga.

**O aviso de pacote grande do Vite**, que foi desligado. Ele dispara acima de
500 kB crus, um número fixo que não sabe nada deste projeto, e o pedaço de
terceiros vive acima dele por natureza: React e Supabase sozinhos passam disso.
Um alarme que toca sempre e um alarme que toca quando importa não convivem —
o segundo vira ruído junto do primeiro.

## O que a CI ainda não verifica

- **O teste ponta a ponta em Playwright** entra quando houver caminho crítico
  para percorrer — registrar um dia, sincronizar, gerar o documento. É a
  [decisão 11](decisoes-tecnicas.md), e tem issue própria na etapa.
- **A geração de ponta a ponta contra o Supabase de verdade** não roda na CI. O
  que `funcoes.yml` verifica é o preenchimento e a tradução do banco para o
  documento, sem rede; o caminho inteiro — sessão, Storage, bloqueio — foi
  percorrido à mão contra o Supabase local, e é ele que o Playwright da
  [decisão 11](decisoes-tecnicas.md) vai cobrir quando a tela existir.
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

### Os cabeçalhos das respostas

O que a Cloudflare manda junto de cada arquivo está em
[`web/public/_headers`](../../web/public/_headers), que o Vite copia para o
`dist/` no build. São duas regras.

A primeira é higiene de quem serve página no navegador, e vale para tudo:
`X-Robots-Tag` para ficar fora dos buscadores, `X-Content-Type-Options`,
`X-Frame-Options` e `Referrer-Policy`.

A segunda é sobre **cache**, e nasceu da mesma medição que gerou o [teto de
peso](#o-peso-do-pacote-tem-um-teto) — as duas coisas se sustentam: guardar o
arquivo para sempre só vale se ele sobreviver ao próximo deploy, e é a
separação descrita lá que faz isso acontecer.

O padrão da Cloudflare para arquivo estático é
`Cache-Control: public, max-age=0, must-revalidate` — o navegador pode guardar,
mas tem de perguntar se ainda vale antes de cada uso. É o padrão certo para uma
página cujo endereço não muda de nome, e errado para tudo que o Vite põe em
`assets/`: esses nomes levam o hash do próprio conteúdo, então **mudou o
arquivo, mudou o nome**. Perguntar se um arquivo assim ainda vale é uma ida e
volta à rede paga à toa, em toda abertura do aplicativo — e numa escola com
internet fraca é exatamente onde o tempo se perde. O `immutable` encerra a
pergunta.

O `index.html` fica de fora de propósito, e é o detalhe que torna a regra
segura: o nome dele **não** muda, e é ele que aponta para os arquivos com hash.
Guardá-lo congelaria o aplicativo numa versão antiga — o navegador continuaria
abrindo o índice velho, que continuaria pedindo os arquivos velhos, e uma
correção publicada nunca chegaria. Pela mesma razão ficam de fora `logo.png` e
`robots.txt`, que moram na raiz com nome fixo.

O efeito só se confere **publicado**: o servidor de desenvolvimento não é a
Cloudflare e não lê este arquivo. A prévia do Pull Request serve para isso —
`curl -I` no endereço da prévia, num arquivo de `assets/`, e o `Cache-Control`
tem de vir com `immutable`.

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

## Publicar o banco e as Edge Functions

A web se publica sozinha a cada merge; o Supabase, não. A assimetria é
proposital em dois pontos e acidental em nenhum: aplicar uma migration é uma
**decisão**, não uma consequência de mergear — migration é imutável, e um
`db push` disparado por engano só se corrige escrevendo a próxima —, e a CI não
tem, nem deve ter, credencial de produção do banco. Quem publica é quem tem a
máquina ligada, olhando o que vai subir.

Confira primeiro o que está fora de sincronia:

```bash
supabase migration list        # lado a lado: o que é local e o que já está no remoto
supabase db push --dry-run     # o que seria aplicado, sem aplicar
supabase db push               # aplica
```

As funções vão em seguida, uma a uma:

```bash
supabase functions deploy generate-document
supabase functions deploy expire-documents
```

**Nenhum segredo a configurar.** O runtime injeta o endereço do projeto e a
chave secreta; `supabase secrets set` não é preciso. O que está em
`supabase/functions/_shared/` sobe junto, porque é importado — não se publica
separado.

A ordem é a do bom senso: mergear, depois publicar. As duas coisas podem ir
antes do merge sem quebrar nada enquanto nenhuma tela chamar a função, mas aí a
`main` deixa de ser o que está no ar, e é ela que se lê para saber o que está.

### O agendamento da limpeza

Os arquivos vencidos só somem se alguém chamar a `expire-documents`, e quem
chama é o [Cron do Supabase](https://supabase.com/docs/guides/cron/quickstart)
— `pg_cron` disparando um `net.http_post` para a função. **Isto não está em
migration**, e não pode estar: precisa da chave secreta, que não entra em
código.

Pelo painel, que é o caminho mais curto porque liga `pg_cron` e `pg_net`
sozinho: *Integrations > Cron > Create job*, nome `expire-documents`,
agendamento `0 6 * * *` — a hora é **UTC**, então isto é três da manhã aqui —,
tipo *Supabase Edge Function*, método POST.

Por SQL dá no mesmo, e o segredo vai para o Vault, nunca para dentro do
`cron.schedule`:

```sql
select vault.create_secret('https://<ref>.supabase.co', 'project_url');
select vault.create_secret('<chave secreta>', 'service_key');

select cron.schedule(
  'expire-documents',
  '0 6 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
           || '/functions/v1/expire-documents',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' ||
        (select decrypted_secret from vault.decrypted_secrets where name = 'service_key')
    )
  );
  $$
);
```

Depois, `select * from cron.job;` mostra o agendamento e
`select * from cron.job_run_details order by start_time desc limit 5;` mostra as
últimas passagens.

**Qual chave vai no cabeçalho.** O projeto tem duas gerações de chave secreta
convivendo: a `service_role` antiga, que é um JWT, e a `sb_secret_…` nova, que é
opaca. A função aceita as duas; quem pode não aceitar é o portão do Supabase,
que valida o `Authorization` **antes** de a função rodar. Chamar a função à mão
resolve a dúvida em dez segundos:

```bash
curl -i -X POST https://<ref>.supabase.co/functions/v1/expire-documents \
  -H "Authorization: Bearer <a chave que vai no agendamento>"
```

Uma resposta `{"removed_files":…}` é a chave certa. Um 401 **no formato de erro
do MAE** chegou à função e a chave está errada; um 401 sem esse corpo foi o
portão, e aí ou se usa a chave antiga, ou se desliga o `verify_jwt` dessa função
no [`config.toml`](../../supabase/config.toml) — o que é seguro, porque o guarda
da chave é da própria função.

### O que vive só no painel

Fora do repositório, e por isso listado aqui: os endereços permitidos do link de
senha nova, o texto dos e-mails, as variáveis da Cloudflare, os segredos do
Vault e o agendamento do Cron. É o inventário do que uma máquina nova não
reconstrói sozinha a partir de um `git clone`.

## O que nunca entra no pacote publicado

Só variáveis com o prefixo `VITE_` chegam ao navegador, e só duas existem: a
URL do projeto e a chave publicável, que é pública por construção e só alcança
o que as políticas de RLS deixarem. A chave secreta — a que ignora as políticas
— não tem nome no painel da Cloudflare, não tem nome nos segredos do GitHub e
não existe em lugar nenhum do que é construído aqui: ela vive apenas no
ambiente das Edge Functions, no Supabase.
