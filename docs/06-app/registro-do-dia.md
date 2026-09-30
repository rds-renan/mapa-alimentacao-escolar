# O registro do dia no aplicativo

A tela central do produto no aplicativo (US001, com a US004 a US007 dentro
dela) — tela 3 da E3, issue #105. O que segue registra só o que diverge do
[registro do dia na web](../05-web/registro-do-dia.md), ou o que esta issue
deixou de propósito fora — ler lá primeiro é o que evita reconstruir de
memória o que já está escrito. O código está em
[`app/lib/day/`](../../app/lib/day/) (as regras, os cartões e os textos) e em
[`app/lib/pages/day_register_page.dart`](../../app/lib/pages/day_register_page.dart)
(a tela).

## O que esta issue cobre, e o que ficou para a #106

A issue #105 e a #106 nasceram separadas: esta cobre a descrição ("Cardápio
previsto"), a aceitação em três botões, o número de refeições e o dia não
letivo — as três primeiras seções da tela 3. Os gêneros utilizados e a
alteração do cardápio (US002, US003 — a tela 3a e a folha 3b da E3) vieram
com a #106, que também estendeu o esquema local para guardá-los: ver
[gêneros utilizados e alteração do cardápio](generos-e-alteracao-do-cardapio.md).

[`day/register.dart`](../../app/lib/day/register.dart) é o porto de
`web/src/day/register.ts` — mesma regra, mesmo raciocínio. Nesta issue
entraram `mealState`, `firstUnfinishedMeal`, `dayProgress`, `touch`,
`setDescription`, `setAcceptance`,
`setMealsServed`/`parseMealsServed`/`stepMealsServed`, `setNote` e
`setNonSchoolDay`; as funções dos gêneros e da alteração (`addFoodItem`,
`setMenuChangeReason`, etc.) entraram com a #106, junto da tela que as usa.

## Uma origem só, e o encontro que a visão do mês esperava

A [visão do mês](visao-do-mes-e-menu.md#uma-origem-só-não-duas) tinha
deixado registrado que ler o rascunho por cima do banco convergido — o par
de origens que a web já resolvia — era decisão desta issue. Aqui está: a tela
combina duas fontes, a mesma fronteira da web (decisão 4 da E5).

- **[`DayRepository`](../../app/lib/local/day_repository.dart)** lê o banco
  já convergido (`meal_maps`/`meals`, issue #102) para um dia só, em
  `Stream<ConfirmedDay?>` — ao lado de `MonthRepository`, que lê o mês
  inteiro para a visão dele. Desde a #106, `ConfirmedDay.day` vem inteiro,
  com os gêneros e a alteração de cada refeição.
- **`SyncEngine.load`/`SyncEngine.save`** (issue #103) são o rascunho —
  `syncEngineProvider`, novo em
  [`local_providers.dart`](../../app/lib/local/local_providers.dart), nasce
  aqui exatamente como `appDatabaseProvider` nasceu na #102: `Provider.family`
  comum, não `autoDispose`, porque sair da tela não pode derrubar um envio em
  andamento. `engine.start()` roda na primeira leitura, e `ref.onDispose`
  para a fila quando o `ProviderContainer` cai.
- **`day = draft ?? confirmado ?? emptyDay(mapDate)`** — vale o rascunho
  quando existe (só está guardado enquanto o servidor não confirmou, logo é
  mais novo por construção); o banco convergido quando não há rascunho; um
  dia em branco quando nenhum dos dois tem nada, sem promessa de rede
  nenhuma — ao contrário da web, que lê o servidor ao vivo quando falta
  rascunho, aqui a leitura é sempre só o aparelho (CA central da E6).
- **O conflito nunca se resolve em silêncio** (CA#3 da US011): perdido o
  conflito, a `_DayRegisterPageState` relê o disco (`SyncEngine.load`) assim
  que `SyncEngine.stateListenable` avisa um `Conflict` novo para esta data, e
  `ConflictNotice` mostra o aviso até ela dizer "Entendi".

### O que ainda não está resolvido: o mês só atualiza no próximo `refreshMonth`

A mesma pendência que a doc da fila apontava. `SyncEngine.settle` tira o dia
confirmado da fila, mas **não escreve** em `meal_maps`/`meals` — quem escreve
lá é só `MonthRepository.refreshMonth`, chamado pela visão do mês ao abrir a
tela ou trocar de mês. Voltar da tela do dia para o mês logo depois de um
envio confirmado pode mostrar o estado antigo até a próxima dessas duas
coisas acontecer.

Decisão consciente de não resolver agora: escrever a confirmação também nas
tabelas de leitura duplicaria o caminho de gravação (a fila e o
`refreshMonth` passariam a concordar sobre o mesmo dado por dois caminhos
diferentes), e a tela do próprio dia não sofre com isso — quem edita continua
vendo o que editou, porque `_draft` não depende de `meal_maps`/`meals` para
mostrar o que está certo. Fica registrado para quem mexer na visão do mês de
novo: se a lacuna incomodar na prática, o caminho mais simples é a
`HomePage` escutar `SyncEngine.stateListenable` e chamar `refreshMonth()`
quando um dia da fila for confirmado.

## `uuid`, para o dia em branco e as refeições que nascem na primeira tecla

`emptyDay`/`newId` (`app/lib/local/day.dart`) precisavam gerar UUID v4 no
aparelho — o mesmo `crypto.randomUUID()` que a web usa. O Dart não tem
equivalente na biblioteca padrão; entrou `package:uuid` (só ele, sem
dependência transitiva nova de peso) como dependência direta.

## O cabeçalho: sem setas de dia, com o botão do sistema

A web tem setas de dia anterior/próximo dia no cabeçalho porque não existe
botão de voltar do navegador dentro do fluxo dela. No aplicativo é o
contrário: o `AppBar` já desenha a seta de voltar sozinho quando há o que
desempilhar (a tela sempre chega por `context.push`, da visão do mês), e o
botão físico do Android faz a mesma coisa de graça — não há código nenhum
para o CA#5 além de deixar o `Navigator` fazer o que já faz. Por isso não há
andar entre dias pelas setas nesta tela: não estava nos critérios de aceite
da #105, e a issue não antecipa o que não foi pedido.

## O acordeão dos três cartões

Igual à web: um `String?` só (`_openMeal`) diz qual cartão está aberto, nunca
mais de um. A escolha do cartão aberto ao entrar na tela é feita uma vez só —
`_chooseOpenMealOnce`, guardado por um `bool`, roda o cálculo de
`firstUnfinishedMeal` num `WidgetsBinding.instance.addPostFrameCallback` para
não chamar `setState` no meio da construção da árvore.

`MealCard` (issue #105) era o `web/src/day/meal-card.tsx` sem os dois blocos
da #106: só o campo do cardápio previsto e a `AcceptanceChoice`; a #106
acrescentou os gêneros e a alteração. O campo de texto e o campo numérico das refeições
servidas guardam o próprio `TextEditingController`, e só o reescrevem quando
o valor vem de fora (o "−"/"+", a devolução do dia não letivo) — sem essa
distinção, o autosave (que reconstrói a tela a cada tecla) empurraria o
cursor para o fim a cada letra digitada no meio do texto.

## A bolinha do interruptor desligado, achada no teste manual

Único achado do teste no aparelho físico (issue #99): o interruptor do dia
não letivo, desligado, não mostrava a bolinha — só aparecia depois do
primeiro toque, e sumia de novo ao desligar de volta. Causa: o padrão do
Material 3 pinta a bolinha desligada com `colorScheme.outline`, e no tema
escuro esse token é **a mesma cor** da trilha
(`colorScheme.surfaceContainerHighest`) — a bolinha não estava invisível por
acidente de renderização, estava desenhada exatamente por cima da própria
trilha, com a mesma tinta. No tema claro os dois tokens só são próximos o
bastante para o mesmo efeito, num pouco menos grave.

Corrigido em [`theme.dart`](../../app/lib/theme/theme.dart) com um
`switchTheme` que pinta a bolinha desligada com `colorScheme.onSurfaceVariant`
— o mesmo tom que o app já usa para texto de apoio sobre essas superfícies,
logo já garantidamente contrastante. `main_test.dart` ganhou um teste que
compara as duas cores nos dois temas, para a correção não se perder numa
revisão futura da paleta.

## Verificação

`flutter analyze`, `dart format --set-exit-if-changed` e `flutter test`:

[`register_test.dart`](../../app/test/day/register_test.dart) — as regras
que esta issue cobre, sem tela, mesmo raciocínio de
`register.test.ts`:

| Cenário | O que se afirma |
| --- | --- |
| Descrição sem aceitação, e o contrário | a refeição é pendente, não preenchida |
| Descrição só com espaço | a refeição continua vazia |
| Dia em branco, dia começado | abre na primeira refeição que falta |
| Andamento do dia letivo e do não letivo | quatro partes e uma parte |
| Escrever numa refeição | não mexe nas outras nem no número do dia |
| Marcar dia não letivo | tira refeições e número do payload |
| Desmarcar | devolve o que estava digitado (CA#3 da US006) |
| Número de refeições: letra, vírgula, zero, teto | só dígitos, zero é vazio, corta no `smallint` |

[`day_repository_test.dart`](../../app/test/local/day_repository_test.dart) —
a leitura de um dia só:

| Cenário | O que se afirma |
| --- | --- |
| Dia sem linha no banco | devolve nulo, e a tela cai para `emptyDay` |
| Mapa e refeições convergidos | reconstrói o `DayPayload` (os gêneros e a alteração, desde a #106) |
| Mapa bloqueado | `locked` chega marcado |
| Mudança por baixo | quem está com o `Stream` aberto é avisado sem reabrir nada |

[`day_register_page_test.dart`](../../app/test/pages/day_register_page_test.dart)
— a tela, critério por critério da issue #105:

| Cenário | O que se afirma |
| --- | --- |
| As três refeições | cada uma abre com o cardápio previsto e três botões de aceitação |
| Digitar e escolher a aceitação | grava no aparelho, sem botão de salvar |
| Número de refeições | teclado numérico, só dígitos |
| Dia não letivo | esconde as refeições, só pede a observação |
| Mapa bloqueado | mostra o estado e desabilita os campos |
| Botão voltar do Android | volta para a visão do mês (CA#5) |

[`main_test.dart`](../../app/test/main_test.dart) — a bolinha do interruptor
desligado tem cor diferente da trilha, em claro e em escuro (achado do
teste manual).

**Não testado**: leitura/escrita num aparelho de verdade — mesma situação da
#102/#103/#104, com banco em memória e gateways falsos nos testes de widget.
