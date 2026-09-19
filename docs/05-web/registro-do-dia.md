# O registro do dia

É a tela central do produto: o lugar onde a merendeira transcreve o que foi
servido em cada uma das três refeições, avalia a aceitação, informa o número de
refeições do dia e, quando é o caso, marca o dia como não letivo. É a US001 —
com a US004, a US005, a US006 e a US007 dentro dela — e é a tela 3 da E3.

O código está em [`web/src/day/`](../../web/src/day/) (as regras, a consulta e
os cartões) e em
[`web/src/pages/DayRegister.tsx`](../../web/src/pages/DayRegister.tsx) (a tela).
O que ela grava e envia é da [camada local](camada-local.md); o contrato do que
sobe é a [gravação do dia](gravacao-do-dia.md).

## Uma tela, três cartões

A [decisão 5 da E3](../03-ux/decisoes-de-design.md) já tinha resolvido a forma:
as três refeições numa tela só, em cartões que abrem e fecham. Uma tela por
refeição triplicaria a navegação de um fluxo que precisa caber na rotina — e o
registro de um dia comum tem de terminar em menos de dois minutos (RNF#1 da
US001).

Fechado, o cartão continua dizendo o que foi servido e em que pé está
(preenchida, pendente, vazia). **A tela abre na primeira refeição que falta**:
num dia em branco é o lanche da manhã; num dia que ela está completando, é onde
o trabalho parou. Com as três prontas, nenhuma abre — o que ela quer ver aí é o
resumo.

A escolha do cartão aberto é feita **uma vez**, ao abrir o dia. Recalculá-la a
cada tecla fecharia o cartão sozinho no instante em que a refeição ficasse
pronta, no meio da digitação dela.

A aceitação é um toque em um de três botões, sem lista suspensa e sem digitar
nada (RNF#1 da US004). Os três ocupam a linha em partes iguais porque nenhum é
o padrão: escolher "Ruim" tem de ser tão fácil quanto escolher "Ótimo". Tocar
no que já está escolhido não desmarca — um registro sem aceitação existe, mas
ninguém o faz de propósito com o dedo.

O número de refeições é **um campo só, do dia inteiro** (RN#1 da US005): na
escola integral as crianças ficam o dia todo, e o número vem das professoras
para a direção e da direção para a cozinha. O campo é numérico, com teclado
numérico (RNF#1), e os botões de − e + ao lado servem à correção de um a mais
ou um a menos, que é o ajuste que acontece de verdade — digitar 312 num stepper
seria absurdo.

## O dia inteiro entra e sai de cada mudança

Tudo o que a tela faz com o dia está em
[`register.ts`](../../web/src/day/register.ts), em funções puras que recebem o
dia e devolvem outro. Não é preciosismo: o que esta tela tem de difícil não é
desenhar o formulário, é **não perder nada** ao mexer numa parte dele.

Com o dia inteiro atravessando cada função, o que não foi tocado chega intacto
do outro lado — e quem grava recebe sempre o dia completo, que é o que o
contrato exige, já que a lista que sobe **é o dia todo e não um acréscimo**.

Toda mudança passa por `touch`, que carimba a edição com o relógio do aparelho.
É "quando ela mexeu", não "quando chegou": é esse carimbo que decide a
convergência quando duas merendeiras registram o mesmo dia
([decisão 5 da E5](decisoes-tecnicas.md)).

**Não há botão de salvar** (decisão 3 da E3). Cada tecla vira rascunho no
aparelho na hora; quem leva ao servidor é a fila. A faixa logo abaixo do
cabeçalho é que diz em que pé está o envio, e o rodapé repete a promessa em uma
linha: _"Salva sozinho, sem botão de salvar."_

## O dia não letivo, e o meio do caminho

Marcar "dia não letivo" recolhe o resto da tela e deixa só a observação (RNF#1
e CA#1 da US006). O servidor leva a regra à letra: dia não letivo **não tem**
refeições nem número de refeições, e sem a observação a gravação é recusada.

Daí o detalhe que mudou a camada local. Entre marcar a alternância e escrever o
motivo passam alguns segundos — procurar o campo, abrir o teclado, pensar na
frase. Se o dia fosse para a fila nesse intervalo, o servidor devolveria
`23514` e a faixa passaria a dizer _"ainda não deu para enviar"_ para quem não
fez nada de errado.

Então a fila passou a perguntar, antes de tentar, se o servidor aceitaria
aquele dia — é o `canBeSent` de [`day.ts`](../../web/src/local/day.ts). O que
não pode subir **fica guardado no aparelho** e sobe sozinho assim que o motivo
existir. A faixa continua dizendo a verdade: salvo no aparelho. Embaixo do
campo, uma linha diz o que falta sem chamar de erro o que é apenas o meio do
caminho: _"Escreva o motivo para este dia entrar no mapa."_

Hoje essa é a única dobra; quando a alteração do cardápio chegar (#63), as
recusas dela entram no mesmo lugar.

### Marcar apaga as refeições; desmarcar devolve

Como o dia que sobe não pode ter refeições, marcar o dia como não letivo as tira
do payload — e não só da tela. Desmarcar devolve o que estava digitado, porque a
tela guardou o conteúdo antes de marcar (CA#3 da US006). O número de refeições
volta junto.

**A devolução é da sessão**, e isso é uma limitação declarada: uma vez gravado
como não letivo, o dia não tem mais refeições em lugar nenhum — nem no aparelho,
nem no servidor —, e recarregar a página não as traz de volta. A alternativa
seria guardar no rascunho o que o payload não leva, e aí o rascunho deixaria de
ser, campo por campo, o que sobe — que é justamente o que faz a fila ser
idempotente.

## Duas origens, e por que a leitura traz o dia inteiro

São as mesmas duas origens da [visão do mês](visao-do-mes.md), com a mesma
fronteira ([decisão 4 da E5](decisoes-tecnicas.md)): **vale o rascunho quando
ele existe** — ele só está guardado enquanto o servidor não confirmou, então é
mais novo por construção — e o servidor quando não existe.

A consulta traz o dia **inteiro**, inclusive os gêneros utilizados e a alteração
do cardápio, que esta tela ainda não edita. Não é antecipação: o que sobe é o
dia todo, e o que não vier deixa de existir. Ler pela metade faria uma correção
de uma vírgula na descrição apagar em silêncio os gêneros que a colega
registrou.

Pelo mesmo motivo, **quando a leitura falha e não há rascunho, a tela não deixa
escrever**: mostra o que não se perdeu e oferece tentar de novo. Um formulário
em branco por cima de um dia que existe no servidor seria a maneira mais rápida
de apagá-lo.

### Quando a colega editou depois

Se a edição dela perder a convergência, o rascunho sai do aparelho e o que vale
passa a ser o dia do servidor. A tela ainda está com o texto antigo na mão —
então, ao ver o aviso de conflito daquela data, ela relê as duas origens. O
aviso continua sendo o da camada local, e não some sozinho: _"confira se está
como você deixou"_ só faz sentido depois da releitura.

## O dia bloqueado abre, e abre só para consulta

Um dia incluído em documento gerado é somente leitura para a merendeira (RN#1 da
US007) — mas continua abrindo, porque é justamente o dia que ela vai querer
conferir depois de gerar o documento. Os campos ficam desabilitados e uma faixa
diz o porquê e para onde ir: _"Este dia já está em um documento gerado, por isso
abre só para consulta. A direção pode reabrir o mapa para correção."_

O `locked` é lido do servidor, que é o único que o conhece. Quando a consulta
não responde e a tela abre pelo rascunho, o bloqueio não é conhecido; se o dia
tiver sido bloqueado nesse meio-tempo, quem recusa é a gravação, e a mensagem
dela aparece na faixa de salvamento.

## O cabeçalho: andar entre dias, e o caminho de volta

O desenho da E3 não tem botão de voltar, e isso não foi esquecimento: no
aplicativo Android quem volta é o botão do aparelho. As setas do cabeçalho são
**dia anterior** e **próximo dia** — é com elas que ela transcreve o cardápio da
semana, seguindo em frente sem passar pelo mês a cada dia.

Na web não existe esse botão do aparelho. Em vez de mudar o desenho
compartilhado, a web ganhou um link no texto que já estava ali: o subtítulo com
o nome do mês volta para a visão do mês, no mês do dia aberto. O desenho da tela
3 continua valendo para as duas plataformas.

A data vai na barra de endereço (`/dia/2026-09-10`), como o mês vai na da visão
do mês: recarregar com F5 não pode jogá-la em outro dia. Data que não existe —
`/dia/2026-02-31` — volta para a tela-casa.

## O que ficou de fora, e onde continua

| O que                             | Onde continua |
| --------------------------------- | ------------- |
| Gêneros utilizados, com o stepper | #63           |
| Alteração do cardápio             | #63           |

Os dois são do mesmo cartão e da mesma issue, e ficam **fora** da tela em vez de
aparecerem desabilitados: botão que não faz nada é promessa falsa, e aqui não há
o que explicar no lugar dele. O que já existe no banco continua sendo lido e
devolvido intacto no envio — o que a tela não mostra, ela também não apaga.

## Verificação

Os testes rodam com `npm test` e se dividem pela mesma razão que o domínio é
separado da tela: o que pode estar errado aqui é a regra.

[`register.test.ts`](../../web/src/day/register.test.ts) — as regras, sem React:

| Cenário                                         | O que se afirma                               |
| ----------------------------------------------- | --------------------------------------------- |
| Descrição sem aceitação, e o contrário          | a refeição é pendente, não preenchida         |
| Descrição só com espaços                        | a refeição continua vazia                     |
| Dia em branco, dia começado                     | abre na primeira refeição que falta           |
| Andamento do dia letivo e do não letivo         | quatro partes e uma parte                     |
| Escrever numa refeição                          | não mexe nas outras nem no número do dia      |
| Marcar dia não letivo                           | tira refeições e número do payload            |
| Desmarcar                                       | devolve o que estava digitado (CA#3 da US006) |
| Número de refeições: letra, vírgula, zero, teto | só dígitos, zero é vazio, corta no `smallint` |

[`day-register.test.tsx`](../../web/src/day/day-register.test.tsx) — a tela,
critério por critério da issue #62:

| Cenário                        | O que se afirma                                  |
| ------------------------------ | ------------------------------------------------ |
| Digitar e escolher a aceitação | está no aparelho, sem botão de salvar            |
| Três refeições e o número      | sobem numa carga só, com a data do dia           |
| Só a descrição                 | registro parcial é aceito (CA#3 da US001)        |
| Os três botões                 | um toque, um escolhido por vez (US004)           |
| Campo do número                | teclado numérico, só dígitos, − e + (US005)      |
| Marcar dia não letivo          | recolhe as refeições e pede o motivo (US006)     |
| Desmarcar                      | devolve a descrição, a aceitação e o número      |
| Dia bloqueado                  | abre, explica e não deixa editar (CA#2 da US007) |
| Leitura que não veio           | não deixa escrever por cima, e oferece de novo   |
| Cabeçalho                      | anda entre dias e volta para o mês               |

A trava de envio do dia não letivo é verificada do lado da fila, em
[`sync.test.ts`](../../web/src/local/sync.test.ts) e
[`day.test.ts`](../../web/src/local/day.test.ts): o dia sem observação fica
guardado e não é enviado, e sobe assim que o motivo existe.
