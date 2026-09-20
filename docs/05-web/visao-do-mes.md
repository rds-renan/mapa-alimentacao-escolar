# A visão do mês e o menu do aplicativo

A tela-casa da merendeira responde a uma pergunta só, que hoje ela responde de
cabeça e de caderno: **o que ainda falta antes de gerar o mapa?** É a US008, e
é também o lugar de onde partem os dois caminhos do produto — abrir um dia e
gerar o documento. Ao lado dela entra o menu (US020), a porta do que não
pertence ao fluxo diário.

São as telas 2 e 2a da E3. O código está em
[`web/src/month/`](../../web/src/month/) (o domínio, as consultas e as peças da
lista), [`web/src/pages/MonthView.tsx`](../../web/src/pages/MonthView.tsx) (a
tela) e [`web/src/components/app-menu.tsx`](../../web/src/components/app-menu.tsx)
(o menu).

## Lista de dias, e não calendário em grade

Num calendário de sete colunas cabe o número do dia e mais nada. O que decide o
que ela vai fazer não é o número — é a linha ao lado dele, que diz *"falta o
lanche da tarde"*. Por isso a tela é uma lista vertical, agrupada por semana, e
cada dia ocupa uma linha inteira com três coisas: a data, o que o dia tem (ou o
que falta nele) e a etiqueta de estado.

O agrupamento quebra na **segunda-feira**, não a cada sete dias corridos: num
mês que começa numa quinta, um bloco de sete arrastaria o sábado seguinte para
dentro da primeira semana e a "Semana 1" deixaria de ser a semana que ela
chama de semana 1.

**Fim de semana não aparece** — a RN#1 da US008 diz que ele não conta como
pendência, e listar oito linhas mortas por mês num aparelho de 390 px é caro.
A exceção é o sábado ou domingo que **tem registro**: a regra é sobre
pendência, não sobre esconder o que existe, e um dia registrado que não
aparecesse na lista ficaria sem porta por onde ser corrigido.

## Os cinco estados, derivados a cada desenho da tela

A [decisão 4 da E4](../04-banco-de-dados/decisoes-de-modelagem.md) é levada à
letra: **só o bloqueio vem gravado do servidor**; vazio, pendente e completo
são calculados na leitura, e não letivo é o atributo do próprio mapa. Toda essa
derivação mora em [`month.ts`](../../web/src/month/month.ts), em funções puras
sobre texto e número — sem rede e sem React, porque o que esta tela tem de
difícil é a regra, não o desenho.

| Estado           | Como se chega nele                                           | Como aparece                             |
| ---------------- | ------------------------------------------------------------ | ---------------------------------------- |
| **Vazio**        | nenhum registro, ou um registro em que ninguém escreveu nada | cinza, círculo tracejado, "Sem registro" |
| **Pendente**     | começado e incompleto                                        | âmbar, relógio, e a frase do que falta   |
| **Preenchido**   | as três refeições e o número de refeições                    | verde, círculo com visto                 |
| **Não letivo**   | `non_school_day`, com a observação                           | azul, calendário riscado, e a observação |
| **No documento** | `locked`, gravado pelo servidor na geração                   | cinza, cadeado                           |

**"Completo" exige a aceitação**, e não só a descrição: o CA#3 da US004 diz que
não se conclui o registro de uma refeição servida sem informá-la. Gêneros
continuam opcionais (RN#3 da US001) e por isso não entram na conta.

**O bloqueio ganha de todos os outros.** É o único estado que muda o que ela
*pode fazer* — o dia saiu num documento oficial e virou somente leitura (RN#1
da US007). Saber que ele também estava completo não muda nada para ela. Um dia
não letivo bloqueado mostra o cadeado, e a observação continua na linha de
apoio.

### Cor e ícone, nunca só cor

É o RNF#1 da US008, e aqui ele não é formalidade de acessibilidade: quem lê
esta lista pode estar com o celular na bancada da cozinha, com a tela lavada de
luz. Cada etiqueta leva ícone junto da cor, e "no documento" e "vazio"
partilham o mesmo cinza de propósito, como no desenho da E3 — o que os separa é
o cadeado, e é ele que precisa ser legível.

A linha inteira é um **link**, não um botão: o destino é um endereço, e isso faz
o "abrir em nova aba" e o botão de voltar do navegador funcionarem sem código
nosso. O leitor de tela recebe a linha como uma frase única — *"3 de setembro,
pendente. falta o lanche da tarde"* —, e a etiqueta visual fica marcada como
decorativa para não ser anunciada duas vezes.

## O andamento do mês

O cartão do topo é o resumo que hoje ela não tem: quantos dias estão prontos de
quantos dias letivos, e a repartição do resto. **Dia letivo** é o dia listado
que não foi marcado como não letivo — é por isso que o contador do cabeçalho
cai de 22 para 21 quando ela marca um conselho de classe. **Pronto** é completo
ou já dentro de um documento.

Estado zerado não aparece na repartição: *"0 pendentes"* ocupa espaço para
dizer que nada aconteceu, e a linha existe justamente para ela achar rápido o
que falta.

## Duas origens que não se misturam

É a fronteira da [decisão 4](decisoes-tecnicas.md) virando código, e esta é a
primeira tela do projeto que **lê** do servidor — por isso é aqui que a TanStack
Query entra, e não na fundação.

- **O servidor** é assunto da Query: uma consulta por mês, recortada por
  `map_date`, trazendo o mapa e as suas refeições. Não há filtro de escola na
  consulta — quem recorta é o RLS da E4. Repeti-lo aqui daria a impressão de
  que é ele que protege, e não é ([decisão 6](decisoes-tecnicas.md)).
- **O aparelho** é assunto da [camada local](camada-local.md): os dias que
  ainda não subiram. Sem eles, um dia preenchido ontem à noite e ainda na fila
  apareceria **vazio** na lista que ela usa para saber o que falta — o oposto
  do que a tela existe para fazer.

Quando as duas origens têm o mesmo dia, **o rascunho vale**: ele é mais novo por
construção, porque só continua guardado enquanto o servidor não confirmou. A
única coisa que não se herda do rascunho é o **bloqueio**, que ele não tem como
conhecer: esse continua vindo da linha do servidor, senão um dia já dentro de um
documento voltaria a parecer editável.

A fila também comanda a revalidação: quando ela confirma alguma coisa, o que o
servidor tem passou a ser diferente do que a tela leu, e os meses em cache são
invalidados. Todos, e não só o aberto — a fila pode ter subido um dia de outro
mês enquanto ela olhava este.

### Quando a lista não vem

Vale repetir o recorte da [decisão 2](decisoes-tecnicas.md), porque é fácil ler
"offline" e supor mais do que foi prometido: **na web, navegar o mês exige
rede**; o offline integral é do aplicativo, na E6. Então a falha de carga não é
mascarada — a tela diz que não deu para carregar **a lista**, afirma que o que
ela registrou continua guardado, conta quantos dias ainda esperam no aparelho e
oferece tentar de novo.

Mostrar o mês "pela metade", só com o que está no aparelho, seria pior que não
mostrar mês nenhum: os dias que o servidor já tem apareceriam como vazios, e é
contando os dias que faltam que ela decide gerar o documento.

## O mês vai na barra de endereço

O mês aberto é um parâmetro da URL (`/?mes=2026-05`), não estado de memória.
Na web o F5 acontece, e recarregar enquanto ela confere o mês passado não pode
jogá-la de volta em hoje. A navegação entre meses é livre nos dois sentidos:
adiantar dias transcrevendo o cardápio é uso esperado (US001), e conferir o mês
passado é o que ela faz antes de gerar.

## O menu

É a [decisão 9 da E3](../03-ux/decisoes-de-design.md): a porta do que não é
fluxo diário. **Um toque a partir da tela inicial** (RNF#1 da US020) — o botão
está no cabeçalho e o que ele abre já é o menu inteiro, sem nível
intermediário. Ele reúne **Documentos gerados**, **Gerenciar gêneros**, **Tema
escuro** e **Sair** (CA#2 da US020).

Ele **não interrompe registro em andamento** (CA#1 da US020), e isso não custou
código: o rascunho do dia mora no aparelho e não depende de tela nenhuma estar
aberta.

O menu não tem caminho para a área da direção (RN#1 da US020) — e, como sempre,
isso é cortesia de interface, não segurança: quem impede a leitura são as
políticas de RLS ([decisão 6](decisoes-tecnicas.md)).

**Sair mudou de lugar.** Ele morava no cabeçalho da tela-casa desde a issue #59,
à espera do menu, e o próprio código dizia isso. Agora está onde a E3 o
desenhou. O aviso de mapa por enviar continua igual.

## O que ficou de fora, e onde continua

A tela foi feita antes dos seus destinos, e isso é deliberado: um caminho que
não leva a lugar nenhum é pior que um que leva a uma tela dizendo de quem ela
é. Cada issue seguinte substitui um arquivo destes.

| O que               | Onde está hoje                          | Issue |
| ------------------- | --------------------------------------- | ----- |
| Registro do dia     | pronto — ver [o registro do dia](registro-do-dia.md) | #62   |
| Documentos gerados  | tela-marco, alcançada pelo menu         | #67   |
| Catálogo de gêneros | pronto — ver [o catálogo de gêneros](catalogo-de-generos.md) | #64   |
| Tema escuro         | item do menu, à vista e inerte          | #71   |
| Gerar documento     | pronto — ver [a seleção de mapas](selecao-de-mapas.md) | #66   |

O item do tema fica **visível e inerte** porque é parte do desenho desta tela,
não da seguinte: tirá-lo e recolocá-lo depois custaria mais do que deixá-lo
explicado. O botão do rodapé esteve assim até a issue #66, e hoje leva à
seleção de mapas, com o mês aberto junto no endereço — a tela 5 não tem
navegação de mês, então o mês de onde ela veio é o que diz quais dias mostrar.

## Verificação

Os testes estão ao lado do código e rodam com `npm test`. Eles se dividem em
dois, pela mesma razão que o domínio é separado da tela: o que pode estar
errado aqui é a regra.

[`month.test.ts`](../../web/src/month/month.test.ts) — a regra, sem React:

| Cenário                                   | O que se afirma                                       |
| ----------------------------------------- | ----------------------------------------------------- |
| Registro que existe mas está em branco    | é vazio, não pendente                                 |
| Falta a aceitação de uma refeição         | continua pendente (CA#3 da US004)                     |
| Falta o número de refeições               | continua pendente                                     |
| Dia bloqueado, completo ou não letivo     | o bloqueio vem na frente                              |
| O que falta, no singular e no plural      | "falta o lanche da tarde", "faltam as três refeições" |
| Fim de semana                             | fora da lista, salvo quando tem registro              |
| Quebra das semanas                        | na segunda-feira, num mês que começa numa terça       |
| Andamento                                 | não letivo sai do total de dias letivos               |
| Virada de ano e fevereiro bissexto        | o recorte do mês fecha no dia certo                   |
| Rascunho e linha do servidor no mesmo dia | o rascunho vale, o bloqueio não                       |

[`month-view.test.tsx`](../../web/src/month/month-view.test.tsx) — a tela, com o
relógio fixado em 9 de setembro de 2026 (uma quarta-feira), porque o mês que a
tela abre, o destaque de "hoje" e a quebra das semanas dependem todos da data:

| Cenário                   | O que se afirma                                    |
| ------------------------- | -------------------------------------------------- |
| Os cinco estados na lista | cada etiqueta tem cor **e** ícone (RNF#1 da US008) |
| Toque num dia             | abre o registro daquele dia (CA#2 da US008)        |
| Toque num dia bloqueado   | também abre: somente leitura não é inalcançável    |
| Navegação entre meses     | e o mês do endereço sobrevive ao F5                |
| Dia guardado no aparelho  | aparece preenchido antes de subir                  |
| Falha de carga            | diz o que não se perdeu e oferece tentar de novo   |
| Menu                      | um toque, e reúne os quatro itens (CA#2 da US020)  |
| Menu                      | nenhum caminho para a direção (RN#1 da US020)      |
