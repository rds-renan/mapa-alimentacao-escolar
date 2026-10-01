# O catálogo de gêneros no aplicativo

A US009 no aplicativo — a manutenção do catálogo, tela 4 da E3, issue #107. O
comportamento é o da web, descrito em [o catálogo de gêneros](../05-web/catalogo-de-generos.md);
o que segue registra só o que é do aplicativo. O código está em
[`app/lib/pages/food_items_page.dart`](../../app/lib/pages/food_items_page.dart)
(a tela) e em [`app/lib/food_items/`](../../app/lib/food_items/) (`form.dart`
com as regras do formulário e `messages.dart` com os textos).

## Os critérios de aceite

| Critério | Onde |
|---|---|
| Listar, cadastrar, editar, desativar e reativar; unidade em texto, com as pílulas como sugestão | um cartão só cadastra e edita: tocar uma linha carrega o gênero nele, e o botão "Adicionar ao catálogo" dá lugar a "Desativar"/"Reativar" e "Salvar". A unidade é campo de texto com as seis sugestões da folha do registro em pílulas |
| Aviso de que trocar a unidade reescreve os dias já registrados (#64) | aparece no cartão, junto da unidade, só quando a unidade de um gênero que já existe muda (`unitChanged`). Não proíbe: manutenção existe para corrigir cadastro |
| A lista se lê sem rede; alterar exige rede, e a tela diz isso | a lista vem do catálogo **no aparelho**; sem rede, um aviso no topo diz que dá para ver mas não para alterar, e os botões de gravar ficam apagados |

Nome repetido é dito antes de tentar (inclusive quando o homônimo está
desativado), desativados ficam numa seção recolhida no pé, que abre sozinha
depois de desativar, e a busca ignora acento e caixa e corta as duas listas —
tudo como na web.

## Ler é local, alterar é do servidor

A tela lê `CatalogRepository.watchFoodItems()` — o mesmo banco local que a folha
de escolher gênero usa — e pede `refresh()` ao abrir, por baixo e ignorando a
falha: sem rede, a atualização só não acontece.

Cadastrar, editar, desativar e reativar vão **direto ao servidor, sem passar
pela fila** ([decisão 2 da E6](decisoes-tecnicas.md)): a fila existe para o mapa
do dia, que é o que não pode se perder, e manutenção é tarefa ocasional, feita
de propósito. Só depois que o servidor aceitou é que `CatalogRepository.save` e
`setActive` gravam a cópia local com o que ele devolveu — a lista nunca mostra
o que o servidor recusou, e a folha do registro enxerga a mudança sem recarregar
nada, porque lê o mesmo banco.

Quando a gravação não passa, a mensagem diz primeiro o que não se perdeu: o que
está no formulário continua ali, é só tentar de novo.

## Como a tela sabe que está sem rede

`connectivityGatewayProvider` expõe o `ConnectivityGateway` que a fila já
usava, e a tela pergunta `isOnline()` ao abrir e escuta `onChange`. É dica de
interface, não garantia: com rede "disponível" a gravação ainda pode falhar, e
aí vale a mensagem de erro acima.

## Verificação

Rodam com `flutter test`, ao lado do código:

- [`food_items_page_test.dart`](../../app/test/food_items/food_items_page_test.dart)
  — os critérios um a um: a lista com os desativados recolhidos; sem rede a
  lista continua e o cadastro não envia; cadastro pela pílula e com "bandeja"
  (texto livre); nome repetido avisado antes; edição com o aviso da unidade;
  gravação recusada mantém o formulário; desativar e reativar; busca sem acento.
- [`form_test.dart`](../../app/test/food_items/form_test.dart) — as regras puras.
- [`catalog_repository_test.dart`](../../app/test/local/catalog_repository_test.dart)
  — a cópia local só é tocada depois que o servidor aceitou.
