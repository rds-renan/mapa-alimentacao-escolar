# Gêneros utilizados e alteração do cardápio no aplicativo

A US002 e a US003 dentro do [registro do dia](registro-do-dia.md) — a lista
de gêneros com stepper em cada refeição, a folha de escolher gênero (tela 3b
da E3) e a alteração do cardápio (tela 3a) —, issue #106. O comportamento é o
da web, descrito em
[os gêneros utilizados e a alteração do cardápio](../05-web/registro-do-dia.md#os-gêneros-utilizados-e-a-alteração-do-cardápio);
o que segue registra só o que é do aplicativo. O código está em
[`app/lib/day/`](../../app/lib/day/) (`food_item_list.dart`,
`food_item_sheet.dart`, `menu_change_page.dart` e as regras em
`register.dart`) e em [`app/lib/food_items/catalog.dart`](../../app/lib/food_items/catalog.dart).

## Os critérios de aceite

| Critério | Onde |
|---|---|
| No máximo uma alteração por refeição, com motivo em texto livre | registrada, a alteração vira resumo no cartão, e o botão que a criaria some — não há por onde nascer a segunda. O motivo é texto livre com três sugestões em pílula (RNF#1 da US002) |
| Gêneros com stepper em números inteiros | `FoodItemListView`: "−" e "+" de um em um, o número no meio é campo com teclado numérico e só aceita dígitos; o "−" de quem está em 1 tira o gênero da lista (quantidade zero não existe, RN#1 da US003) |
| Folha de escolher gênero com busca e cadastro, sem rede | a lista vem do catálogo **no aparelho**, a busca ignora acento e caixa, e o gênero novo sobe sem identificador, com a unidade escolhida — `save_meal_map` o cria pelo nome na mesma operação que grava o dia |

## O dia agora sobe inteiro

A #105 tinha deixado registrado o risco: `save_meal_map` substitui a lista de
refeições inteira a cada envio, e um aplicativo que lê o dia **sem** os
gêneros e o reenvia apagaria os gêneros que a colega registrou pela web. Com
esta issue a lacuna fecha:

- **A consulta do mês traz tudo.** `SupabaseMonthGateway` pede, para cada
  refeição, `meal_food_item` e `menu_change` com `menu_change_food_item`, cada
  gênero com o `food_item` embutido para o nome e a unidade — a mesma
  consulta de `web/src/day/queries.ts`. A resposta do PostgREST foi conferida
  contra o Supabase local: a alteração vem como objeto (a refeição é única em
  `menu_change`), não como lista.
- **O banco local guarda tudo.** Três tabelas novas, `schemaVersion` 3,
  migração só aditiva (ver [banco local](banco-local.md)). Cada gênero guarda
  o nome e a unidade junto do identificador — é a forma em que ele sobe, e o
  catálogo do aparelho pode ainda não conhecer um gênero que a colega
  cadastrou pela web.
- **`DayRepository` devolve tudo.** O `ConfirmedDay.day` que a tela edita já
  vem com os gêneros e a alteração de cada refeição.

O `refreshMonth` apaga os filhos à mão antes de regravar o dia, e não pela
cascata do esquema: o SQLite só respeita chave estrangeira com
`PRAGMA foreign_keys` ligado, e este banco nunca o ligou.

## A folha 3b é uma folha modal; a tela 3a é uma rota

Na web as duas são `Sheet` montadas pela própria página. No aplicativo:

- **A folha 3b** é `showModalBottomSheet` e **devolve** o gênero escolhido
  (ou nulo, se ela fechou) — quem põe na lista é o registro, com o dia mais
  novo na mão. Ao abrir, pede `CatalogRepository.refresh()` por baixo e
  ignora a falha: a lista já aparece com o que o aparelho tem, e sem rede a
  atualização só não acontece. É a primeira tela a acionar esse `refresh`,
  que a #102 tinha deixado sem uso; `catalogRepositoryProvider` nasceu aqui e
  é a mesma porta que a manutenção do catálogo (#107) vai usar.
- **A tela 3a** é uma rota de tela cheia (`fullscreenDialog`). Por ser outra
  rota, ela não se reconstrói junto com o registro — por isso recebe o dia
  por um `ValueListenable`, que o registro atualiza a cada tecla. A tela não
  guarda cópia nenhuma: cada gesto dela passa pelo registro, que grava e
  devolve. Ao fechar, ela diz **como** fechou — `cancel`, `remove`, ou nulo
  (confirmar, o X, o botão voltar do Android) —, e o registro decide o que
  fica: cancelar devolve a alteração como estava ao abrir, confirmar vazia a
  tira do dia.

A folha 3b aberta de dentro da 3a sobe por cima dela, porque as duas vão para
o mesmo `Navigator`.

Sem a normalização Unicode do JavaScript (`String.normalize('NFD')`), a busca
sem acento é uma tabela das letras acentuadas do português — é o que se
escreve num catálogo de cozinha escolar.

## Um detalhe do stepper

O número no meio do stepper guarda o próprio controlador, como os outros
campos do registro, e deixa o campo ficar **vazio** enquanto ela apaga para
digitar outro número — sem isso, apagar devolveria 1 debaixo do dedo e o
número seguinte sairia grudado nele. Ao sair do campo vazio, volta a mostrar a
quantidade que vale.

## O catálogo antes da primeira rede

Na web, a folha lê o catálogo do servidor e mostra um aviso se a leitura
falhar. No aplicativo a leitura é sempre do aparelho, então o único caso sem
lista é o aparelho que nunca teve rede desde o login. A folha diz isso e
aponta para o cadastro logo abaixo — que continua funcionando.

Um gênero cadastrado na folha só aparece nas sugestões depois de o dia subir
e o catálogo ser atualizado de novo (a próxima vez que a folha abrir com
rede). É o mesmo comportamento da web.

## Verificação

`flutter analyze`, `dart format --set-exit-if-changed`, `flutter test` (143
testes) e `flutter build apk --debug`.

[`register_test.dart`](../../app/test/day/register_test.dart) — as regras:

| Cenário | O que se afirma |
|---|---|
| Gênero escolhido | entra com a quantidade em 1 |
| O mesmo gênero de novo, com outra caixa | não duplica nem volta para 1 |
| "−" e "+" | andam de um em um, e o "−" em 1 tira o gênero |
| Quantidade digitada | só dígitos, zero é vazio, corta no `smallint` |
| Gêneros da refeição e da troca | não se misturam (decisão 7 da E4) |
| Gênero cadastrado na folha | sobe sem identificador e com unidade, e o dia pode subir |
| Primeiro gênero da troca | cria a alteração, ainda sem motivo |
| Segundo gênero da troca | entra na mesma alteração |
| Alteração sem motivo ou sem gênero | não está inteira, e o dia fica no aparelho |
| Mexer na alteração | não mexe no cardápio previsto |
| Busca | ignora acento e caixa |

[`month_gateway_test.dart`](../../app/test/local/month_gateway_test.dart) lê
a resposta do PostgREST na forma aninhada;
[`month_repository_test.dart`](../../app/test/local/month_repository_test.dart)
confere que um segundo `refreshMonth` substitui os gêneros e a alteração em
vez de acumular; e
[`day_repository_test.dart`](../../app/test/local/day_repository_test.dart)
faz a volta inteira — mês baixado, dia lido com os gêneros e a alteração.

[`day_register_page_test.dart`](../../app/test/pages/day_register_page_test.dart)
— a tela:

| Cenário | O que se afirma |
|---|---|
| Adicionar gênero | a folha abre, esconde o desativado, busca sem acento; o escolhido entra em 1 e o stepper anda |
| Gênero já na refeição | aparece marcado na folha |
| Sem rede nenhuma | a folha avisa que o catálogo não foi baixado, e o gênero cadastrado ali entra na refeição e no rascunho sem identificador |
| Alteração do cardápio | gênero pela folha por cima da 3a, motivo por sugestão, resumo no cartão, e o botão de criar outra some |
| Cancelar | devolve a refeição sem alteração |
| Fechar pelo voltar do Android com tudo apagado | não deixa alteração vazia |
| Mapa bloqueado | gêneros e alteração visíveis, sem editar; a 3a só tem "Fechar" |

Contra o Supabase local, fora dos testes automáticos: um dia com um gênero
novo na refeição e outro na alteração enviado por `save_meal_map` e lido de
volta com a consulta exata de `SupabaseMonthGateway` — os dois gêneros
nasceram pelo nome e a leitura tem a forma que o aplicativo espera.

**Não testado**: o caminho no aparelho físico — fica para o teste manual,
como nas issues anteriores.
