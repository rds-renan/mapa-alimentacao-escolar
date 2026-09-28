# A fila de envio e a convergência

O CA#2 e o CA#3 da US010, e a US011 inteira, virando código: cada alteração
de campo é gravada no aparelho **imediatamente**, sem botão "salvar", e o
envio é uma tentativa que se repete sozinha até o servidor confirmar. É a
issue #103, decisão 8 da E6, e o código mora em
[`app/lib/local/`](../../app/lib/local/).

Ela é a versão em Dart de [`web/src/local/`](../../web/src/local/) — mesmo
contrato de [`save_meal_map`](../05-web/gravacao-do-dia.md), mesma unidade (o
dia inteiro), mesma regra de convergência (prevalece a edição mais recente, e
o caso é sinalizado, nunca resolvido calado). O que muda é o que a plataforma
já resolve por conta própria, e é isso que este documento registra.

## O que já não precisa existir aqui

- **Não há coluna de usuária.** A web guarda um depósito só, e toda leitura
  da fila é por usuária, porque o navegador não separa arquivo por conta. O
  aplicativo já separa — um arquivo Drift por perfil (decisão 6 da E6) — então
  a chave da fila é só a data do dia. Trocar de sessão troca de arquivo, e o
  rascunho de uma merendeira nunca chega perto do banco da outra.
- **Sair não apaga a fila.** A web apaga o que não subiu ao sair da conta,
  porque lá é uso raro e o custo de guardar indefinidamente é alto (["Sair
  apaga tudo, e quem decide é ela"](../05-web/camada-local.md#sair-apaga-tudo-e-quem-decide-é-ela)).
  Aqui não existe esse botão: `AuthController.signOut` nunca tocou o
  banco local (nem vai — [autenticação e sessão](autenticacao-e-sessao.md)) e,
  como o arquivo é por perfil, deslogar simplesmente para de abri-lo. O
  rascunho continua no aparelho até o próximo login confirmar ou até ela
  desinstalar — que é exatamente o que a RN#1 da US011 pede, sem precisar de
  código para isso.

## A peça que a decisão 14 da E6 deixou em aberto: `connectivity_plus`

A decisão 8 da E6 diz que a fila tenta "ao abrir, quando a conexão volta e a
cada dia que ela altera" — e a decisão 14 deixou para esta issue escolher se
"quando a conexão volta" precisa de um pacote, ou se basta tentar e falhar.

Escolhido o pacote
([`connectivity_plus`](https://pub.dev/packages/connectivity_plus)), atrás de
[`ConnectivityGateway`](../../app/lib/local/connectivity_gateway.dart) — o
mesmo formato de portão substituível dos outros gateways (decisão 4 da E6).
Só tentar e falhar custaria caro na escola sem sinal de operadora: sem
detecção, a única forma de saber que a rede voltou seria um temporizador
batendo à toa em loop, ou esperar a próxima abertura do aplicativo — e ela
pode ficar com o aplicativo aberto no colo enquanto anda pela escola atrás de
sinal. `onConnectivityChanged` avisa no instante em que ele volta.

Ela é o "não se resolve à cegas": mesmo raciocínio de `canBeSent` — evitar a
tentativa que já se sabe perdida. `AppLifecycleListener.onResume` cobre o que
a mudança de conectividade pode perder em segundo plano, o mesmo papel do
`visibilitychange` da web.

## A mesma fila, sobre Drift

`PendingMealMaps` (em
[`app_database.dart`](../../app/lib/local/app_database.dart)) é o
`web/src/local/store.ts` em forma de tabela: uma linha por dia ainda não
confirmado, com o próprio [`DayPayload`](../../app/lib/local/day.dart)
serializado em `payload` — sem tradução no meio, mesmo raciocínio da web.
**Estar aqui é ser dia que o servidor ainda não confirmou** (RN#1 da US011).

Uma diferença de armazenamento, não de contrato:
`queuedAt` é gravado em microssegundos (`queuedAtMicros`, um `int`), não num
`DateTimeColumn`. O armazenamento padrão do Drift trunca data e hora para o
segundo, e dois dias gravados no mesmo segundo — comum num teste rápido, e não
impossível numa sessão real de preenchimento — empatariam e perderiam a ordem
de envio. Custou um teste falhando para aparecer.

[`SyncQueueStore`](../../app/lib/local/sync_queue_store.dart) é a camada de
persistência (`put`, `get`, `list`, `settle`, `markRetried`, `markRejected`);
[`SyncEngine`](../../app/lib/local/sync_engine.dart) é a fila em si — o
`web/src/local/sync.ts`, com o mesmo `drain`/`flush`, o mesmo recuo dobrado
com teto de um minuto entre tentativas, a mesma distinção entre o que se
resolve reenviando (`40001`, falha de rede) e o que não se resolve (`23514`,
`42501`, [gravação do dia](../05-web/gravacao-do-dia.md)). O estado sai por um
`ValueNotifier<SyncState>` em vez do `subscribe`/`getState` da web — é o que o
Flutter já tem para isso, sem precisar de um `useSyncExternalStore`.

`SyncGateway`/`SupabaseSyncGateway` isolam a chamada RPC, no mesmo formato dos
outros gateways da E6. A recusa chega como `PostgrestException`, com o mesmo
`code`/`message` que a tabela de erros da gravação do dia descreve.

## As três frases, mais a quarta — sem tela ainda para mostrá-las

[`sync_messages.dart`](../../app/lib/local/sync_messages.dart) tem as
mesmas três frases da faixa de salvamento (decisão 3 da E3) e o mesmo texto de
conflito da web, palavra por palavra. `pendingOnSignOutMessage` não tem
equivalente aqui — não existe o "sair apaga" que ela avisaria.

[`SyncBanner`](../../app/lib/widgets/sync_banner.dart) e
[`ConflictNotice`](../../app/lib/widgets/conflict_notice.dart) são as
versões em Dart de `sync-banner.tsx` e `conflict-notice.tsx` — a tela de
[registro do dia](registro-do-dia.md) (#105) é quem as monta, chamando
`engine.save()` a cada campo e desenhando as duas por cima do formulário.

## O que a #105 resolveu, e o que continua em aberto

- **Gerar o `DayPayload`.** Feito em
  [`day/register.dart`](../../app/lib/day/register.dart) — os campos que a
  #105 cobre (descrição, aceitação, número de refeições, dia não letivo);
  os gêneros e a alteração do cardápio, que também moram no payload, ficam
  vazios/nulos até a #106.
- **Ligar a fila à tela.** `syncEngineProvider`, em
  [`local_providers.dart`](../../app/lib/local/local_providers.dart), mesmo
  raciocínio do `appDatabaseProvider` da #102.
- **Invalidar a leitura do mês quando a fila confirma** continua em aberto,
  e por decisão, não por esquecimento: ver
  [o que ainda não está resolvido](registro-do-dia.md#o-que-ainda-não-está-resolvido-o-mês-só-atualiza-no-próximo-refreshmonth)
  na doc do registro do dia.

## Testado

`flutter analyze`, `dart format --set-exit-if-changed` e `flutter test` —
[`day_test.dart`](../../app/test/local/day_test.dart),
[`sync_queue_store_test.dart`](../../app/test/local/sync_queue_store_test.dart),
[`sync_engine_test.dart`](../../app/test/local/sync_engine_test.dart) (com
`FakeSyncGateway` e `FakeConnectivityGateway`) e os testes de widget de
`SyncBanner`/`ConflictNotice`:

| Cenário | O que se afirma |
|---|---|
| Autosave e reabertura do aplicativo | o rascunho sobrevive a um `SyncEngine` novo sobre o mesmo banco (CA#2 e CA#3 da US010) |
| Envio confirmado | o dia sobe numa chamada só e só então sai do aparelho |
| Reenvio | mesma carga, mesmo carimbo — sem registro duplicado |
| Sem rede | não tenta, e a faixa diz "salvo no aparelho" |
| Rede voltando (`ConnectivityGateway.onChange`) | reenvia sozinha, sem ação da usuária (CA#1 da US011) |
| Tecla durante o envio | os identificadores são adotados e o texto novo não se perde |
| `superseded` | conflito sinalizado, e o que veio depois continua subindo |
| `23514`/`42501` | para de insistir, mostra a frase do servidor, não descarta o dia |
| `40001` | continua na fila e sobe na tentativa seguinte |
| Dia não letivo sem observação | fica guardado, não é enviado, e sobe quando o motivo chega |
| As três frases e o conflito | comparados palavra por palavra com a tabela da E3 e com a mensagem da web |
| `insertOnConflictUpdate` sem colunas explícitas | pegou uma recusa antiga sobrevivendo a uma gravação nova — corrigido gravando `rejectionCode`/`rejectionMessage` sempre, mesmo nulos |

**Não testado nesta issue**: leitura/escrita num aparelho de verdade. A
[tela de registro do dia](registro-do-dia.md) (#105) passou a exercitar a
fila fora do teste de unidade, mas só em testes de widget (banco em memória,
`FakeSyncGateway`) — o aparelho físico continua de fora.
