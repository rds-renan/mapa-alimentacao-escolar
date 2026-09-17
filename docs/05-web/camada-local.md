# A camada local: rascunho, fila de envio e convergência

O que a merendeira digita é escrito no aparelho **antes** de qualquer conversa
com o servidor, e o envio é uma fila que se repete sozinha até o servidor
confirmar. É a decisão 3 da E5 virando código, e o coração das US010 e US011 —
a dor mais forte da entrevista da E1 foi perder preenchimento, e é esta camada
que responde a ela.

Ela mora em [`web/src/local/`](../../web/src/local/) e não tem tela: quem a
consome são o registro do dia (issue #62) e a visão do mês (issue #61). O que
está aqui é o mecanismo, a faixa que o mostra e as regras de quem ganha quando
dois aparelhos escrevem o mesmo dia.

Vale repetir o recorte da [decisão 2](decisoes-tecnicas.md), porque é fácil ler
"offline" e supor mais do que foi prometido: **na web, o offline garante que
nada se perde.** Abrir o aplicativo do zero, navegar o mês e consultar o
catálogo continuam exigindo rede. O funcionamento integral sem conexão é do
aplicativo Android, na E6.

## Um depósito só, e a regra que ele carrega

O rascunho e a fila de envio parecem duas coisas, e são uma. No IndexedDB existe
um único depósito, o dos dias guardados — e **estar guardado ali é ser dia que o
servidor ainda não confirmou**.

É essa igualdade que dá corpo à RN#1 da US011 (o dado local não se descarta
antes de confirmado no servidor): não há um lugar onde o dado esteja "salvo" e
outro onde ele esteja "na fila", com a pergunta de qual dos dois está certo.
Confirmado, o dia sai do aparelho e passa a ser lido do servidor, que é
exatamente a fronteira que a [decisão 4](decisoes-tecnicas.md) desenhou — a
TanStack Query cuida do que veio do servidor, e a escrita que ainda não subiu é
nossa.

O que se guarda de cada dia é, campo por campo, o **payload de
`save_meal_map`**: a mesma forma descrita na [gravação do dia](gravacao-do-dia.md),
sem tradução no meio. Enviar é pegar o que está no disco e mandar. Uma camada de
conversão entre o que se grava e o que se envia seria mais um lugar para
divergir do contrato do servidor, calada, até o dia em que um campo some.

Cada dia carrega de quem ele é. As duas merendeiras se revezam no mesmo
aparelho, e toda leitura da fila é por usuária: o rascunho de uma não aparece
para a outra, nem sobe na conta dela.

## O que a fila faz com cada resposta

A distinção que decide tudo é **o que se resolve reenviando e o que não se
resolve**. A tabela de erros da gravação do dia é a fonte:

| Resposta | O que a fila faz |
|---|---|
| `saved` | O dia adota o identificador do mapa e os dos gêneros que voltaram, e sai do aparelho. |
| `saved`, mas ela digitou durante o envio | Adota os identificadores e **fica**: o que está no aparelho já é mais novo que o confirmado. |
| `superseded` | O caso é sinalizado à usuária e o dia sai do aparelho — a tela recarrega o do servidor. |
| `40001` | Fica na fila. Dois aparelhos criaram o mesmo dia no mesmo instante; na segunda vez vale a comparação de datas. |
| Falha de rede | Fica na fila, e a próxima tentativa espera o dobro da anterior, até o teto de um minuto. |
| `23514`, `42501` | Para de insistir, e mostra a frase que o servidor mandou. |

A reentrega é inofensiva porque o carimbo de edição vai junto e não muda entre
tentativas: reenviar é reescrever o mesmo dia, com a mesma data de edição, e dá
o mesmo dia. É o que impede que uma rede caindo entre a gravação e a confirmação
vire mapa repetido.

A rede voltando dispara o envio sozinha — o aplicativo escuta o `online` do
navegador e a volta da aba ao primeiro plano (CA#1 da US011). Sem rede a fila
**não tenta**: a tentativa falharia do mesmo jeito, e a faixa passaria a dizer
"ainda não deu para enviar" quando a frase verdadeira é a outra.

### Uma correção ao contrato: recusada não quer dizer descartada

A [gravação do dia](gravacao-do-dia.md) diz, para `23514` e `42501`, "tira o item
da fila, porque reenviar dá o mesmo erro". Metade disso vale e metade não: o item
para de ser reenviado, mas **o dia continua guardado no aparelho**. Jogá-lo fora
seria perder o que ela digitou por causa de um campo torto, que é precisamente o
que a RN#1 da US011 proíbe. Ele volta à fila sozinho no instante em que ela
corrigir, porque corrigir é escrever o rascunho de novo.

## Digitar enquanto o envio está no ar

O autosave e a fila correm juntos, e isso não é exceção: é o caso comum. O envio
pode levar segundos ou horas, porque a rede pode simplesmente não existir na
hora, e ela continua preenchendo o dia nesse meio-tempo.

Por isso a confirmação do servidor não apaga o que está no aparelho sem antes
**comparar**: sai da fila o dia cujo carimbo de edição é o mesmo que subiu, e o
que mudou depois disso fica, para subir na volta seguinte. É a comparação que
separa "o servidor já tem exatamente isto" de "o servidor tem a versão de dois
minutos atrás". Sem ela, confirmar um envio apagaria tudo o que foi escrito
enquanto ele viajava.

Duas outras proteções são de ordem entre operações assíncronas, e não de espera:
a comparação e a saída da fila acontecem numa transação só do IndexedDB, e a
leitura do rascunho ao abrir a tela não sobrescreve uma edição feita enquanto
ela estava no ar. Custam poucas linhas e fecham a possibilidade de uma escrita
chegar entre a leitura e a decisão.

Vale registrar a medida, para ninguém superdimensionar isto depois: ler um dia
cheio do IndexedDB leva **0,6 ms** no computador e **2,1 ms** com a CPU seis
vezes mais lenta — dentro de um quadro de tela. Ninguém digita nesse intervalo.
Quem faz esperar de verdade é a rede, e espera se resolve na tela, com estado de
carregando, não com estrutura de dados.

## As três frases, e a quarta que a E3 não previu

Não há botão "Salvar". Quem diz em que pé está o registro é a faixa da
[decisão 3 da E3](../03-ux/decisoes-de-design.md), com os três textos dela, ao
pé da letra:

| Estado | Frase |
|---|---|
| Salvo no aparelho | "Salvo no aparelho. Envia sozinho quando houver internet." |
| Enviado | "Enviado. Este mapa já está disponível para gerar o documento." |
| Falha de envio | "Ainda não deu para enviar. Nada foi perdido, vamos tentar de novo." |

Quando a recusa tem explicação própria — uma quantidade inválida, um mapa já
dentro de um documento gerado —, a frase do servidor entra depois da terceira.
Ela já vem legível para quem vai lê-la: não há tradução a fazer no cliente.

Um dia que ela ainda não tocou **não mostra faixa nenhuma**. Dizer "enviado"
antes da primeira tecla seria a faixa mentindo.

**A quarta frase é o conflito, e a E3 não a desenhou.** O catálogo previu três
estados, e nenhum deles é "outro aparelho registrou este dia depois de você" —
que é o caso que a [decisão 5](decisoes-tecnicas.md) manda sinalizar e nunca
resolver em silêncio. O texto entra aqui, com a origem declarada, como já se fez
na E3 com as telas que nasceram do desenho e não do levantamento:

> O dia 10/09 foi registrado em outro aparelho depois da sua edição, e o que
> vale é o registro mais recente. Confira se está como você deixou.

Ele foge da regra "o erro diz primeiro o que não se perdeu" de propósito: aqui
alguma coisa se perdeu de verdade, e dourar isso mandaria ela seguir sem olhar a
tela. O que a regra preserva é o resto — não culpa ninguém, não chama aquilo de
"conflito de sincronização" e não some sozinho: some quando ela disser que leu.

## Sair apaga tudo, e quem decide é ela

Sair do aplicativo apaga o que era da pessoa no aparelho (CA#5 da issue #59),
**inclusive o dia que ainda não subiu**. Quando há algo por enviar, ela é
avisada antes e escolhe.

Isso contraria a leitura literal da RN#1 da US011, e é deliberado. A web é uso
raro neste produto — o registro do dia acontece no celular —, e ficar sem
internet num computador é bem mais raro do que num celular. O cenário que
justificaria guardar, preencher sem rede e voltar depois para enviar, quase não
existe aqui. Já o custo de guardar é alto: um dia parado neste depósito pode
esperar **meses**, por uma pessoa que talvez nunca mais entre, e chegar ao
servidor num formato que o sistema já não reconhece. É o tipo de defeito que
aparece dois meses depois de alguém mexer no esquema, sem nada na tela que o
explique — e guardar dado indefinidamente atrelado a uma sessão que pode mudar
e a um perfil que pode ser desativado é risco que não se paga.

O que torna a escolha legítima é o aviso, e a frase diz o que se perde:

> Ainda tem 1 dia salvo neste computador que não foi enviado. Se sair agora, ele
> se perde.

Perder por escolha dela é uma coisa; perder por decisão do sistema seria outra.
O botão que apaga também diz que apaga: "Sair e apagar", ao lado de "Ficar".

**Detalhe que quase passou em branco**: banco com conexão aberta não se apaga —
`deleteDatabase` dispara `onblocked` e fica esperando. A fila mantém a conexão
viva, então a saída fecha antes de apagar. Sem isso, o apagamento falharia em
silêncio e o depósito sobreviveria à saída.

A preferência de tema (US024) continua fora disso por outro motivo: ela é
escolha do aparelho, não atributo da pessoa (decisão 12 da E4).

## O que esta camada não faz

- **Não lê o servidor.** Ela só escreve. Quem busca o mês, o catálogo e os
  documentos é a TanStack Query, e ela entra com a primeira tela que precisar
  ler — a visão do mês (issue #61). Adicionar a biblioteca agora seria
  dependência por antecipação.
- **Não guarda leitura para uso offline.** Persistir cache é sobre leitura, e o
  que este produto precisa persistir é escrita que ainda não subiu
  ([decisão 4](decisoes-tecnicas.md)).
- **Não instala service worker nem transforma a web em PWA.** É o recorte da
  [decisão 2](decisoes-tecnicas.md), e ele é deliberado.
- **Não decide conflito sozinha.** Quem compara as datas é o servidor, dentro da
  mesma operação atômica que grava o dia. Aqui só se obedece e se avisa.

## Verificação

Os testes estão ao lado do código, em
[`web/src/local/`](../../web/src/local/), e rodam com `npm test`. O servidor
deles é de mentira, mas o contrato é o de verdade: as respostas e os códigos de
erro são os que `save_meal_map` devolve.

| Cenário | O que se afirma |
|---|---|
| Autosave e reabertura do navegador | o rascunho sobrevive ao fechar (CA#2 e CA#3 da US010) |
| Rascunho da colega | não aparece para a outra merendeira |
| Envio confirmado | o dia sobe numa chamada só e só então sai do aparelho |
| Reenvio | mesma carga, mesmo carimbo — sem registro duplicado |
| Sem rede | não tenta, e a faixa diz "salvo no aparelho" |
| Rede voltando | reenvia sozinha, sem ação da usuária (CA#1 da US011) |
| Tecla durante o envio | os identificadores são adotados e o texto novo não se perde |
| `superseded` | conflito sinalizado, e o que veio depois continua subindo |
| `23514` | para de insistir, mostra a frase do servidor, não descarta o dia |
| `40001` | continua na fila e sobe na tentativa seguinte |
| As três frases | comparadas palavra por palavra com a tabela da E3 |
| Leitura do rascunho chegando atrasada | não sobrescreve a edição feita no meio-tempo |
| A fila ligada à tela | gravar, ver a faixa mudar e receber o aviso de conflito |
| Sair da conta | avisa antes, e o que não subiu é apagado de fato |

Fora dos testes, o contrato foi conferido à mão contra o Supabase local, com as
duas merendeiras do seed: primeira gravação, reenvio idêntico, correção da colega
no dia seguinte, a edição antiga chegando depois, quantidade zero e a direção
tentando registrar. Seis chamadas, um mapa na data, nenhum gênero duplicado — e
o `superseded` aparecendo exatamente onde devia.

Uma armadilha que vale registrar, porque custou uma investigação: **data de
edição no futuro é reduzida ao instante da chegada** pelo servidor, de propósito,
para que um aparelho com o relógio adiantado não ganhe todo conflito para sempre.
Conferir a convergência com datas futuras faz tudo parecer quebrado.
