# Autenticação, sessão e senha nova pelo código

A porta de entrada do aplicativo: a [tela 1 da E3](../03-ux/telas.md) — a
mesma da web —, a sessão que sobrevive ao fechar do aplicativo e a troca de
senha por código de 6 dígitos, em vez de link. É a issue #101, decisão 9 da
E6, e o código mora em [`app/lib/auth/`](../../app/lib/auth/),
[`app/lib/pages/`](../../app/lib/pages/) e
[`app/lib/routing/`](../../app/lib/routing/).

O que segue registra só o que diverge, ou o que o aplicativo acrescenta, em
relação a [autenticação e sessão da web](../05-web/autenticacao-e-sessao.md)
— ler lá primeiro é o que evita reconstruir de memória o que já está escrito.

## A guarda de rota não é a segurança, aqui também

A decisão 5 da E6 repete a mesma coisa que a decisão 6 da E5 já dizia:
esconder telas de quem não é merendeira é cortesia de interface. Quem
impede a leitura e a escrita são as políticas de RLS da E4, no banco — um
aplicativo instalado é, se alguma coisa, mais fácil de inspecionar que uma
página. O `redirect` do `go_router`
([`app/lib/routing/app_router.dart`](../../app/lib/routing/app_router.dart))
cumpre o que a decisão 5 pede: sem sessão, toda rota leva ao login; com
sessão de merendeira, a casa é `/` — a [visão do mês e o
menu](visao-do-mes-e-menu.md), issue #104.

## A sessão sobrevive ao aplicativo, em cofre — não em preferências comuns

É o RNF#2 da US016, igual à web. A diferença é o lugar: o aplicativo guarda a
sessão com `flutter_secure_storage`
([`app/lib/auth/secure_session_storage.dart`](../../app/lib/auth/secure_session_storage.dart)),
que no Android cifra o valor (AES-GCM, chave protegida pelo Keystore) — não
um arquivo de preferências comum, que qualquer um com acesso ao aparelho
lê em texto puro. A chave de armazenamento é nossa (`mae.session`), pelo
mesmo motivo da web: não depender do endereço do projeto Supabase, que se
mudasse faria a sessão de quem já tinha o aplicativo instalado sumir em
silêncio.

## O perfil, e os dois desfechos ruins — mais um terceiro

A leitura de `profile` tem os mesmos dois desfechos que a web já documentou
(a linha não aparece → sessão encerrada e explicada; a leitura falha → sessão
mantida, tela oferece tentar de novo). O aplicativo soma um terceiro,
específico dele:

- **O perfil é de direção.** O aplicativo é só da merendeira (decisão 1 da
  E6): quem entra com uma conta de direção é derrubada no mesmo instante,
  como se a conta estivesse desativada, e o aviso aponta para a web em vez
  de "fale com a direção" — é justamente ela quem está do outro lado. Os
  dois casos (conta desativada, conta de direção) passam pelo mesmo caminho
  em [`AuthController._loadProfile`](../../app/lib/auth/auth_controller.dart):
  derruba a sessão e escreve o aviso, sem tela própria — o login de volta já
  é o destino de qualquer sessão encerrada.

## Sair apaga o que é do aparelho, não o que é da pessoa

Mesma distinção da web (issue #60): sair não pode apagar o dia que ainda não
subiu. O banco local (issue #102) e a fila (issue #103) já existem, e a
resposta ficou mais simples do que a da web: como cada perfil tem o próprio
arquivo Drift (decisão 6 da E6), deslogar não abre nem toca esse arquivo —
só para de usá-lo. O que não subiu continua lá até o próximo login confirmar,
sem precisar de um passo de limpeza que decida o que preservar. A regra
segue escrita em
[`AuthController.signOut`](../../app/lib/auth/auth_controller.dart): nenhuma
limpeza de dado entra ali. É a cerca que impede a próxima issue de somar um
`clearLocalData()` sem perceber que a decisão já foi tomada — ver
[fila de envio e convergência](fila-de-envio-e-convergencia.md).

## `touch_last_access()` a cada abertura

Carimbado depois que o perfil chega — não no login — pelo mesmo motivo da
[administração da escola](../05-web/administracao.md#o-último-acesso): a
sessão sobrevive ao fechar do aplicativo, então a merendeira pode passar
meses sem digitar senha, e "último acesso há três meses" faria a direção
desativar quem trabalha todo dia. Sem `await` de erro tratado — é um
carimbo, não passo do caminho; se a rede não estiver lá, o aplicativo abre
igual.

## "Esqueci minha senha": o código, não o link

Nada do que é conta abre o navegador (decisão 9 da E6). A tela
([`app/lib/pages/forgot_password_page.dart`](../../app/lib/pages/forgot_password_page.dart))
é uma só, em dois passos:

1. **O e-mail**, com a mesma resposta para conhecido e desconhecido do
   login — dizer que ele não tem acesso entregaria quem tem.
2. **O código de 6 dígitos e a senha nova**, na mesma tela, assim que o
   código sai. Confirmado, os dois viram uma chamada de sequência:
   `auth.verifyOTP(type: recovery)` troca o código pela sessão, e
   `auth.updateUser(password: …)` grava a senha nova. As outras sessões caem
   (`signOut(scope: others)`) — a desta fica, e vira a sessão normal do
   aplicativo: o mesmo pipeline de `_loadProfile` decide se ela pode
   continuar (o código não pula a checagem de conta desativada ou de
   direção).

**O convite da direção é o mesmo caminho.** A conta nasce na web
(`create-access`, [administração](../05-web/administracao.md)) com senha
descartada, e quem define a senha de verdade é esta mesma tela — pedir o
código é pedir a primeira senha e a senha nova com o mesmo gesto.

Testado contra o Supabase local, de ponta a ponta, pela API (sem passar pelo
aplicativo): `POST /auth/v1/recover` → o código chegou no Mailpit dentro do
modelo novo → `POST /auth/v1/verify` com `type=recovery` devolveu uma sessão
válida. O caminho que o `AuthGateway` implementa é este mesmo, com o cliente
Dart no lugar do `curl`.

## O modelo de e-mail ganhou uma segunda porta

[`supabase/templates/senha-nova.html`](../../supabase/templates/senha-nova.html)
continua sendo o e-mail da web (o botão, `{{ .ConfirmationURL }}`), com o
código do aplicativo somado por cima: `{{ .Token }}`, o mesmo OTP de 6
dígitos que `otp_length` já configurava — o Supabase o gera para toda
recuperação de senha, o aplicativo só passou a ler o que já existia. Um
modelo só, porque as duas plataformas disparam a mesma chamada
(`resetPasswordForEmail` / `auth.recover`).

`additional_redirect_urls`, no `config.toml`, ganhou
`http://10.0.2.2:5173/**` — o endereço do `npm run dev` do host, visto de
dentro do emulador Android —, porque é para lá que o `redirectTo` do
aplicativo aponta (`${WEB_URL}/nova-senha`, em
[`supabase_auth_gateway.dart`](../../app/lib/auth/supabase_auth_gateway.dart)).
O aplicativo nunca abre esse link, mas o e-mail é o mesmo dos dois lugares:
se alguém abrir o link sem querer — ou pela web, como plano B —, ele precisa
continuar levando a algum lugar que funcione.

**No projeto da nuvem**: o texto de *Authentication > Emails* de lá tinha
sido colado antes desta issue existir ([ambiente de
produção](../05-web/autenticacao-e-sessao.md#no-projeto-da-nuvem)), só com o
link. O modelo novo, com o código, foi colado por cima — o `config.toml` não
viaja sozinho para lá, e a cada mudança em
`supabase/templates/senha-nova.html` o painel precisa ser atualizado à mão.

## O que o aplicativo não tem, e por quê

- **Turnstile.** É um desafio pensado para uma página na web, contra a
  Cloudflare que hospeda a web — não faz sentido dentro de um aplicativo
  instalado, e nenhuma issue da E6 pediu um equivalente.
- **O freio de tentativas em série** que a web tem
  (`sign-in-throttle.ts`, issue #59) não entrou aqui: não é um dos critérios
  da issue #101, e o limite que de fato segura uma tentativa em série
  continua sendo o do servidor (`auth.rate_limit`, por endereço de rede) —
  o freio da web é só uma cortesia de interface por cima dele. Fica anotado
  para entrar se um dia virar dor de verdade.

## Testado

`flutter analyze`, `dart format --set-exit-if-changed` e `flutter test` (o
`AuthController` com um `AuthGateway` falso — decisão 4 da E6 — e as duas
telas, incluindo o redirecionamento do `go_router` pelos três desfechos:
sem sessão, merendeira, direção). `flutter build apk --debug` compila. O
código de recuperação foi conferido de ponta a ponta contra o Supabase
local, como a seção acima descreve.

**Não testado ainda num aparelho físico**: o desenho das duas telas segue os
tokens da E3, mas a verificação à mão que a decisão 13 da E6 pede — igual à
que a fundação (issue #99) já fez — fica para antes do primeiro APK
distribuído (issue #112).
