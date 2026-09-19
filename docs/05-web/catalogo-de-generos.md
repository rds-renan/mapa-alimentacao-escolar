# O catálogo de gêneros

O catálogo é o que mantém as quantidades comparáveis. Se a manteiga é "pote"
para uma merendeira e "quilo" para a outra, o número que vai ao documento
deixa de querer dizer alguma coisa — e é por isso que a unidade mora no gênero,
uma só por gênero (RN#1 da US009), e não no registro de cada dia.

Esta é a tela 4 da E3, a **manutenção** do catálogo: listar, buscar, cadastrar,
editar e desativar. Ela não participa do caminho diário — quem a alcança é o
menu ([decisão 9 da E3](../03-ux/decisoes-de-design.md)), porque cadastrar um
gênero no meio de uma refeição já acontece na folha 3b, sem sair do dia
([o registro do dia](registro-do-dia.md)).

O código está em [`web/src/food-items/`](../../web/src/food-items/) (o modelo,
a regra do formulário, as consultas e o cartão) e em
[`web/src/pages/FoodItems.tsx`](../../web/src/pages/FoodItems.tsx) (a tela). É
a mesma pasta que a folha 3b já lia: catálogo é catálogo, visto de duas telas.

## Um cartão só, que cadastra e edita

O desenho da E3 tem um cartão "Novo gênero" em cima e a lista embaixo, com um
chevron em cada linha que não levava a lugar nenhum. **Tocar uma linha carrega
o gênero nesse mesmo cartão**: o título vira "Editar gênero" e o botão
"Adicionar ao catálogo" dá lugar a dois lado a lado — desativar e salvar.

Dois formulários na mesma tela, ou uma folha por cima só para editar três
campos, custariam mais tela e mais gesto para fazer o que este cartão já faz. O
✕ do canto desiste da edição e devolve o cartão ao estado de cadastro.

Como a lista fica **abaixo** do cartão, tocar um gênero lá embaixo o carregaria
fora da tela — pareceria que o toque não fez nada. Por isso o cartão é trazido
à vista e o foco vai para o nome, que resolve o mesmo para quem navega por
teclado e leitor de tela.

## A unidade, em texto livre com sugestões

É aqui que o leque da [decisão 8 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)
se abre. A unidade é um campo de texto com as seis sugestões da E3 logo abaixo:
tocar uma preenche o campo, e o que a cozinha usa fora delas — "bandeja",
"fardo" — se escreve.

A folha 3b continua com as seis fechadas, e a diferença é proposital: lá, um
teclado no meio de uma refeição é que seria o custo; aqui, quem veio manter o
catálogo já veio para digitar.

### Trocar a unidade alcança o passado

`meal_food_item` guarda a quantidade e o gênero — **a unidade é lida do
catálogo**. Trocar "pote" por "quilo" faz um dia já registrado passar a dizer
"3 quilos de manteiga", e sair assim no documento do mapa que ainda não foi
gerado.

A tela não proíbe: manutenção existe justamente para corrigir erro de cadastro,
e é a correção que ela quer que pegue no passado. O que a tela faz é **dizer**,
no lugar onde a decisão está sendo tomada, e só quando a unidade de um gênero
que já existe muda. Nada disso alcança documento já gerado: aquele é um arquivo,
e ele não é reescrito.

## Nome repetido, dito antes de tentar

O banco tem índice único por escola e nome normalizado — "Arroz" e "arroz " são
o mesmo gênero ([decisão 8 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)).
A tela compara o nome com o catálogo que já tem na mão e avisa antes de enviar,
em vez de deixar o servidor recusar sem explicação.

Quando o homônimo está **desativado**, a mensagem diz onde ele está: sem isso,
ela ficaria tentando cadastrar um gênero que a lista de cima não mostra, sem
entender por que não entra.

## Desativar não é excluir

O CA#3 da US009 em uma linha: **o gênero sai das sugestões e continua nos dias
que já o usaram**. Não existe política de exclusão no banco, e a chave
estrangeira restritiva garante o resto.

Os desativados não somem da tela. Ficam numa seção recolhida no pé — "Desativados
(2)" —, cada um com o caminho de volta pelo mesmo cartão, agora com "Reativar".
Se eles sumissem de vez, desativar por engano seria irreversível pela interface,
e a volta dependeria de alguém mexer no banco. Depois de desativar, a seção abre
sozinha: é para lá que ela vai olhar se tiver sido engano.

**Desativar não pede confirmação.** A única confirmação do fluxo da merendeira é
a de gerar o documento, porque ela é irreversível para ela
([decisão 11 da E3](../03-ux/decisoes-de-design.md)); esta tem volta logo ali
embaixo, e confirmar tudo é o caminho mais curto para ela deixar de ler as
confirmações.

## A busca

RNF#1 da US009. Ela ignora acento e caixa — "feijao" acha "Feijão" —, e é a
mesma função que a folha 3b usa, porque errar o til não pode custar o resultado
de quem está com as duas mãos ocupadas na cozinha.

A busca corta as duas listas: procurar um gênero que foi desativado é
justamente como se descobre que ele foi desativado.

## Duas leituras do mesmo catálogo

| Quem lê             | O que pede            | Por quê                                               |
| ------------------- | --------------------- | ----------------------------------------------------- |
| A folha 3b (tela 3) | só os ativos          | o desativado sumiu das sugestões (CA#3 da US009)      |
| A tela 4            | ativos e desativados  | desativar por engano precisa ter volta                |

As duas chaves de cache nascem da mesma raiz (`['food-items']`), e é isso que
faz uma escrita na tela 4 alcançar a folha do registro sem ninguém recarregar
nada — e que faz a fila do dia, que já invalidava essa raiz quando
`save_meal_map` cria um gênero, continuar valendo sem mudança.

A leitura da folha 3b guarda meia hora de validade, porque ela acontece no meio
de um registro e o catálogo muda devagar. A da tela 4 não guarda nenhuma: quem
está aqui veio mexer no catálogo, e as duas merendeiras mexem nele do mesmo
jeito — meia hora de atraso seria meia hora editando uma lista que já mudou.

## A gravação vai direto ao servidor

Sem passar pela fila do aparelho, e isso é a [decisão 2](decisoes-tecnicas.md)
aplicada: a fila existe para o mapa do dia, que é o que não pode se perder
(RN#1 da US011). A manutenção do catálogo é tarefa ocasional, feita de
propósito, e quem a faz sem rede pode refazer com rede.

O gênero que nasce no meio de um registro — esse sim — continua subindo dentro
do dia, pela fila, porque ele é parte do que ela digitou naquele momento.

Quando a gravação não passa, a mensagem diz o que ela precisa saber para
continuar: **o que está no formulário continua ali**, é só tentar de novo. E
quando é a *lista* que não vem, o cartão de cadastro continua de pé — o que
falhou foi a leitura, e a escrita tenta o servidor por conta própria.

Quem pode escrever é a merendeira: as políticas de RLS da E4 dão o `insert` e o
`update` de `food_item` ao perfil `cook`, e o catálogo é dela sem depender de
ninguém — a premissa da US009. A guarda de rota é cortesia de interface, como
sempre ([decisão 6](decisoes-tecnicas.md)).

## Verificação

Os testes rodam com `npm test`, ao lado do código.

[`food-items.test.tsx`](../../web/src/food-items/food-items.test.tsx) — os
critérios de aceite da issue, um a um:

| Cenário                                 | O que se afirma                                        |
| --------------------------------------- | ------------------------------------------------------ |
| A lista                                 | cada gênero com a sua unidade padrão                   |
| Busca por "feijao"                      | acha "Feijão carioca" (RNF#1 da US009)                 |
| A lista não veio                        | diz o que houve e mantém o cadastro de pé              |
| Cadastro pela sugestão                  | entra no catálogo com a unidade escolhida              |
| Cadastro com "bandeja"                  | a unidade é texto livre (decisão 8 da E4)              |
| Nome ou unidade em branco               | não dá para salvar (CA#1 da US009)                     |
| Nome repetido                           | avisa antes de tentar, em vez de duplicar              |
| Nome repetido de um desativado          | diz onde ele está                                      |
| Gravação recusada                       | o que ela escreveu continua no formulário              |
| Toque numa linha                        | carrega o gênero no mesmo cartão e salva o nome novo   |
| Troca da unidade                        | avisa que alcança os dias já registrados               |
| ✕ na edição                             | desiste sem mexer no gênero                            |
| Desativar                               | sai da lista, aparece entre os desativados, e reativa  |
| Um dia que já usou um gênero desativado | o gênero continua no dia e some da folha de escolher   |

A última linha é o CA#3 da US009 visto dos dois lados na mesma corrida: o dia
abre com "Manteiga" e a sua unidade, e a folha 3b, no mesmo dia, já não a
oferece.
