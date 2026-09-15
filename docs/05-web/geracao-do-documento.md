# Geração do documento oficial

O risco declarado no [plano de projeto](../planodeprojeto.md) era este: gerar o
mapa no padrão da prefeitura pode ser mais difícil do que parece, e descobrir
isso tarde custaria a etapa inteira. Este documento é o resultado do *spike*
que atacou o risco — o que o modelo oficial realmente é, como preenchê-lo sem
perder o formato, e o que foi testado antes de chegar nisso.

O protótipo está em [`supabase/spikes/template-oficial/`](../../supabase/spikes/template-oficial/)
e roda em Deno, o mesmo ambiente da Edge Function que vai implementá-lo (US012,
issue da geração). **O spike responde "como"; a implementação é outra issue** —
aqui não há autenticação, nem Storage, nem bloqueio de mapa.

## O que o modelo oficial é, de verdade

A primeira descoberta desfez a premissa. O arquivo que a escola usa **não é um
modelo em branco**: é um mapa de uma semana específica, preenchido à mão, que
circula sendo sobrescrito. Lido por dentro, o `.docx` mostra:

| O que se esperava | O que está lá |
|---|---|
| Um gabarito vazio | A semana de 24 a 28 de agosto, com os cardápios digitados |
| Linhas que crescem com o texto | Altura **travada** (`hRule="exact"`), ajustada a olho linha a linha |
| Cabeçalho que repete sozinho | Cabeçalho **copiado à mão** no meio da tabela, a cada dois dias |
| Campos de formulário | Nenhum: texto corrido dentro de células |
| Um arquivo do Word atual | Modo de compatibilidade **Word 2003**, herdado dos editores por onde passou |
| Um arquivo anônimo | O nome de **duas pessoas** nas propriedades do pacote |

E não é um arquivo estático: **é sempre o mesmo arquivo**, que circula sendo
reeditado a cada semana, por pessoas que não têm motivo nenhum para se importar
com o layout. A cada volta, alguma linha ou algum texto se desloca. Isso é o
que o formulário é na vida real, e o gerador tem de contar com isso — não
lamentar.

A estrutura, essa sim, é regular e serve de gabarito: página A4 deitada, uma
tabela de cinco colunas — dia, cardápio realizado, gêneros utilizados,
alterações, número de refeições — e, por dia, um **bloco de quatro linhas**: as
três refeições e a linha "Mudança no cardápio, justificativa:". As colunas do
dia, dos gêneros, das alterações e do número de refeições são mescladas
verticalmente ao longo do bloco. Os cinco dias do arquivo têm o esqueleto
idêntico, célula por célula.

Essa regularidade é o que torna o preenchimento possível, e cada linha da
tabela acima teve um destino diferente. O conteúdo da semana de agosto é
**descartado** — só o primeiro bloco serve, e serve como forma. A altura
travada e o cabeçalho copiado são **normalizados**, junto com duas imperfeições
do rodapé e do cabeçalho, em
"[o que o gerador muda de propósito](#o-que-o-gerador-muda-de-propósito)". A
ausência de campos de formulário é o que **decidiu a abordagem**, logo abaixo.
O modo de compatibilidade é **mantido de propósito**, e o porquê está em
"[como a fidelidade foi verificada](#como-a-fidelidade-foi-verificada)". E o
nome das duas pessoas é um problema de sigilo, tratado a seguir.

### O modelo carrega nome de gente

As propriedades do pacote (`docProps/core.xml`) trazem `dc:creator` e
`cp:lastModifiedBy` com **nomes completos de duas servidoras**, além da data da
última impressão. Nada disso aparece no corpo do documento, mas está no arquivo
e é legível em qualquer leitor de metadados — inclusive depois de o documento
sair pelo WhatsApp e ser reencaminhado.

Sem tratamento, **todo documento gerado pelo sistema levaria esses nomes
junto**, porque o gerador reaproveita o pacote do modelo. O preenchimento
reescreve essas propriedades com valores neutros. É a [regra de sigilo do
projeto](../../CLAUDE.md) valendo para o que o sistema produz, não só para o
que ele versiona.

## A abordagem escolhida: o modelo é o próprio gabarito

**Decisão**: o gerador **clona o bloco de quatro linhas que o modelo já traz**,
uma vez por dia do período, e escreve o conteúdo dentro do XML que veio da
prefeitura. Nenhuma formatação é recriada em código.

É a diferença entre copiar uma folha do formulário e redesenhar o formulário.
Bordas, larguras de coluna, sombreado do cabeçalho, fontes, margens, o brasão
no cabeçalho da página — tudo isso continua sendo o que o arquivo original
dizia, porque nunca foi tocado. O que o código escreve é texto dentro de
células que já existiam, reaproveitando inclusive o `w:rPr` — a formatação de
trecho — que o modelo já tinha ali.

**O reconhecimento é por rótulo, não por posição.** A linha de cabeçalho é a
que começa com "Dia"; cada linha do bloco é achada pelo rótulo que ela própria
imprime ("Almoço:", "Mudança no cardápio, justificativa:"); o bloco do dia
começa onde a mescla vertical da primeira coluna recomeça. Se a prefeitura
mudar o formulário, o preenchimento **falha alto, dizendo qual rótulo faltou**,
em vez de escrever no lugar errado e devolver um documento plausível e errado.
Para um documento que vai a prestação de contas, falhar é melhor que mentir.

E o rótulo é procurado no texto do parágrafo inteiro, não dentro de cada trecho
do XML. A diferença importa porque **o Word reparte texto em vários trechos por
motivos que nada têm a ver com formatação** — uma correção, uma pausa na
digitação — e o modelo oficial já mostra isso: o rótulo "Lanche da tarde:" chega
repartido em quatro. Hoje a linha do grau de aceitação vem inteira, mas basta
alguém reeditar o modelo para ela se partir; se a procura fosse trecho a
trecho, o `(X)` simplesmente deixaria de ser marcado, **sem erro nenhum** — o
documento sairia bonito e sem o grau de aceitação. É o tipo de falha que só
aparece quando o documento já está na prefeitura.

### O gabarito é o primeiro bloco íntegro, não o primeiro bloco

Como o modelo é reeditado toda semana, o deslize de edição é questão de tempo —
e se cair no **primeiro** dia, tomar aquele bloco como gabarito propagaria o
defeito para todos os dias do documento. Foi o que a verificação mostrou: uma
única linha duplicada no primeiro bloco fazia o mês inteiro sair com cinco
linhas por dia em vez de quatro.

Por isso o gabarito é o primeiro bloco **íntegro** — o que traz exatamente uma
linha de cada refeição e uma de justificativa. Os outros dias do modelo servem
de segunda opinião, e basta um deles estar inteiro: com dois dias deslocados no
arquivo oficial, o documento continua saindo certo. Uma linha que não
corresponde a rótulo nenhum é tolerada, porque pode ser algo que a prefeitura
acrescentou de propósito; o que desqualifica um bloco é a repetição de uma
refeição que já apareceu, que é a assinatura do deslize.

Vale notar o que **não** precisa dessa proteção, porque o preenchimento já
absorve: parágrafo a mais dentro de uma célula (o ENTER sobrando) e texto
empurrado por espaços. Nos dois casos o conteúdo é reescrito de qualquer jeito.

### O que entra em cada coluna

| Coluna | Conteúdo | Observação |
|---|---|---|
| Dia | `dd/mm` | na primeira linha do bloco; mesclada no dia |
| Cardápio realizado | descrição da refeição, depois do rótulo | fiel ao cardápio previsto, mesmo com troca |
| — grau de aceitação | `( )` vira `(X)` só na opção registrada | sem registro, nenhuma marcação |
| Gêneros utilizados | gêneros do **dia inteiro**, consolidados | soma por gênero; unidades diferentes não somam |
| Alterações | gêneros e quantidades da troca, por refeição | vazia quando não houve troca |
| Número de refeições | o número do dia | vazio quando não registrado; `—` em dia não letivo |
| Justificativa | o motivo da troca, depois do rótulo | prefixado pela refeição, quando há mais de uma |

Duas dessas linhas merecem nota. **A descrição da refeição permanece fiel ao
cardápio previsto mesmo quando houve troca** — é o achado da E4 que desmentiu a
US002, e é o que dá sentido à justificativa. E **os gêneros são consolidados
por dia** porque a coluna é mesclada no dia, enquanto o registro é por refeição;
gêneros de mesma unidade somam, mas o mesmo gênero em unidades diferentes vira
duas linhas, porque somar `kg` com `unidade` seria inventar um número.

**Dia não letivo** ocupa o bloco com "DIA NÃO LETIVO:" e a observação, deixa as
outras refeições em branco e marca `—` no número de refeições. As linhas vazias
encolhem: um dia sem aula não deve ocupar, em branco, a mesma meia página de um
dia cheio.

**Dia letivo com registro parcial** — que as regras permitem, porque a
merendeira pode ter lançado só o almoço — sai como o formulário em branco
naquela refeição: o rótulo, a escala de aceitação sem marca, e nada mais. Não
se inventa descrição, e não se apaga a escala: o dia é letivo, só não foi
registrado, e quem receber ainda pode completar à mão.

### O campo "MÊS/ANO" quando a seleção não é um mês

O cabeçalho do formulário tem um campo "MÊS/ANO", mas a seleção não é
obrigatoriamente um mês: a merendeira pode gerar uma semana, ou dias avulsos.
O rótulo é derivado das próprias datas — uma seleção dentro de setembro sai
como `Setembro/2026`, mesmo sendo três dias soltos, porque **quais dias
entraram é o que a tabela mostra logo abaixo, dia a dia**. O que o campo não
pode é mentir: uma seleção que atravessa meses os nomeia (`Agosto e
Setembro/2026`), e uma que atravessa anos repete o ano dos dois lados
(`Dezembro/2026 a Fevereiro/2027`). Quem chamar o preenchimento pode passar um
rótulo próprio e ele prevalece.

## O que o gerador muda de propósito

Cinco coisas do modelo não sobrevivem a um mês gerado, e o gerador as troca por
equivalentes que o Word calcula sozinho. São desvios conscientes — o resultado
é mais fiel ao *formulário* do que a cópia literal seria:

- **Altura travada vira altura mínima** (`exact` → `atLeast`). No modelo, cada
  linha tem altura fixa, ajustada a olho para aquele texto. Mantê-la faria
  texto mais longo **sumir sem aviso** — o pior defeito possível num documento
  de prestação de contas, porque é invisível para quem gerou.
- **O cabeçalho copiado à mão vira cabeçalho de tabela** (`tblHeader`). No
  modelo ele foi duplicado a cada dois dias para cair certo na quebra de
  página; num mês com feriados e dias não letivos, essa conta não fecha mais. O
  Word passa a repetir o cabeçalho sozinho, no alto de cada página.
- **O dia passa a atravessar a quebra de página inteiro** (`keepNext` e
  `cantSplit`). Sem isso — e acontece no arquivo original — a linha da
  justificativa fica órfã no alto da página seguinte, sob uma célula de dia
  vazia, e quem lê não sabe de que dia ela é.
- **As assinaturas passam a se apoiar em paradas de tabulação** centralizadas,
  calculadas a partir da largura útil da página. No modelo, os dois traços e os
  rótulos "Cozinheiro(a) responsável pelo mapa" e "Diretor(a)" foram
  posicionados com sequências de espaço contadas a olho — e em fonte
  proporcional isso nunca alinha: o "Diretor(a)" sai à direita do traço dele. A
  tabulação centralizada é o mecanismo que o Word tem para exatamente isso.
- **A lacuna preenchida perde o rabicho.** "ESCOLA:" e "MÊS/ANO" são lacunas
  tracejadas, e o valor entra por cima delas; o que sobra vira espaço, não mais
  tracejado. Linha preenchida não precisa do convite a preencher, e o
  `Escola Municipal ____________` é justamente a cara de formulário feito às
  pressas que este produto existe para acabar. Em espaço, o comprimento se
  mantém e o "MÊS/ANO" continua caindo onde caía.

Fora esses cinco, o gerador não muda nada do modelo. Os três primeiros são
correções de robustez — sem eles o documento sai errado. Os dois últimos são
acabamento, e se comportam como tal: reconhecem o rodapé pela forma (o
parágrafo que só tem traço e espaço, e o próximo com texto) e, se não
reconhecerem, **deixam como está em silêncio**. Não vale reprovar uma geração
por causa de estética.

## O que foi testado e descartado

**docxtemplater** — a escolha óbvia, e foi testada contra o arquivo oficial: a
biblioteca roda, abre o documento e **não encontra marcação nenhuma para
preencher** (zero tags), devolvendo o arquivo intacto. Ela preenche templates
*preparados*, com `{tags}` escritas dentro do documento, e loops de tabela
declarados com `{#dias}…{/dias}` nas células. Preparar o modelo é trabalho de
edição no Word — e quem sobe o modelo é a direção da escola (RN#1 da US015),
com o arquivo que a prefeitura mandou. Transferir essa preparação para ela seria
transferir o risco inteiro do spike para a pessoa menos equipada para absorvê-lo,
e quebraria a cada arquivo novo que a secretaria enviasse. Descartada por causa
de quem opera, não por capacidade técnica.

**Montar o documento do zero** (com a biblioteca `docx` ou equivalente) — daria
controle total e dispensaria o modelo, ao custo de reescrever o formulário em
código: bordas, larguras, sombreado e o brasão. O formato passaria a ser uma
cópia mantida por nós, que envelhece em silêncio quando a prefeitura mudar o
dela — e a US015 existe justamente porque esse dia chega. Descartada.

**Gerar PDF com layout equivalente** — era a alternativa prevista no critério de
aceite da issue, caso o preenchimento fiel se mostrasse inviável. **Não foi
preciso**, e é bom que não: a saída em PDF seria *parecida* com o formulário, e
o "parecida" é exatamente o que este produto existe para acabar. Fica
registrada como plano B se a fidelidade se mostrar insustentável na
implementação — o custo dela é redesenhar o layout, o mesmo custo de montar o
documento do zero.

## Como a fidelidade foi verificada

O documento de amostra foi gerado a partir do **arquivo oficial de verdade**,
com um mês inteiro de dados fictícios: 22 dias úteis de setembro, dois deles não
letivos, um dia sem número de refeições registrado, uma refeição sem grau de
aceitação e duas trocas de cardápio com gêneros e justificativa.

O resultado foi conferido página a página contra o original renderizado lado a
lado. O brasão, o cabeçalho da prefeitura, as bordas, o sombreado e as fontes
saíram idênticos; o cabeçalho da tabela repetiu sozinho em todas as páginas; e
nenhum dia ficou partido entre páginas.

O mês saiu em 12 páginas, com os mesmos **dois dias por página** do original —
menos a primeira, que leva um dia só porque divide o espaço com o cabeçalho do
documento, e a última, que fica com a sobra. Vale notar que manter o dia
inteiro junto **não custou papel**: a versão que deixava o dia partir dava as
mesmas 12 páginas, e apenas espalhava a justificativa de alguns dias para o
alto da página seguinte. Até as
imperfeições do original se mantiveram — a coluna do dia quebra "01/ 09" em
duas linhas porque é estreita, exatamente como quebra "24/ 08" no arquivo da
escola. Isso é fidelidade, não defeito: corrigir alargaria a coluna e o
documento deixaria de ser o formulário deles.

**Desempenho**: 336 ms e cerca de 62 MB para o mês inteiro, contra o teto de 30
segundos do RNF#2 da US012. O risco de tempo, que o plano de projeto também
previa, não se confirmou — sobra folga de duas ordens de grandeza.

**Conferido no Word.** A primeira leitura foi no LibreOffice, que é tolerante
com OOXML malformado e por isso não prova nada sobre o risco que mais
importava: o Word **recusa** um arquivo cuja ordem de elementos viole o schema,
e o preenchimento mexe justamente em `w:trPr`, `w:pPr` e `w:tabs`, onde essa
ordem é normativa. O documento foi aberto no Word e impresso em PDF pelo
servidor da Microsoft: as 12 páginas, o cabeçalho repetido em todas elas e
nenhum dia partido — tudo como o LibreOffice mostrava.

**O Word avisa que o arquivo está em "modo de compatibilidade", e assim deve
ficar.** O aviso vem do modelo, não do preenchimento: o `word/settings.xml`
declara `compatibilityMode` **11** — Word 2003 — e o gerador o repassa
intocado, como faz com todo o resto do pacote. O arquivo que a escola usa hoje
abre com o mesmo aviso. Mudar para o modo atual tiraria o aviso e não traria
nada: o documento não usa um único recurso posterior ao Word 2003 — tabela,
mescla vertical, tabulação centralizada, repetição de cabeçalho e `keepNext`
existem desde o Word 97. Em troca, mudaria as regras de layout de tabela que o
Word aplica, invalidando a conferência acima. Um documento nosso que se
comportasse **diferente** do modelo é que seria o defeito.

## Sigilo

Nada do que este spike tocou entra no repositório. O modelo oficial tem brasão,
nome da prefeitura e um mapa real preenchido; o documento de amostra é derivado
dele. O `.gitignore` barra `.docx` de propósito, e essa barreira não foi
contornada.

O que está versionado é **código**: o preenchimento, os testes, e um
[modelo de teste](../../supabase/spikes/template-oficial/modelo-de-teste.ts)
construído do zero — mesma estrutura, mesmos rótulos, mesmos dois vícios, sem
brasão e sem nome de prefeitura. É contra ele que os testes rodam, e é com ele
que qualquer pessoa reproduz o spike sem ter o arquivo oficial em mãos.

É também o que permite verificar o spike na integração contínua, no fluxo
[`spikes.yml`](../../.github/workflows/spikes.yml): um spike responde a uma
pergunta e depois vira base de código de produção, e o que ele descobriu
precisa continuar valendo até lá. A limpeza dos metadados tem teste próprio —
o modelo de teste nasce com nome de gente justamente para que apagá-lo seja
verificado, e não confiado à memória de quem implementar.

## O que fica para a implementação

O spike responde "como preencher". A Edge Function da US012 ainda precisa
resolver, na issue dela:

- ler o modelo vigente do bucket privado e gravar o resultado com validade de
  até sete dias (RN#2 da US012);
- registrar `generated_document` e bloquear os mapas incluídos, numa transação
  só (RN#4 da US012, US007);
- apontar os dias pendentes do período **antes** de gerar (CA#3 da US012).

**O modelo guardado no sistema é o arquivo da prefeitura como ele vem**, com a
semana preenchida e o layout torto que ele tiver no dia. Não há versão limpa a
manter, e não deve haver: limpar à mão acrescentaria um passo humano entre a
secretaria e o sistema — mais um lugar onde algo se perde — para apagar
justamente o que o gerador descarta sozinho. O que o administrador sobe na
US015 é o arquivo que recebeu, sem cerimônia.

Isso é uma inversão que vale registrar. O desleixo do arquivo era o obstáculo
que se esperava ter de contornar para gerar o documento; acabou virando algo
que o sistema **corrige** — as alturas travadas a olho, o cabeçalho copiado no
meio da tabela, os rótulos de assinatura fora de lugar e o tracejado
pendurado desaparecem a cada geração, sem ninguém precisar arrumar nada. O mapa
que sai do sistema é mais bem formado que o modelo de onde veio.
