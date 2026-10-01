# A visão do mês e o menu do aplicativo

A tela-casa da merendeira no aplicativo (US008, US020) — tela 2 e 2a da E3,
issue #104. O que segue registra só o que diverge da
[visão do mês da web](../05-web/visao-do-mes.md), ou o que o aplicativo
acrescenta — ler lá primeiro é o que evita reconstruir de memória o que já
está escrito. O código está em
[`app/lib/month/`](../../app/lib/month/) (o domínio e as peças da lista),
[`app/lib/pages/home_page.dart`](../../app/lib/pages/home_page.dart) (a tela)
e [`app/lib/widgets/app_menu.dart`](../../app/lib/widgets/app_menu.dart) (o
menu).

A lista de dias, a quebra de semana na segunda-feira, o fim de semana fora
salvo com registro, os cinco estados derivados na leitura (decisão 4 da E4) e
o andamento do mês são os mesmos da web, letra por letra — só a linguagem
trocou. [`month.dart`](../../app/lib/month/month.dart) é o porto de
[`month.ts`](../../web/src/month/month.ts): mesmas funções puras, mesmo
raciocínio, sem rede e sem Flutter.

## Datas em hora local, sem o cuidado que a web precisou ter

A web trata toda data como texto e aritmética em UTC porque `new
Date('2026-09-01')` no JavaScript é meia-noite em UTC — no fuso de Brasília
isso é 31 de agosto, e o mês inteiro andaria um dia para trás. O Dart não tem
essa armadilha: `DateTime.parse('2026-09-01')` é meia-noite **local**, o
oposto do `Date` do JavaScript. `MonthRepository` (issue #102) já constrói
todas as datas em hora local — `DateTime(ano, mês)` para os limites do mês,
`DateTime.parse` para o que vem do servidor —, e `month.dart` faz o mesmo em
toda parte. Não há UTC neste arquivo porque não precisa haver.

## Uma origem só, não duas

Na web, a visão do mês é onde a TanStack Query (o servidor) e a camada local
(o rascunho por enviar) se encontram pela primeira vez, e o rascunho vence
— menos o bloqueio, que só o servidor sabe.

Esta tela ainda não tem esse encontro: `DayRecord` nasce só do banco local
(`meal_maps`/`meals`, issue #102), que já é a cópia convergida do servidor
via `refreshMonth`. O rascunho por enviar mora em `pending_meal_maps` (issue
#103), numa tabela separada que ninguém aqui lê — um dia editado e ainda na
fila aparece **vazio** nesta lista, a mesma lacuna que a web teve até a
própria visão do mês entrar (veja o histórico do PR #83).

A tela do [registro do dia](registro-do-dia.md#uma-origem-só-e-o-encontro-que-a-visão-do-mês-esperava)
já faz esse encontro, para o dia que ela abre — é lá que `DayRepository` e
`SyncEngine` se juntam. Trazê-lo também para **esta** lista (para o mês
inteiro, não um dia por vez) continua em aberto, e a mesma página do
registro do dia explica por que não foi resolvido junto: escrever a
confirmação da fila nas tabelas de leitura duplicaria o caminho de gravação.

## O banco abre com o perfil e não fecha com a sessão

[`local_providers.dart`](../../app/lib/local/local_providers.dart) resolve as
duas pendências que a documentação do banco local (issue #102) deixou em
aberto:

- **`appDatabaseProvider`** é quem chama
  `AppDatabase(openLocalDatabaseConnection(profile.id))` pela primeira vez —
  a visão do mês, ao montar. É um `Provider.family` comum, não
  `autoDispose`: sair não fecha o arquivo — `AuthController.signOut` nunca
  chega perto daqui (autenticação e sessão, #101) —, e um único perfil por
  sessão do aplicativo é o único caso que existe hoje. `ref.onDispose` fecha
  a conexão quando o próprio `ProviderContainer` cai, o que na prática só
  acontece ao encerrar o aplicativo.
- **Apagar ao sair, ou não** deixou de ser uma pergunta em aberto: não há
  apagar nenhum. É a mesma resposta que a autenticação já tinha escrito
  ([sair apaga o que é do aparelho, não o que é da
  pessoa](autenticacao-e-sessao.md#sair-apaga-o-que-é-do-aparelho-não-o-que-é-da-pessoa)),
  só que agora o banco existe de verdade para confirmar que o código cumpre
  a regra.

## Sem promessa de rede — nem estado de "carregando"

A web não promete navegar sem rede (decisão 2 da E5): a visão do mês de lá
tem um estado de "carregando" e um de "falhou", porque cada abertura da tela
pede o mês ao servidor. Aqui é o oposto — CA#3 da issue #104. `watchMonth`
lê só o banco local, que já está no aparelho desde a última convergência; não
há nada para "carregar" nem para "falhar em carregar", porque a tela nunca
depende da rede para aparecer.

`refreshMonth` ainda roda — ao abrir a tela e a cada troca de mês, iniciado
por `_ensureMonthStream` em `home_page.dart` — mas por baixo, sem bloquear a
leitura: uma falha (`catchError((_) {})`) é silenciosa de propósito, porque a
lista já mostra o que está no aparelho e a rede só melhora o que já apareceu,
nunca condiciona a tela a aparecer. Não há faixa de erro, nem contagem de
"dias salvos esperando envio" como a web tem para a falha de carga — esse
aviso é sobre o **rascunho** que ainda não subiu (issue #103). A tela do
[registro do dia](registro-do-dia.md) já o mostra, mas só para o dia que
está aberta nela; esta lista continua sem um resumo do que está pendente no
mês inteiro.

## `package:clock`, para "hoje" ser um dado e não uma chamada global

O destaque de "hoje" na lista, o mês em que a tela abre e a quebra das
semanas dependem todos da data corrente. A web fixa isso em teste trocando o
relógio do sistema (`vi.setSystemTime`); o equivalente em Dart é
`package:clock` — `clock.now()` no lugar de `DateTime.now()` em
`home_page.dart`, e `withClock(Clock.fixed(...), ...)` em volta do corpo de
cada teste que precisa de uma data fixa
([`home_page_test.dart`](../../app/test/pages/home_page_test.dart)). Já era
dependência transitiva (o próprio `flutter_test` a usa por baixo) — entrar
como dependência direta é só nomear o que já estava no projeto.

## O mês fica no estado da tela, não na rota

A web guarda o mês aberto na URL (`/?mes=2026-05`) porque o F5 acontece lá, e
recarregar não pode devolvê-la a hoje enquanto confere o mês passado. O
aplicativo não tem barra de endereço nem F5: `_HomePageState._month` é
suficiente, e voltar para a tela-casa (pelo menu, ou saindo do registro de um
dia) recomeça em hoje — o mesmo comportamento que abrir o aplicativo do zero
já tinha.

## O menu

A mesma [decisão 9 da E3](../03-ux/decisoes-de-design.md) da web: a porta do
que não é fluxo diário, um toque a partir da tela inicial, reunindo
documentos gerados, gerenciar gêneros, tema e sair. Dois desses quatro itens
ainda não têm destino, e o tema ainda não tem controle — a mesma situação em
que a web esteve entre as issues #61 e #71, e a mesma resposta: ficam **à
vista e inertes**, porque tirá-los do desenho e recolocá-los depois custaria
mais do que deixá-los explicados.

| O que | Onde está hoje | Issue |
| --- | --- | --- |
| Gerenciar gêneros | tela-marco | #107 |
| Tema escuro | à vista e inerte — o aplicativo já segue o tema do aparelho (`ThemeMode.system`), falta o controle entre claro/escuro/sistema | #111 |
| Gerar documento (rodapé) | abre a [seleção de mapas](selecao-de-mapas-e-geracao.md) no mês que ela estava vendo | #108 |
| Registro do dia (toque numa linha) | tela-marco | #105 |

Sem caminho para a área da direção (RN#1 da US020) — cortesia de interface,
como sempre; quem impede a leitura são as políticas de RLS da E4.

## Verificação

`flutter analyze`, `dart format --set-exit-if-changed` e `flutter test`:

[`month_test.dart`](../../app/test/month/month_test.dart) — a regra, sem
Flutter, mesma divisão da web entre domínio e tela:

| Cenário | O que se afirma |
| --- | --- |
| Registro que existe mas está em branco | é vazio, não pendente |
| Falta a aceitação de uma refeição | continua pendente (CA#3 da US004) |
| Falta o número de refeições | continua pendente |
| Bloqueado ganha de completo e de não letivo | o bloqueio vem na frente |
| O que falta, singular e plural | "falta o lanche da tarde", "faltam as três refeições" |
| Fim de semana | fora da lista, salvo quando tem registro |
| Quebra das semanas | na segunda-feira, num mês que começa numa terça |
| Andamento | não letivo sai do total de dias letivos |
| Virada de ano e fevereiro bissexto | o recorte do mês fecha no dia certo |

[`home_page_test.dart`](../../app/test/pages/home_page_test.dart) — a tela,
com o relógio fixado em 9 de setembro de 2026 (`package:clock`, o mesmo
raciocínio do `vi.setSystemTime` da web):

| Cenário | O que se afirma |
| --- | --- |
| Os cinco estados na lista | cada etiqueta tem texto próprio (RNF#1 da US008) |
| Funciona sem rede com o que já está no aparelho | reabrir a tela com o gateway falhando continua mostrando o que convergiu antes (CA#3 da issue #104) |
| Toque num dia | abre o registro daquele dia (CA#2 da US008) |
| Toque num dia bloqueado | também abre: somente leitura não é inalcançável |
| Navegação entre meses | troca o título |
| "Gerar documento" | visível e inerte |
| Menu | um toque, e reúne os quatro itens (CA#2 da US020) |
| Menu | nenhum caminho para a direção (RN#1 da US020) |
| Menu → Documentos gerados / Gerenciar gêneros | levam à lista de documentos e à manutenção do catálogo |
| Menu → Sair | encerra a sessão e volta ao login |

`flutter build apk --debug` compila com o Drift ligado ao SQLite nativo do
Android.

**Não testado**: leitura/escrita num aparelho de verdade — os testes de
widget usam um banco em memória e um `MonthGateway` falso, como sempre nesta
etapa. Fica para a verificação manual de cada issue que mexer aqui.
