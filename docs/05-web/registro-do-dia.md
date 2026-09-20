# O registro do dia

É a tela central do produto: o lugar onde a merendeira transcreve o cardápio de
cada uma das três refeições, avalia a aceitação, anota os gêneros que usou,
registra a troca quando houve uma, informa o número de refeições do dia e,
quando é o caso, marca o dia como não letivo. É a US001 — com a US002, a US003,
a US004, a US005, a US006, a US007 e a US009 dentro dela — e são as telas 3, 3a
e 3b da E3.

O código está em [`web/src/day/`](../../web/src/day/) (as regras, a consulta, os
cartões e as duas telas que sobem sobre o registro) e em
[`web/src/pages/DayRegister.tsx`](../../web/src/pages/DayRegister.tsx) (a tela).
A leitura do catálogo de gêneros mora fora, em
[`web/src/food-items/`](../../web/src/food-items/), porque é do catálogo e não
do dia: a [manutenção dele](catalogo-de-generos.md) entra pela mesma porta. O que a tela grava e
envia é da [camada local](camada-local.md); o contrato do que sobe é a
[gravação do dia](gravacao-do-dia.md).

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

Abaixo da aceitação vêm os **gêneros utilizados**, opcionais (RN#3 da US001), e
por último a **alteração do cardápio**, que enquanto não existe é só um botão.
Os dois são do cartão porque são da refeição: as merendeiras sabem de cabeça o
que foi de cada uma, e é a geração do documento que junta as três numa célula
só ([decisão 7 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)).

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

## A refeição é o cardápio previsto, e o rótulo passou a dizer isso

A linha da refeição **não muda** quando houve troca: ela continua sendo o
cardápio previsto, com a sua aceitação ([decisão 8 da E3](../03-ux/decisoes-de-design.md),
[decisão 7 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)). É essa
permanência que dá sentido à justificativa — se a descrição já fosse reescrita
com o que foi servido, não haveria divergência aparente e não haveria o que
justificar.

O desenho da E3 rotulava o campo como *"Cardápio realizado"*, que é o nome da
coluna do formulário oficial. Na tela ele pedia o contrário do que a tela 3a
diz duas telas adiante — _"o almoço continua registrado como o cardápio
previsto"_ —, e quem lê o rótulo é quem está digitando, não quem vai montar o
documento. O campo passou a se chamar **"Cardápio previsto"**, na web e no
desenho; o nome da coluna do formulário continua onde ele importa, na geração
do documento.

## Os gêneros utilizados, e a alteração do cardápio

São duas listas com a mesma forma e o mesmo gesto, e são duas de propósito:
alimentam **colunas diferentes** do documento oficial — os gêneros da refeição
e os gêneros da troca. Por isso a lista é uma peça só no código
([`food-item-list.tsx`](../../web/src/day/food-item-list.tsx)) usada nos dois
lugares: desenhá-la duas vezes faria as duas divergirem na primeira correção.

A quantidade é um stepper de inteiros com a unidade do catálogo ao lado
(decisão 2 da E3, RN#1 da US003). O "−" e o "+" resolvem o caso comum num
toque, e o número do meio é campo de verdade, com teclado numérico, porque 12
potes não se alcançam a toques. **O "−" de quem está em 1 tira o gênero da
lista**: quantidade zero não existe no banco, então o botão precisava parar em
1 ou remover — e remover é o que ela quer, já que o item foi posto ali por
engano. Um cesto de lixo em cada linha encheria o cartão de ícone para um gesto
que o "−" já nomeia; o leitor de tela é avisado, porque o rótulo do botão muda
para _"Tirar Arroz da lista"_ quando ele vai remover.

O mesmo gênero não entra duas vezes na mesma lista, e repetir o gesto **não**
devolve a quantidade para 1. A chave da lista é o nome normalizado, e não o
identificador, porque é assim que o servidor decide se dois gêneros são o
mesmo: ele funde os repetidos numa linha só valendo a última quantidade, que
apagaria em silêncio o número que ela já tinha ajustado.

### Escolher gênero sem sair do registro

"Adicionar gênero" abre a folha da tela 3b sobre o dia (decisão 7 da E3): busca
no catálogo e, no fim da lista, o cadastro de um gênero novo com a sua unidade
padrão. A busca ignora acento e caixa — "feijao" acha "Feijão" —, e o item
escolhido entra na refeição já com a quantidade em 1. O que já está na lista
aparece marcado e não se escolhe de novo.

O gênero cadastrado ali **nasce no envio**, não na hora: `save_meal_map` cria no
catálogo o que ainda não existir, na mesma operação que grava o dia. É isso que
permite cadastrar sem rede. Quando a fila confirma, a leitura do catálogo é
invalidada junto com a dos dias, senão o gênero recém-nascido ficaria fora da
busca até a consulta envelhecer.

A unidade é escolhida entre seis sugestões, sem campo livre. No banco ela é
texto curto e a lista **não** é fechada ([decisão 8 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)),
mas quem abre o leque é a [manutenção do catálogo](catalogo-de-generos.md): no meio de uma refeição
são seis toques e nenhum teclado, e é isso que faz o pior caso — o gênero não
existe — caber em dois gestos.

Sem catálogo (a folha abriu offline, ou a leitura falhou) o cadastro continua de
pé, com a mensagem dizendo o que aconteceu. Ficar sem poder registrar porque a
lista não veio seria perder preenchimento por falta de rede, que é justamente o
que o produto promete não fazer.

### As duas sobreposições ficam dentro da coluna

A tela 3a toma a tela inteira e a folha 3b sobe por baixo — no celular, que é o
desenho. Na web o fluxo da merendeira é o mesmo desenho num **container
central** de 390 px (decisão 1 da E3), e as duas nasceram presas à janela em
vez de à coluna: no monitor, a folha se esticava de ponta a ponta sobre uma
coluna estreita.

As duas passaram a respeitar o mesmo `max-w-screen` do resto do fluxo. O mesmo
desenho nas duas plataformas não quer dizer o mesmo número de pixels — quer
dizer a mesma largura de leitura, que é o que a decisão 1 comprou ao dispensar
telas próprias para a web. A centralização é por margem automática, e não por
`translate`, porque as animações de entrada e saída já usam o `transform` do
elemento.

### A alteração registra o que entrou, e aparece no cartão

A tela 3a tem os gêneros usados na troca e o motivo em texto livre, com
sugestões de motivos frequentes (RNF#1 da US002). **Não há campo para o item que
saiu** — o formulário oficial não o pede em lugar nenhum —, e há no máximo uma
alteração por refeição: a justificativa cobre a modificação inteira e os gêneros
são uma lista, então duas trocas no mesmo almoço são um registro só (RN#2).

Registrada, ela aparece **dentro do cartão da refeição**, com os gêneros
resumidos e o motivo embaixo, tocável para editar. Tem de aparecer porque é o
que sai impresso: sem isso, a merendeira abriria a tela 3a no escuro para
lembrar o que registrou. O resumo pluraliza a unidade com um "s" simples
("3 bandejas de ovo") — as seis unidades sugeridas pluralizam assim, e o
documento oficial não passa por aqui, porque lá o formato é "N unidade" (CA#3
da US003).

### Confirmar não é salvar

O desenho da tela 3a tem "Cancelar" e "Confirmar alteração", e o CA#2 da US002
fala em não **concluir** uma alteração sem justificativa — mas neste aplicativo
não existe botão de salvar (decisão 3 da E3), e o que está digitado não pode
depender de ela chegar ao rodapé. Então cada tecla da tela 3a já vai para o
aparelho na hora, como em qualquer outro campo, e os dois botões decidem outra
coisa: se a alteração **fica**.

- **Confirmar** fecha. Fechar pelo X, pela tecla Esc ou pelo fundo é a mesma
  coisa — o que está escrito já está gravado, e desfazer por acidente seria a
  surpresa. A alteração aberta e fechada sem nada dentro sai do dia, em vez de
  virar um registro vazio que o servidor recusaria para sempre.
- **Cancelar** devolve a alteração como ela estava quando a tela abriu. A tela
  guarda esse retrato ao abrir, porque sem ele não haveria o que desfazer.
- **Remover a alteração** não está no desenho da E3 e entrou aqui: sem ele, o
  único caminho de volta seria tirar os gêneros um a um e apagar o motivo —
  três gestos e nenhuma pista de que o conjunto deles é "não houve troca".

Enquanto faltar o motivo ou o gênero, o dia **fica guardado no aparelho** e não
vai para a fila: é a mesma dobra do dia não letivo, descrita logo abaixo, e as
recusas dela entram no mesmo `canBeSent`. Duas linhas dizem o que falta, no
mesmo tom da observação — _"Escolha o gênero que entrou para esta alteração
valer."_ e _"Escreva o motivo para esta alteração entrar no mapa."_ —, e a
segunda também aparece no resumo dentro do cartão, que é a única pista disso
com a tela 3a fechada.

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

É a mesma dobra da alteração do cardápio, acima: o que não pode subir fica
guardado e sobe sozinho assim que ficar inteiro.

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

A consulta traz o dia **inteiro**, com os gêneros utilizados e a alteração do
cardápio dentro: o que sobe é o dia todo, e o que não vier deixa de existir.
Ler pela metade faria uma correção de uma vírgula na descrição apagar em
silêncio os gêneros que a colega registrou.

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

Reaberto o mapa, a faixa é outra, no lugar da mesma — e as duas nunca aparecem
juntas, porque o dia reaberto é, por definição, o que saiu do bloqueio. Ela diz
o que mudou e não o porquê: a justificativa da direção fica no registro de
auditoria, e não vira recado
([a reabertura de um mapa](desbloqueio-de-mapa.md)).

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

A tela do registro está inteira. O que sobra do catálogo é a **manutenção** dele
— listar, editar e desativar gênero, com a unidade em texto livre —, que é a
tela 4, alcançada pelo menu: ela ficou pronta na #64 e está descrita em
[o catálogo de gêneros](catalogo-de-generos.md). A folha 3b só lê o catálogo e
acrescenta; ela não desativa nem renomeia nada.

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
| Gênero entrando na lista                        | quantidade 1, unidade do catálogo             |
| O mesmo gênero de novo, com outra caixa         | não duplica nem devolve a quantidade para 1   |
| "−" no gênero que está em 1                     | o gênero sai da lista                         |
| Quantidade acima do teto, e abaixo de 1         | corta no `smallint`, e o mínimo é 1           |
| Gêneros da refeição e da troca                  | são duas listas, e uma não invade a outra     |
| Alteração registrada                            | descrição e aceitação não mudam (CA#3 US002)  |
| Dois gêneros na mesma troca                     | continua sendo uma alteração só (RN#2 US002)  |
| Alteração sem motivo, sem gênero, e inteira     | o dia só pode subir quando ela fica inteira   |
| Gênero a nascer sem unidade                     | o dia fica guardado                           |

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

[`menu-change.test.tsx`](../../web/src/day/menu-change.test.tsx) — as telas 3a e
3b, critério por critério da issue #63:

| Cenário                          | O que se afirma                                     |
| -------------------------------- | --------------------------------------------------- |
| Escolher um gênero do catálogo   | entra na refeição sem tirá-la da tela do registro   |
| Stepper e campo da quantidade    | inteiros, unidade do catálogo, teclado numérico     |
| "−" no gênero que está em 1      | o gênero sai da lista                               |
| Gênero novo no meio do registro  | entra na refeição com a sua unidade (CA#2 da US009) |
| Catálogo que não veio            | ainda dá para cadastrar                             |
| Busca "feijao"                   | acha "Feijão carioca" (RNF#1 da US009)              |
| Alteração registrada             | a refeição continua sendo o cardápio previsto       |
| Alteração já existente           | vira o resumo no cartão, e o botão some             |
| Sugestões de motivo              | preenchem o campo, e o texto próprio prevalece      |
| Alteração sem motivo             | fica guardada no aparelho, e a tela diz o que falta |
| Cancelar                         | devolve a alteração que estava registrada           |
| Remover                          | a alteração sai do dia e o botão volta              |
| Aberta e fechada sem nada dentro | não vira registro nenhum                            |

A trava de envio do dia não letivo é verificada do lado da fila, em
[`sync.test.ts`](../../web/src/local/sync.test.ts) e
[`day.test.ts`](../../web/src/local/day.test.ts): o dia sem observação fica
guardado e não é enviado, e sobe assim que o motivo existe.
