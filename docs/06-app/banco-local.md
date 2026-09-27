# Banco local: o mês e o catálogo sem rede

O CA#1 da US010 virando código: os meses já consultados e o catálogo de
gêneros ficam no aparelho, e abrir o aplicativo do zero sem rede mostra o
que já foi baixado. É a issue #102, decisão 6 da E6, e o código mora em
[`app/lib/local/`](../../app/lib/local/).

**O que esta issue não é**: nem rascunho, nem fila de envio — isso é a #103.
Nem o detalhe de um dia aberto para editar — gêneros usados na refeição e
alteração do cardápio ficam para a #105 estender o esquema quando a tela de
registro existir. O que está aqui é só o que a visão do mês (US008) e a
leitura do catálogo pedem: a mesma consulta que a
[visão do mês da web](../05-web/visao-do-mes.md#duas-origens-que-não-se-misturam)
já faz — por `map_date`, trazendo o mapa e as suas refeições —, e o
[catálogo de gêneros](../05-web/catalogo-de-generos.md) inteiro, ativos e
desativados.

## Drift sobre SQLite, um arquivo por usuária

O banco é acessado pelo [Drift](https://drift.simonbinder.eu), sobre um
arquivo SQLite próprio (`app/lib/local/app_database.dart`). O nome do
arquivo nasce do identificador do perfil —
[`localDatabaseName`](../../app/lib/local/app_database.dart) — porque só
existe depois do login (decisão 6 da E6): duas merendeiras no mesmo aparelho
não dividem arquivo, mesmo dividindo a mesma escola e o mesmo mapa.

Três tabelas, hoje:

| Tabela | Espelha | O que fica de fora, e por quê |
|---|---|---|
| `food_items` | `public.food_item` | nome normalizado e escola — o arquivo já é de uma escola só |
| `meal_maps` | `public.meal_map` | `updated_by`: não entra no cálculo dos cinco estados |
| `meals` | `public.meal` | gêneros usados e alteração do cardápio — ficam para a #105 |

`type` e `acceptance` guardam o mesmo texto do banco (`morning_snack`,
`great`, …), sem tradução no meio — o mesmo raciocínio da
[gravação do dia](../05-web/gravacao-do-dia.md) sobre o payload de
`save_meal_map`.

## Um gateway por origem remota, substituível nos testes

`CatalogGateway` e `MonthGateway` isolam o que cada repositório precisa do
Supabase, atrás de uma interface — o mesmo raciocínio do `AuthGateway` da
autenticação (decisão 4 da E6): torna os repositórios testáveis sem
servidor. `SupabaseCatalogGateway` e `SupabaseMonthGateway` são as
implementações de verdade; nenhum filtro de escola entra nas consultas —
quem recorta é o RLS da E4, como sempre (decisão 6 da E6).

## Ler é sempre o aparelho; atualizar não bloqueia

`CatalogRepository` e `MonthRepository` seguem os dois a mesma forma:

- **`watchFoodItems()` / `watchMonth(mês)`** leem só o banco local, como um
  `Stream` — a "consulta que avisa quando o resultado muda" que a decisão 6
  promete. Quem está olhando a tela nunca espera o servidor para ver o que
  já tinha.
- **`refresh()` / `refreshMonth(mês)`** buscam no gateway e escrevem por
  baixo, dia por dia (`insertOnConflictUpdate` no catálogo; no mês, o dia
  inteiro substitui as refeições que tinha — o mesmo raciocínio de
  `save_meal_map`, "o que não vier deixa de existir"). Se a rede falhar, a
  chamada lança e a cópia local não é tocada: quem chama decide se tenta de
  novo, e quem está lendo nem percebe.

Nenhum dos dois é acionado a partir de uma tela ainda — não há uma para
acionar. A tela-casa (#104) é quem vai chamar `refresh`/`refreshMonth` ao
abrir e ao trocar de mês, e observar o `Stream` para desenhar a lista.

## O que fica para depois

- **Abrir e fechar o arquivo certo a cada login/logout.** `AuthController`
  ainda não conhece o banco local — a issue #101 já registrou isso
  ([autenticação e sessão](autenticacao-e-sessao.md#sair-apaga-o-que-é-do-aparelho-não-o-que-é-da-pessoa)).
  Quem abre `AppDatabase(openLocalDatabaseConnection(profile.id))` pela
  primeira vez é a tela que precisar dele.
- **Apagar ao sair, ou não.** A web apaga tudo ao sair porque é uso raro; o
  aplicativo guarda "uma cópia do que ela consulta" (decisão 6) — se
  apagar ao sair também vale aqui é decisão de quem ligar a sessão ao
  banco, não desta issue.
- **Gêneros usados e alteração do cardápio.** Entram com a #105, que também
  decide se abrir um dia para editar lê deste banco ou pede rede.

## Testado

`flutter analyze`, `dart format --set-exit-if-changed` e `flutter test` —
[`catalog_repository_test.dart`](../../app/test/local/catalog_repository_test.dart)
e
[`month_repository_test.dart`](../../app/test/local/month_repository_test.dart),
com `NativeDatabase.memory()` (é o banco que roda nos testes, decisão 6) e
um gateway falso de cada:

| Cenário | O que se afirma |
|---|---|
| Catálogo/mês já no aparelho, gateway nunca chamado | leitura sem rede mostra o que já foi baixado |
| `refresh`/`refreshMonth` com o gateway respondendo | a cópia local reflete o que veio |
| Gênero repetido, dia já existente | atualiza a linha, não duplica |
| Refeições do dia mudando entre duas atualizações | o novo conjunto substitui o antigo, não acrescenta |
| Alguém observando o `Stream` durante o `refresh` | recebe a emissão nova sem reabrir nada — não bloqueou |
| Gateway lançando (sem rede) | a chamada propaga o erro, e a cópia local não muda |

`flutter build apk --debug` compila com o Drift ligado ao SQLite nativo do
Android.

**Não testado**: leitura/escrita num aparelho de verdade — não há tela
ainda que exercite o banco fora do teste de unidade. Fica para a #104, que
segue a lição da própria E6
([autenticação e sessão](autenticacao-e-sessao.md)): compilar não é o
mesmo que abrir contra o Supabase de verdade.
