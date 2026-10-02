# Versão mínima do aplicativo

A [decisão 12](decisoes-tecnicas.md#12-trava-de-versão-mínima-desde-a-primeira-versão)
implementada, issue #113. O banco guarda a versão mínima do aplicativo que
aceita, a `save_meal_map` recusa o aplicativo abaixo dela, e o aplicativo
confere sozinho, para de mandar e se atualiza pela release do GitHub, sem
navegador. Ela entra antes do primeiro APK porque um aplicativo instalado só
respeita a trava que já veio com ele.

| Critério da issue | Onde está |
|---|---|
| Migration com a versão mínima, legível por quem estiver logado | [`20261001120000_versao_minima_do_app.sql`](../../supabase/migrations/20261001120000_versao_minima_do_app.sql) — [No banco](#no-banco) |
| O app confere ao abrir e antes da fila; abaixo do mínimo, para de enviar e oferece a atualização, sem perder nada | [`version_gate.dart`](../../app/lib/version/version_gate.dart), [`sync_engine.dart`](../../app/lib/local/sync_engine.dart), [`update_notice.dart`](../../app/lib/version/update_notice.dart) — [No aplicativo](#no-aplicativo) |
| A `save_meal_map` recusa pelo cabeçalho; a web segue como está; pgTAP | `internal.reject_outdated_app`; [`versao-minima.test.sql`](../../supabase/tests/versao-minima.test.sql) — [A recusa](#a-recusa-pelo-cabeçalho) |
| O app baixa a release e chama o instalador, sem navegador | [`release_gateway.dart`](../../app/lib/version/release_gateway.dart), [`app_installer.dart`](../../app/lib/version/app_installer.dart) — [A atualização](#a-atualização) |
| Regra: o APK novo sai antes da migration que sobe o mínimo | [Como subir o mínimo](#como-subir-o-mínimo) |

## Qual número se compara

O número depois do `+` na `version:` do pubspec, o `versionCode` do Android
([a versão](release-e-distribuicao.md#a-versão)). Ele só cresce, de um em um,
e a Action de release recusa a tag em que ele não cresceu. Por isso basta
comparar dois inteiros. O nome (`0.1.0`) é para gente ler e não entra na
conta.

O aplicativo lê o próprio número do APK instalado (`package_info_plus`), não
de uma constante no código: não há um segundo lugar que alguém esqueça de
subir.

## No banco

`public.app_version` tem uma linha só, garantida pela chave
(`singleton boolean primary key check (singleton)`). A trava vale para o
aplicativo, que é o mesmo APK para todas as escolas, e não para uma escola. A
coluna `minimum_build` nasce em **1**, o número do primeiro APK, e não recusa
ninguém.

Quem está logado lê. Ninguém escreve pela API: não há política de escrita, e
os privilégios que o Supabase concede por padrão foram revogados, para que a
ausência de política não seja a única proteção. O mínimo sobe só por
migration.

### A recusa pelo cabeçalho

O aplicativo manda `x-mae-app-build: <versionCode>` em **toda** chamada (os
cabeçalhos globais do `Supabase.initialize`). O PostgREST entrega os
cabeçalhos da requisição ao banco em `request.headers`, e a primeira linha da
`save_meal_map` é `internal.reject_outdated_app()`:

| Cabeçalho | Resultado |
|---|---|
| ausente ou vazio | passa — é a web, que segue como está |
| número ≥ mínimo | passa |
| número < mínimo | recusa |
| ilegível (`abc`, grande demais) | recusa — não vem de nenhum aplicativo que saiu daqui |

A recusa usa o código **`PT426`**, a convenção do PostgREST para escolher o
status HTTP: a resposta sai como **426 Upgrade Required**, e o aplicativo a
reconhece como "atualize", diferente de qualquer recusa do dia. Ela vem
**antes** de qualquer outra conferência, inclusive a de sessão e a de perfil.
Um aplicativo velho que recebesse "só a merendeira registra" acharia que o
problema é a conta.

Conferido pela API local, com o token de uma merendeira do seed e o mínimo
em 1:

```text
x-mae-app-build: 0   → HTTP 426 {"code":"PT426","message":"Esta versão do aplicativo está desatualizada.","details":"Versão mínima: 1.", …}
x-mae-app-build: 1   → segue para a gravação
sem o cabeçalho      → segue para a gravação
```

No aparelho de teste, com uma tabela temporária gravando `request.headers`
dentro da função, o aplicativo de depuração chegou com
`x-mae-app-build: 1` ao lado do `x-client-info` do `supabase_flutter`.

A trava fica só na `save_meal_map`, como a decisão pede. É por ela que entra o
que o aplicativo escreve sem a merendeira ver, pela fila. A manutenção do
catálogo e a geração do documento são pedidas com a tela aberta, e a recusa
que receberem aparece ali mesmo.

## No aplicativo

### A trava

[`VersionGate`](../../app/lib/version/version_gate.dart) compara o versionCode
do APK com o mínimo, e é um só para o aplicativo: a fila consulta e a
tela-casa mostra o mesmo objeto.

- **Ao abrir**: o aviso da tela-casa pergunta o mínimo ao aparecer.
- **Antes da fila**: cada vez que a fila tem o que mandar e há rede, ela
  pergunta antes do primeiro dia. Abaixo do mínimo, não manda nada.
- **Pela recusa do banco**: se o mínimo subiu entre a conferência e o envio,
  o `PT426` põe o aplicativo no mesmo estado, e a fila para no primeiro dia,
  porque os outros receberiam a mesma resposta.

O último mínimo conhecido fica guardado no aparelho
(`shared_preferences`, chave `mae.minimum_build`, uma para o aparelho e não
por perfil). É o que mantém a trava sem rede: aberto em casa, à noite, o
aplicativo já sabe que está velho. Sem rede e sem mínimo conhecido, ele
segue, e a recusa do banco continua de guarda.

### Registra, só não envia

Abaixo do mínimo, **ela continua registrando**. A tela não tranca, por
decisão do autor nesta issue:

- **Nada do aplicativo velho chega ao banco.** A fila não tenta, e a
  `save_meal_map` recusaria se tentasse.
- **O que ela registra fica na fila, intocado.** Não é recusa, que tiraria o
  dia da fila, nem falha, que contaria tentativa. O aplicativo novo abre o
  mesmo banco local, e é ele quem manda, já com a migração do esquema local
  que a versão nova trouxer.
- **Trancar a tela pesaria no caso que o produto existe para resolver.** Ela
  vê o pedido de atualização na escola, com rede, e deixa para depois (são
  64 MB, talvez no plano de dados dela). À noite, em casa e sem rede, uma
  tela trancada a deixaria sem registrar e sem ter como atualizar. A recusa do
  banco já protege tudo o que a tela trancada protegeria.

A faixa do dia ganha um quarto estado, porque a frase de sempre ("Envia
sozinho quando houver internet") seria falsa: com internet também não sobe.

| Estado | Faixa do dia |
|---|---|
| abaixo do mínimo | Salvo no aparelho. Vai para a nuvem depois que você atualizar o MAE. |

### O aviso na tela-casa

No alto da visão do mês, acima do aviso de documento pronto, **sem X para
dispensar**: enquanto ele estiver ali, nada vai para a nuvem.

> **Atualize o MAE**
> Seus registros ficam salvos no aparelho e vão para a nuvem depois da
> atualização.
> [Atualizar]

Usa as cores de aviso (`warning`), as mesmas da faixa "ainda não deu para
enviar". O aviso e o quarto estado da faixa entraram no
[catálogo de avisos](../03-ux/avisos-e-mensagens.md) e nas artboards
"Avisos · Ao abrir o app" e "Avisos · Na tela" do canvas. O texto segue o [vocabulário dela](../03-ux/avisos-e-mensagens.md#as-três-regras-da-linguagem):
diz primeiro o que não se perdeu, fala em "nuvem" e não em "servidor", e não
explica versão mínima.

## A atualização

Tocar em **Atualizar**:

1. Pergunta à API do GitHub pela release mais recente
   (`/repos/rds-renan/mapa-alimentacao-escolar/releases/latest`) e pega o
   `.apk` anexado. `latest` deixa de fora as pré-releases, então uma tag de
   ensaio nunca chega a um aparelho por aqui. O repositório é público: a
   pergunta não leva credencial, e o limite de sessenta por hora por endereço
   sobra.
2. Baixa o arquivo com o [`ota_update`](https://pub.dev/packages/ota_update)
   para a pasta interna do aplicativo, mostrando quanto já veio.
3. Confere a impressão digital SHA-256 que o GitHub informa para o arquivo
   anexado (`digest`). Arquivo que chegou com defeito não vai para o
   instalador.
4. Abre o instalador do Android. Na primeira vez, o Android pede que ela
   permita ao MAE instalar aplicativos: é o mesmo **Permitir desta fonte** da
   [primeira instalação](release-e-distribuicao.md#a-primeira-instalação), agora
   para o MAE em vez do WhatsApp.
5. O Android substitui o aplicativo, que reabre na versão nova. O banco local
   continua onde estava, porque a assinatura é a mesma e atualizar não é
   desinstalar.

| O que deu errado | O que ela lê |
|---|---|
| sem internet, ou a release não respondeu | Não deu para baixar agora. Confira a internet e tente de novo. |
| o arquivo chegou diferente do publicado | O arquivo chegou com defeito. Tente de novo. |
| o aparelho não deixou instalar | O aparelho não deixou instalar. Toque em Atualizar e, se ele pedir, permita que o MAE instale aplicativos. |
| o instalador abriu | Siga as instruções na tela para instalar. Se elas não apareceram, toque em Atualizar de novo. |

### O que mudou no Android

- **`REQUEST_INSTALL_PACKAGES`** no manifesto principal: sem ela, o Android
  não oferece a instalação.
- **O `FileProvider` do `ota_update`**, com
  [`ota_update_paths.xml`](../../app/android/app/src/main/res/xml/ota_update_paths.xml)
  expondo só a pasta para onde o APK é baixado.
- **Permissões que o plugin traz e não servem aqui, removidas** com
  `tools:node="remove"`: escrita e leitura do armazenamento compartilhado (o
  arquivo vai para a pasta interna), `INSTALL_PACKAGES` (instalação silenciosa,
  só de aplicativo de sistema) e o estado do Wi-Fi. Permissão a mais é
  pergunta a mais na tela da instalação. O APK de release ficou com:

  ```text
  uses-permission: name='android.permission.INTERNET'
  uses-permission: name='android.permission.REQUEST_INSTALL_PACKAGES'
  uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
  ```

- **Core library desugaring** no Gradle, que o `ota_update` exige do
  aplicativo, na mesma versão de `desugar_jdk_libs` que ele declara.

## Como subir o mínimo

**O APK novo sai antes da migration que sobe o mínimo.** O contrário tranca
todo mundo para fora: o mínimo sobe, o aplicativo de todas pede atualização,
e a release mais recente ainda é a velha.

1. Faça a release da versão nova
   ([como fazer uma release](release-e-distribuicao.md#como-fazer-uma-release))
   e confira que ela aparece em `/releases/latest` com o APK anexado.
2. Só então, num PR, a migration que sobe o mínimo para o número dessa
   versão:

   ```sql
   -- O APK 0.3.0+4 está publicado em app-v0.3.0. A partir daqui, a
   -- save_meal_map passa a gravar <o que mudou>, que o aplicativo
   -- anterior não manda.
   update public.app_version set minimum_build = 4, updated_at = now();
   ```

3. No mesmo PR, ou depois dele, a mudança de contrato que motivou a subida.

Subir o mínimo só faz sentido quando o aplicativo antigo deixou de funcionar
com o banco. Versão nova que só melhora a tela não sobe o mínimo, e as
merendeiras atualizam quando receberem o arquivo. Um aviso "leve" de versão
nova, sem trava, foi descartado na decisão 12.

## Testes

- **pgTAP**, [`versao-minima.test.sql`](../../supabase/tests/versao-minima.test.sql),
  16 cenários: a linha única, quem lê e quem não escreve, a recusa abaixo do
  mínimo sem gravar nada, no mínimo e acima gravam, a web sem cabeçalho,
  cabeçalho ilegível e vazio, e a recusa da versão antes da de perfil e da de
  sessão.
- **Unidade e widget**, em `app/test/version/` e no
  [`sync_engine_test.dart`](../../app/test/local/sync_engine_test.dart): a
  conferência, o último mínimo conhecido sem rede, a fila que não manda e
  deixa o dia intocado, o `PT426` no meio da fila, a leitura da release, o
  andamento da atualização e o aviso na tela-casa.
- **No aparelho** (Samsung A52, aplicativo de depuração contra o Supabase
  local com o mínimo subido para 2): o aviso aparece ao abrir, a faixa do dia
  diz "Vai para a nuvem depois que você atualizar o MAE", e "Atualizar", sem
  release publicada ainda, mostra "Não deu para baixar agora". Com o mínimo de
  volta a 1, o aviso some na abertura seguinte e o dia sobe.

**Não conferido ainda**: o download e a instalação de verdade. Eles dependem
de uma release publicada assinada com a mesma chave do aplicativo instalado,
e a primeira (`app-v0.1.0`) sai depois desta issue. Roteiro para quando ela
existir:

1. Instalar o APK da release `app-v0.1.0` no aparelho de teste.
2. Compilar localmente, com `env/local.json` e a chave de release
   (`key.properties`), o mesmo `0.1.0+1`, e instalar por cima.
3. No Supabase local, subir o mínimo para 2.
4. Abrir, tocar em "Atualizar" e acompanhar o download, a permissão do
   Android e a instalação da release por cima. O Android aceita reinstalar o
   mesmo versionCode.
5. Voltar o mínimo para 1.
