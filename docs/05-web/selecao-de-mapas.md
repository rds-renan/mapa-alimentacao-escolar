# Seleção de mapas e pedido de geração

A [tela 5 da E3](../03-ux/telas.md#5--seleção-de-mapas) é curta de olhar e
pesada de decidir: é a antessala do único passo irreversível do fluxo da
merendeira. Depois que o documento sai, os mapas incluídos ficam bloqueados
para edição (RN#1 da US007), e a saída do bloqueio passa a ser a direção, com
justificativa (US023).

Por isso esta tela não é só uma lista com caixas de marcar. Ela responde três
perguntas antes de deixar gerar: **o que já pode entrar num documento**, **o
que falta para o período fechar** e **o que ainda nem chegou ao servidor**. O
que ela pede está na
[Edge Function de geração](geracao-do-documento.md#como-a-edge-function-funciona),
que é quem preenche o modelo oficial e bloqueia os mapas.

![Seleção de mapas](../assets/e3-5-selecao-de-mapas.png)

## Três modos, e não três botões

O desenho da E3 tem "Mês inteiro", "Semana" e "Escolher dias" lado a lado, como
um seletor — e desenhou a tela com o terceiro aberto. Os outros dois nunca
chegaram a ser desenhados, e é essa a leitura que a implementação seguiu: são
**modos**, cada um respondendo a uma intenção diferente.

| Modo | O que faz | Buraco no período |
|---|---|---|
| Mês inteiro | marca o mês de uma vez | recusa, e diz o que falta |
| Semana | cada semana vira uma caixa no seu cabeçalho | a semana incompleta não marca |
| Escolher dias | dia a dia | permitido: é o caso dos dias avulsos |

**A tela abre no primeiro.** O RNF#1 da US013 pede que selecionar o mês inteiro
leve poucos toques; abrindo assim, são zero — a prestação de contas é mensal, e
o caso típico já está pronto quando a tela termina de carregar.

O modo "Semana" precisou de um elemento que o desenho não tem: uma caixa no
cabeçalho de cada semana. O desenho traz um botão "Semana" só, e um botão só
não diz **qual** semana — o mês tem quatro ou cinco. Marcar no cabeçalho é o
lugar onde a pergunta tem resposta.

## Quem pode entrar num documento

A régua daqui é mais dura que a da [visão do mês](visao-do-mes.md). Lá o estado
do dia descreve o que existe; aqui ele decide o que vai à prefeitura.

| O dia está | Entra? | Por quê |
|---|---|---|
| Preenchido | sim | é o caso comum |
| Não letivo | sim | também é registro do mês, e sai no documento como tal |
| **No documento** | **sim** | o bloqueio é sobre editar, nunca sobre sair de novo |
| Pendente | não | ver a seção seguinte |
| Sem registro | não | não há mapa no servidor para pedir |
| Esperando enviar | não | o documento é montado com o que está no servidor |

A linha do meio é a que se inverte por descuido, e por isso tem teste próprio:
**dia bloqueado continua selecionável**. É o que sustenta o CA#4 da US023 —
corrigido um mapa reaberto, o documento do período é gerado de novo com os
outros dias ainda bloqueados — e é o que permite gerar o mês inteiro depois de
já ter gerado uma semana dele.

## A regra que a US012 não tinha: mapa pendente não entra

O CA#3 da US012 pedia que os dias pendentes fossem **apontados** antes da
geração. O servidor os aceita: um dia parcial sai no documento como o
formulário em branco naquela refeição, e isso é
[deliberado lá](geracao-do-documento.md#o-que-entra-em-cada-coluna).

A decisão do projeto foi outra, e é dela que sai o comportamento desta tela:

> Pendente nunca deve entrar em documento. Se não for possível fechar a semana
> ou o mês por haver pendentes, não deve gerar nada e avisar a usuária que
> ainda existem dias pendentes. Bloqueado é bloqueio de edição, não serve como
> regra para gerar documento.

O motivo é de fora do software. O documento vai à prefeitura em papel, por um
caminho que não tem volta barata — WhatsApp, impressão, assinaturas —, e o que
chega incompleto volta. Somado a isso, o preço do engano aqui é alto: uma
seleção feita com **um toque** bloquearia dias que só a direção reabre.

Então o atalho que não consegue fechar o período **não seleciona o que dá**:
ele não seleciona nada e mostra o que falta, dia por dia, com o motivo de cada
um. Esse aviso é o elemento novo da tela — a E3 não o desenhou, porque na E3 a
regra ainda era a da US012.

E ele não é um beco. A última linha do aviso oferece a saída: "Escolher dias" e
marcar só os que já estão prontos — que é o caso dos dias avulsos, previsto no
CA#1 da US013. A recusa é do **atalho**, que promete fechar um período inteiro;
a escolha manual continua dela.

**"Sem registro" conta como buraco junto com "pendente".** A decisão falou de
pendentes, e esta é a extensão que a implementação fez: para fechar o mês, um
dia letivo sem mapa nenhum é exatamente o mesmo problema que um mapa pela
metade — e seria estranho o mês fechar ignorando o dia que ninguém registrou.

## O que está no aparelho não está no documento

A RN#3 da US012 diz que a geração "depende dos registros sincronizados", e na
prática isso é mais literal do que parece: a Edge Function recebe **os
identificadores dos mapas no servidor**, e o rascunho guardado no aparelho tem
um identificador próprio, gerado ali, que o servidor pode nem ter adotado
([camada local](camada-local.md)). Mandá-lo seria pedir um dia que não existe.

Por isso a visão do mês passou a ler também o `id` do mapa, e a junção das duas
origens ganhou a regra que faltava: quando o mesmo dia existe no servidor e no
aparelho, vale o rascunho — **menos o bloqueio e menos o identificador**, que
ele não tem como conhecer. Era a mesma exceção que o bloqueio já tinha, pelo
mesmo motivo.

Na tela, o dia nessa situação aparece como "Esperando enviar" e não é
selecionável, e a tela oferece **enviar agora** em vez de só informar. O motivo
aparece antes de qualquer outro, mesmo num dia que também está incompleto:
mandá-la abrir um dia preenchido para "terminar de preencher" seria mentira — o
que falta ali é internet, e isso se resolve sozinho.

## Sem internet, a tela explica a espera

A geração acontece no servidor, então sem rede não há o que tentar. O
[catálogo de avisos da E3](../03-ux/avisos-e-mensagens.md) já tinha escrito
essa mensagem para ficar **dentro** da tela, com o botão desabilitado — a
alternativa seria deixar o toque falhar em silêncio.

Quem responde é `navigator.onLine`, que é notoriamente otimista: ele diz que há
*uma rede*, não que há internet. Serve mesmo assim, porque o custo do engano é
pequeno e assimétrico — o falso positivo cai no diálogo de falha, que já
existe; o falso negativo não acontece, porque sem interface de rede não há
rede.

## A confirmação, que é a única do fluxo dela

O texto é o da E3, palavra por palavra, com a contagem no lugar:

> **Gerar o documento de setembro?**
> Os 22 mapas incluídos ficam bloqueados para edição depois de gerar. Se ainda
> falta corrigir algum, é agora.

O período é nomeado pela **mesma regra** que o preenchimento do modelo usa no
campo "MÊS/ANO": o rótulo nomeia os meses que a seleção toca, não os dias —
quais dias entraram é o que a tabela do documento mostra, linha a linha. Uma
seleção que atravessa meses os nomeia, e uma que atravessa anos repete o ano
dos dois lados, porque aí omiti-lo passaria a mentir.

Ela é a única confirmação do fluxo da merendeira, e isso é decisão de produto:
confirmar tudo é o caminho mais curto para ela deixar de ler as confirmações. O
diálogo é um `AlertDialog` e não um `Dialog` por uma diferença que não é de
estilo — ele não fecha com um toque fora nem com Esc, e a saída é sempre um dos
dois botões.

## Quando falha, nada foi bloqueado

O diálogo de falha obedece à regra de linguagem da E3 — o erro diz primeiro o
que **não** se perdeu. Aqui isso não é gentileza, é informação operacional, e é
verificável: o bloqueio dos mapas acontece na mesma transação que **publica** o
documento, não no pedido
([por quê](geracao-do-documento.md#o-bloqueio-entra-na-publicação-e-não-no-pedido)).
Geração que falhou não bloqueou nada, sempre.

A frase vem do servidor quando a recusa tem explicação própria — "a escola
ainda não tem um modelo oficial cadastrado", "algum dia selecionado não existe
mais" —, já escrita para quem vai lê-la, como na
[gravação do dia](gravacao-do-dia.md). O cliente não traduz nada; ele só
**alcança** a mensagem, porque o `supabase-js` embrulha a resposta num erro e
guarda o corpo em `context`. Sem esse trecho, a merendeira leria "Edge Function
returned a non-2xx status code", que não é frase de ninguém.

Quando o servidor não respondeu nada — que na escola é quase sempre a
internet —, vale a frase que a E3 escreveu inteira para este caso.

## A geração sobrevive a ela sair da tela

O pedido é uma mutação da TanStack Query **com chave**, e não uma chamada solta
dentro da tela. A diferença importa porque a mutação vive no cliente da Query,
que está acima das rotas: sair da tela não a cancela, e a tela reencontra a
geração em curso quando ela volta.

O que a tela **não** faz é navegar por cima do que ela estiver fazendo se a
geração terminar com ela em outro lugar. Isso é de propósito, e é o que a E3 já
tinha resolvido: o documento pronto aparece em Documentos gerados, e a tela 2b
diz isso com todas as letras — "quando ficar pronto, ele aparece aqui, não é
preciso esperar na tela". O registro é do servidor; a tela é só onde ela estava
quando pediu.

Na prática a espera é curta: a resposta é síncrona e o mês inteiro sai em menos
de meio segundo. A situação "em processamento" continua existindo no registro
porque é ela que sustenta o caminho da falha, não porque alguém vá esperar por
ela.

## Verificação

Os testes rodam com `npm test`, ao lado do código, e se dividem em dois pela
mesma razão de sempre: o que pode estar errado aqui é a regra, não o desenho.

[`selection.test.ts`](../../web/src/documents/selection.test.ts) — quem pode entrar
num documento, sem React e sem rede:

| Cenário                            | O que se afirma                                     |
| ---------------------------------- | --------------------------------------------------- |
| Dia preenchido e enviado           | entra                                               |
| Dia não letivo                     | entra: também é registro do mês                     |
| Dia já incluído em outro documento | **entra de novo** (CA#4 da US023)                   |
| Dia pendente                       | não entra, e o motivo é "pendente"                  |
| Dia sem registro nenhum            | não entra: não há mapa no servidor                  |
| Dia preenchido que não subiu       | não entra (RN#3 da US012)                           |
| Dia que não subiu **e** incompleto | o motivo é "esperando enviar", não "pendente"       |
| Semana com um pendente             | não fecha, e o que impede é nomeado dia a dia       |
| A mesma semana sem ele             | fecha, e leva o dia bloqueado junto                 |
| Período vazio                      | não fecha: não há documento de nada                 |
| Rótulo de um mês, dois, três, dois anos | nomeia sem mentir                              |

[`select-maps.test.tsx`](../../web/src/documents/select-maps.test.tsx) — os
critérios de aceite da issue, um a um:

| Cenário                          | O que se afirma                                       |
| -------------------------------- | ----------------------------------------------------- |
| Botão do rodapé da visão do mês  | abre a tela com o mês que ela estava vendo            |
| A tela abre                      | mês inteiro marcado, zero toques (RNF#1 da US013)     |
| Mês com um dia bloqueado         | ele vai junto                                         |
| Mês com um dia pendente          | nada marcado, e o aviso nomeia o dia                  |
| Mês com um dia sem registro      | idem: buraco é buraco                                 |
| Modo "Semana"                    | a semana inteira num toque; a incompleta não marca    |
| Modo "Escolher dias"             | aceita avulsos e recusa o dia pendente                |
| Dia esperando enviar             | fora do documento, com "Enviar agora" à mão           |
| Sem internet                     | a espera é explicada e o botão fica desabilitado      |
| Toque em "Gerar documento"       | a confirmação diz o período e o bloqueio              |
| "Voltar" na confirmação          | nada é gerado                                         |
| "Gerar" na confirmação           | manda os 22 dias e leva para os documentos gerados    |
| A geração falha                  | diz que nada foi bloqueado, e "Tentar de novo" repete |

## O que ficou para a próxima issue

**O documento gerado não tem tela ainda.** Gerada com sucesso, esta tela leva
para `/documentos`, que hoje é a tela-marco da issue #67 — é lá que entram o
download do arquivo, o botão de compartilhamento nativo quando o navegador o
oferecer, e a lista dos documentos ainda dentro da janela de sete dias.

É a fronteira que as issues desenham, e ela é honesta desde que se diga o que
custa: **quem gerar um documento antes do #67 não recebe o link**. O documento
existe, os mapas ficam bloqueados e o registro está no servidor — o que falta é
a tela que o mostra. Até lá, a geração é verificável pelo registro e pelo
balde, não pela interface.

## O peso do pacote, que ficou apertado

Esta issue somou **4,2 kB em gzip** à carga inicial — a tela, mais o
`AlertDialog` do Radix, que é a primeira peça do tipo no projeto. O pacote foi
de 195,8 kB para **200,0 kB**, contra o
[teto de 205 kB](integracao-continua-e-publicacao.md#o-teto-que-é-um-lembrete-e-não-uma-meta)
que a CI verifica.

Sobram 5 kB. O teto foi posto para acender no commit da biblioteca de gráficos
do painel gerencial, e é provável que acenda antes disso — o que não muda o que
ele é nem o que se faz quando acender: carregar a rota pesada com `lazy()`, ou
subir o teto num commit que diga por quê. Fica registrado aqui para que o dia
não pareça surpresa.
