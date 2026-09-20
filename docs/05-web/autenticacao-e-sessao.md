# Autenticação, sessão e rotas por perfil

A porta de entrada do MAE: a [tela 1 da E3](../03-ux/telas.md), a sessão que
sobrevive ao fechar do navegador e o roteamento que separa o fluxo da merendeira
das telas da direção. É a issue #59, e o código mora em
[`web/src/auth/`](../../web/src/auth/) e [`web/src/pages/`](../../web/src/pages/).

## A guarda de rota não é a segurança

Vale repetir o que a [decisão 6](decisoes-tecnicas.md) já dizia, porque é a
coisa mais fácil de esquecer ao ler este código: **esconder a administração de
quem é merendeira é cortesia de interface**. Quem impede a leitura e a escrita
são as políticas de RLS da E4, no banco, onde ninguém contorna abrindo o
DevTools. Se um dia a guarda falhar, a pessoa vê uma tela vazia — não os dados
de outro perfil.

Foi por levar isso a sério que a etapa foi conferir se a tal política segurava
de verdade — e ela não segurava para o perfil: a merendeira conseguia virar
administradora editando a própria linha. Está fechado, e o caso inteiro está na
[decisão 2 da E4](../04-banco-de-dados/decisoes-de-modelagem.md), com os
cenários em `supabase/tests/perfis-e-acessos.test.sql`.

| Rota | Quem alcança | Tela |
|---|---|---|
| `/entrar` | qualquer pessoa | Login (tela 1 da E3) |
| `/esqueci-a-senha` | qualquer pessoa | Pedido de senha nova |
| `/nova-senha` | quem chegou pelo link do e-mail | Criar a senha nova |
| `/` | merendeira | Visão do mês (issue #61) |
| `/admin` | direção | Painel (issue #70) |

Os caminhos ficam em português porque aparecem na barra de endereço: são texto
de interface, e a fronteira da [decisão 13 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)
põe o inglês nos identificadores e o português no que a merendeira lê. Endereço
desconhecido cai na casa de quem está logada; quem não está logada cai no login,
e volta ao endereço que tentou abrir depois de entrar.

## A sessão sobrevive ao navegador

É o RNF#2 da US016 — ela não redigita senha no dia a dia —, e é o que torna o
uso real possível: o preenchimento acontece em casa, à noite, no celular.

O cliente guarda a sessão no aparelho e renova o token sozinho. A chave de
armazenamento é nossa (`mae.auth`) e não a padrão da biblioteca, que deriva do
endereço do projeto: no dia em que o projeto mudasse de endereço, a sessão de
todo mundo sumiria em silêncio.

Ao abrir o aplicativo, a sessão guardada chega pela própria inscrição em
mudanças de autenticação — e é por isso que existe uma tela de espera curta
antes da primeira: sem ela, o login piscaria na frente de quem já está logada.

## O perfil, e o que fazer quando ele não vem

Saber o papel exige uma leitura a mais, na tabela `profile`. Ela tem dois
desfechos ruins, e eles pedem coisas opostas:

- **A linha não aparece.** O acesso foi desativado pela direção (CA#2 da US016)
  e a política de RLS deixou de enxergá-la. Não há aplicativo nenhum para
  mostrar: a sessão é encerrada e o login explica o que houve.
- **A leitura falhou.** Quase sempre é falta de rede. Aqui a sessão é
  **mantida** de propósito e a tela oferece tentar de novo. Deslogar quem está
  sem sinal numa escola sem sinal de operadora seria transformar instabilidade
  de rede em perda de acesso.

Confundir os dois é o erro caro, e é por isso que estão escritos separados.

## Sair apaga o que era da pessoa

Sair encerra a sessão e apaga o que ficou no aparelho. A distinção que o código
faz é entre **o que é da pessoa** e **o que é do aparelho**: o rascunho e a fila
(que chegam na issue #60) são da pessoa, e as duas merendeiras se revezam no
mesmo aparelho — o rascunho de uma não pode aparecer para a outra. A preferência
de tema (US024) é do aparelho e não se toca: sair da conta não muda o aparelho.

Se a revogação no servidor não for possível — sem rede, que é o comum aqui —, a
sessão sai do aparelho do mesmo jeito. Ficar preso dentro do aplicativo por
falta de internet seria o pior desfecho.

**Resolvido na issue #60**, e não como esta seção previa. Apagar continua sendo
apagar tudo, inclusive o dia que não subiu — guardar mapa na web depois da saída
custaria mais do que salva, porque aqui ele pode ficar meses esperando alguém
que talvez não volte. O que entrou foi o aviso: quem tem mapa por enviar é
avisada antes e decide. O porquê está na [camada local](camada-local.md).

## O erro de login não diz qual campo errou

"E-mail ou senha não conferem. Confira e tente de novo." — o texto é o do
[catálogo de avisos da E3](../03-ux/avisos-e-mensagens.md), e os **dois** campos
são marcados juntos: marcar só um diria qual é o certo. Só a direção cria
acesso, e apontar o campo certo ajudaria justamente quem não deveria entrar.

## O formulário, antes de o servidor entrar na conversa

Três coisas acontecem na tela, sem rede nenhuma:

- **O e-mail é conferido na forma** — alguma coisa, arroba, domínio e ponto —,
  ao sair do campo e de novo ao enviar. Torto, o **campo fica marcado**, a
  mensagem aparece nele e o envio **não acontece**: mandar ao servidor o que já
  se sabe que não é e-mail traria de volta o erro de senha, que não é o
  problema, e ainda contaria como tentativa errada no freio. O foco volta para
  o campo, que é o que se espera de um formulário que recusou alguma coisa.
  A conferência é no `onBlur` e não a cada tecla: ninguém quer ser corrigido no
  meio da digitação de um e-mail que ainda não terminou.

  Este é o único erro que aponta **um** campo, e pode: nenhum servidor foi
  consultado, então dizer qual está torto não entrega nada a ninguém. E ele
  nunca convive com a resposta do servidor — mexer no e-mail apaga a mensagem
  anterior, para que a tela tenha uma mensagem só, sempre. O que a regra impede
  é o engano de digitação; recusar quem entra não é trabalho de uma expressão
  regular, que nunca prova que um endereço existe.
- **A senha tem o olho de mostrar**, num botão dentro do campo, com nome
  acessível que diz a ação e estado que o leitor de tela anuncia. Ela nasce
  escondida.
- **A senha nova tem oito caracteres no mínimo**, e nenhuma exigência de
  maiúscula, número ou símbolo. É a orientação atual de segurança, e é também
  a prática: regra de composição produz a senha de sempre com `1!` no fim,
  anotada num papel do lado do fogão. O que barra senha ruim de verdade é a
  checagem de senha vazada, que se liga no painel do projeto na nuvem.

## Tentar senha em série fica caro

Cinco erros seguidos e o formulário espera um minuto; mais cinco, cinco
minutos; daí em diante, quinze. A contagem vive no navegador e o tempo que
falta é recontado do relógio, então recarregar a página não zera a espera.

**Isto não é o que barra um ataque** — mora no navegador, e quem quiser burlar
limpa o armazenamento. É freio de interface, e existe por um motivo legítimo:
quem errou cinco vezes não vai acertar na sexta, e insistir depressa só piora,
para a pessoa e para o servidor. O código está em
[`web/src/auth/sign-in-throttle.ts`](../../web/src/auth/sign-in-throttle.ts),
com um teste para cada degrau da escalada.

Falha de rede **não** conta para o freio: não é tentativa de adivinhar senha, e
trancar quem está sem sinal seria punir o lugar em que este aplicativo vive.

## A guarda contra robôs

O desafio é o Turnstile, da Cloudflare — a mesma casa que já hospeda a web. Ele
resolve sozinho na maioria das vezes, sem pedir nada a quem está do outro lado:
a ideia não é pôr mais um obstáculo entre a merendeira e o aplicativo, e sim
entre o aplicativo e quem tenta senha em série.

Ele é **ligado por configuração, não por código**: a web só mostra o desafio
quando existe `VITE_TURNSTILE_SITE_KEY`, e o servidor só passa a exigi-lo quando
`[auth.captcha]` estiver ligado no projeto da nuvem, com a chave secreta do par.
Em desenvolvimento e nos testes não há chave, não há desafio e nada depende de
serviço de terceiro. O código do desafio vale uma vez só, então o widget é
remontado a cada recusa.

Se o desafio não carregar — rede ruim, bloqueador, serviço fora do ar —, o login
é tentado assim mesmo e quem decide é o servidor. Trancar a porta do lado de cá
transformaria um problema do desafio em perda de acesso.

## O que o Supabase já faz, e o que ele não faz

Vale ter isto escrito, porque muda o que ainda precisa ser feito à mão:

| Ele faz | Ele não faz |
|---|---|
| Guarda a senha com hash (`bcrypt`); ela nunca trafega nem repousa em claro | Trancar a conta depois de N erros — não existe bloqueio por usuária |
| Limita tentativas **por endereço de rede**: 30 logins a cada 5 minutos, 2 e-mails por hora | Distinguir a merendeira do robô sem o desafio ligado |
| Recusa senha curta e, no painel da nuvem, senha que já vazou | Dizer qual campo errou — e isso é proposital, aqui e lá |
| Expira o token em 1 hora e rotaciona o de renovação, com janela de reuso | Exigir segundo fator (existe no produto, fora de escopo aqui) |
| Responde igual para e-mail conhecido e desconhecido no pedido de senha | — |

O limite por endereço de rede é o que de fato segura uma tentativa em série, e
ele é do servidor — não há como contorná-lo pelo navegador. O freio da tela e o
desafio existem em volta dele, não no lugar dele.

## Fora dos buscadores

O MAE é inteiramente atrás de login, serve a uma escola só e não tem nada a
indexar. São três camadas dizendo a mesma coisa, para quem lê cada uma:
a meta tag em [`web/index.html`](../../web/index.html), o
[`robots.txt`](../../web/public/robots.txt) e o cabeçalho `X-Robots-Tag` em
[`_headers`](../../web/public/_headers), que a Cloudflare lê ao servir os
arquivos. O mesmo arquivo carrega três cabeçalhos de higiene: tipo de arquivo
não se adivinha, a página não se embute em site de terceiro e o endereço não
vaza ao sair dele.

Nada disso é proteção: quem protege é o login e as políticas no banco. É o
pedido de que o endereço não apareça em busca — e ele vale para quem respeita o
pedido.

## A senha esquecida: um requisito descoberto na codificação

O link "Esqueci minha senha" está na tela 1 desde a E3, e **nenhuma história o
descrevia**. A US016 fala de criar e desativar acessos; nada dizia o que
acontece quando a merendeira esquece a senha — e a tela, ao ser implementada,
cobrou a resposta.

Fica registrado aqui pelo mesmo critério que a E3 usou com o Menu e os
Documentos gerados, na seção ["Telas que não vieram do levantamento"](../03-ux/fluxo-de-telas.md):
requisito que não nasceu da entrevista nem do desenho, mas da etapa em que
alguém tentou percorrer o fluxo inteiro — desta vez a codificação. **Origem
declarada, na etapa em que apareceu**, sem reescrever a história para parecer
que sempre esteve lá e sem empurrá-lo para a etapa de testes, onde não foi
encontrado.

Na revisão da documentação, ele vira história no backlog (ou critério novo da
US016) e as duas telas entram no desenho da E3. Até lá, o desenho e o código não
divergem no que existe: o link da tela 1 é o mesmo, e o que ele abre é o que
está descrito aqui.

Como funciona:

1. O pedido leva só o e-mail, e a resposta é **a mesma** para e-mail conhecido e
   desconhecido — pelo mesmo motivo do erro de login: dizer "este e-mail não tem
   acesso" entregaria quem tem.
2. O e-mail chega em português, do modelo em
   [`supabase/templates/senha-nova.html`](../../supabase/templates/senha-nova.html),
   e o link vale por uma hora.
3. O link devolve a pessoa em `/nova-senha` já autenticada, e ali ela cria a
   senha. São dois campos, e não um: um erro de digitação num campo escondido
   trancaria para fora do acesso que ela acabou de recuperar.
4. Trocada a senha, **as outras sessões caem** — a desta aba fica. Pedir senha
   nova quase sempre quer dizer "perdi o acesso", e o que não pode acontecer é
   o acesso antigo seguir aberto em outro aparelho depois de a senha mudar. O
   que cai na hora é a renovação; o token que já estava em uso vale até expirar,
   no máximo uma hora (`jwt_expiry`).

### Duas abas, uma sessão só

Isto apareceu em uso, e é o tipo de coisa que nenhum teste de tela teria pego
sozinho: a pessoa pede a senha nova numa aba, abre o link do e-mail em outra,
cria a senha — e **a primeira aba também vira uma tela de trocar senha**,
aceitando trocar de novo a senha recém-criada.

O culpado não é o link. Conferido contra o servidor: o link é de uso único, e
abri-lo pela segunda vez responde `otp_expired`. O que é compartilhado é a
**sessão** — ela vive no armazenamento do navegador, que é o mesmo para todas
as abas, e o aviso de "entrou para trocar a senha" viaja junto. A segunda aba
não estava usando o link de novo: estava usando a sessão que o link criou.

O conserto trata a recuperação como **fato da aba**, e não como estado da
conta: [`web/src/lib/recovery-link.ts`](../../web/src/lib/recovery-link.ts)
pergunta, no carregamento, se foi **este** endereço que trouxe o código do
e-mail — antes de o cliente do Supabase consumir e limpar o endereço. A tela da
senha nova exige essa resposta, e não basta estar logada para alcançá-la. A aba
que só pediu o e-mail continua onde estava.

O fluxo é o **implícito**, e não o PKCE. O PKCE exige que o link do e-mail seja
aberto no mesmo navegador que o pediu, e o caminho comum aqui é pedir no
navegador e abrir o e-mail no aplicativo do celular — que abre outro navegador.
O PKCE falharia justamente no caminho mais provável.

## Duas armadilhas do ambiente, encontradas ao subir a tela

Nenhuma das duas aparece em código: as duas apareceram na primeira tentativa de
entrar de verdade, e as duas fazem o login falhar por inteiro.

**O provedor de e-mail estava desligado.** O `enable_signup = false` em
`[auth.email]` parece dizer "sem autocadastro por e-mail", mas vira
`GOTRUE_EXTERNAL_EMAIL_ENABLED=false` no servidor de autenticação — o
interruptor do provedor **inteiro**. Com ele desligado, ninguém entra com e-mail
e senha, nem as contas que a direção criou. Quem barra o cadastro é o
`enable_signup = false` de `[auth]`, e ele sozinho basta: o autocadastro
responde `signup_disabled` mesmo com o provedor ligado.

**As contas do seed não conseguiam entrar.** Quatro colunas de token em
`auth.users` (`confirmation_token`, `recovery_token`, `email_change`,
`email_change_token_new`) não têm padrão e ficavam nulas nos usuários inseridos
à mão. O servidor de autenticação as lê em campos de texto que não aceitam nulo
e derruba o login com `Database error querying schema` — erro que parece de
banco e é do seed. Entram como texto vazio.

## O que chega ao pacote publicado

Ao navegador vão apenas `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY`,
que é pública por construção e só tem o poder que as políticas de RLS lhe derem.
A chave secreta vive somente no ambiente das Edge Functions.

Isso deixou de ser promessa e virou passo:
[`web/scripts/conferir-segredos-do-pacote.mjs`](../../web/scripts/conferir-segredos-do-pacote.mjs)
varre o `dist/` atrás de chave secreta, chave de serviço e chave privada, e a
[CI](integracao-continua-e-publicacao.md) o roda depois do build.

## Conferindo na sua máquina

```bash
supabase start          # na raiz do repositório
cd web && npm run dev
```

As contas do seed estão em [`supabase/seed.sql`](../../supabase/seed.sql) —
direção e duas merendeiras, todas com a senha `mae-desenvolvimento`. O e-mail de
senha nova não sai para a internet em desenvolvimento: ele cai na caixa local,
em <http://127.0.0.1:54324>.

## No projeto da nuvem

Duas coisas que o `config.toml` resolve no local e que **não** viajam sozinhas:

- **Authentication > URL Configuration**: o endereço da web e os destinos
  permitidos do link de senha nova. O que não estiver na lista é recusado — é
  ela que impede que um link do MAE leve para fora do MAE.
- **Authentication > Emails**: o texto do e-mail de senha nova. Sem isso, ele
  sai no padrão do Supabase, em inglês.

E mais três, que são de segurança e não de idioma:

- **A guarda contra robôs**: criar o par de chaves do Turnstile no painel da
  Cloudflare, pôr a pública em `VITE_TURNSTILE_SITE_KEY` no Worker e a secreta
  no Supabase, com `[auth.captcha]` ligado.
- **A checagem de senha vazada**, em *Authentication > Providers > Email* — é
  ela que recusa a senha que já apareceu em vazamento conhecido.
- **Conferir os limites por endereço de rede** em *Authentication > Rate
  Limits*: o padrão de 2 e-mails por hora vale para o pedido de senha nova, e
  numa escola com duas merendeiras isso é folgado — mas é bom saber antes de
  alguém achar que o e-mail sumiu.

## O que ficou de fora, e onde continua

- **As telas do desenho** — o pedido de senha nova e a senha nova entram na E3
  na revisão da documentação, junto com a história que as descreve.
- **`profile.last_access`** — **resolvido na issue #68**: quem carimba é
  `public.touch_last_access()`, chamada a cada abertura do aplicativo, logo
  depois de o perfil chegar. O porquê de não ser no login está em
  [a administração da escola](administracao.md#o-último-acesso).
- **A tela-casa de cada perfil** — o que está em `/` e `/admin` hoje é só o
  destino das guardas: a visão do mês é a issue #61 e o painel, a #70. A casa
  da merendeira chegou na #61; a da direção continua sendo uma tela-marco, com
  a barra lateral da #68 já em volta dela.
