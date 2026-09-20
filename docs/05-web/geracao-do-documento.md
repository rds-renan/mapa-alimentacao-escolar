# Geração do documento oficial

O risco declarado no [plano de projeto](../planodeprojeto.md) era este: gerar o
mapa no padrão da prefeitura pode ser mais difícil do que parece, e descobrir
isso tarde custaria a etapa inteira. Este documento é o resultado do *spike*
que atacou o risco — o que o modelo oficial realmente é, como preenchê-lo sem
perder o formato, e o que foi testado antes de chegar nisso — e, no fim, a
implementação que saiu dele.

O código está em [`supabase/functions/`](../../supabase/functions/): o
preenchimento em `_shared/`, que é o spike graduado, e a Edge Function
`generate-document`, que o cerca de tudo o que um spike não tem —
autenticação, Storage, registro e bloqueio dos mapas. Quem quiser só o "como
preencher" pode parar em
"[o que foi testado e descartado](#o-que-foi-testado-e-descartado)"; quem
procura o contrato da função vai direto para
"[como a Edge Function funciona](#como-a-edge-function-funciona)".

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
[modelo de teste](../../supabase/functions/_shared/modelo-de-teste.ts)
construído do zero — mesma estrutura, mesmos rótulos, mesmos dois vícios, sem
brasão e sem nome de prefeitura. É contra ele que os testes rodam, e é com ele
que qualquer pessoa reproduz o spike sem ter o arquivo oficial em mãos.

É também o que permite verificá-lo na integração contínua, no fluxo
[`funcoes.yml`](../../.github/workflows/funcoes.yml): um spike responde a uma
pergunta e depois vira base de código de produção, e o que ele descobriu
precisa continuar valendo até lá. A limpeza dos metadados tem teste próprio —
o modelo de teste nasce com nome de gente justamente para que apagá-lo fosse
verificado, e não confiado à memória de quem implementasse.

## Como a Edge Function funciona

O spike responde "como preencher". O resto — quem pode pedir, de onde vem o
modelo, onde o arquivo fica, quando o mapa trava — é a
[`generate-document`](../../supabase/functions/generate-document/), e o caminho
dela é este:

1. o token da sessão diz quem chamou; o perfil diz a escola e o papel;
2. `start_document_generation` valida o pedido e registra a geração como **em
   processamento**, amarrando os mapas incluídos;
3. a função lê os mapas e baixa o modelo **que aquele registro aponta**;
4. preenche o modelo com o preenchedor do spike;
5. grava o `.docx` no balde privado `generated-documents`;
6. `complete_document_generation` publica o registro e **bloqueia os mapas**,
   numa transação só;
7. devolve o link assinado, com a validade que o banco carimbou.

Qualquer tropeço entre 3 e 6 encerra a geração como **falha**, e nenhum mapa é
bloqueado. Os três passos de banco estão em
[`20260919120000_geracao_do_documento.sql`](../../supabase/migrations/20260919120000_geracao_do_documento.sql),
e os cenários deles em
[`supabase/tests/geracao-do-documento.test.sql`](../../supabase/tests/geracao-do-documento.test.sql).

**A resposta é síncrona.** O mês inteiro sai em menos de meio segundo — 336 ms
de preenchimento no spike, 200 a 320 ms de ponta a ponta contra o Supabase
local, com 22 dias —, contra os 30 segundos do RNF#2. A situação "em
processamento" continua existindo no registro porque é ela que sustenta o
caminho da falha, não porque a merendeira vá esperar por ela.

### O contrato

`POST /functions/v1/generate-document`, com a sessão da merendeira no
`Authorization`:

```json
{ "meal_map_ids": ["c0000001-…", "c0000002-…"] }
```

A escola **não** está no pedido, e é de propósito: ela vem sempre do perfil de
quem chamou — a mesma regra da [gravação do dia](gravacao-do-dia.md). Datas
repetidas na lista viram um dia só no documento.

A resposta, em 200:

```json
{
  "generated_document_id": "ec8aa71b-…",
  "status": "available",
  "requested_at": "2026-10-31T12:00:00.000Z",
  "completed_at": "2026-10-31T12:00:00.320Z",
  "expires_at": "2026-11-07T12:00:00.320Z",
  "meal_map_count": 22,
  "period": { "from": "2026-10-01", "to": "2026-10-30" },
  "file_name": "mapa-da-alimentacao-escolar-outubro-2026.docx",
  "download_url": "https://…/object/sign/generated-documents/…"
}
```

`period` e `meal_map_count` são **derivados** dos mapas incluídos, não gravados
(decisão 10 da E4). O `file_name` é o nome com que o arquivo chega no aparelho
de quem recebe, e vai sem acento e sem espaço de propósito: ele viaja em
cabeçalho HTTP, passa por aplicativo de mensagem e termina no sistema de
arquivos de um celular que não é nosso.

Esse nome é **gravado** no registro, e não só devolvido aqui: a
[lista de documentos gerados](documentos-gerados.md#o-nome-do-arquivo-mora-no-registro)
assina um link novo dias depois e precisa entregar o arquivo com o mesmo nome.
Quem o carimba é `complete_document_generation`, junto com o caminho e a
validade.

Os erros, com a mensagem já legível por quem vai lê-la:

| Quando | HTTP | O que chega na tela |
|---|---|---|
| Sem sessão, ou sessão vencida | 401 | Entre de novo para gerar o documento. |
| Direção, ou perfil desativado | 403 | Só a merendeira gera o documento do mapa. |
| Seleção vazia | 400 | Selecione ao menos um dia para gerar o documento. |
| Dia que não existe, ou de outra escola | 400 | Algum dia selecionado não existe mais. |
| Escola sem modelo vigente | 400 | A escola ainda não tem um modelo oficial cadastrado. |
| Modelo ilegível, balde fora do ar, qualquer tropeço | 500 | Não foi possível gerar o documento agora. |

O 500 é o único que não explica a causa, e é de propósito: a causa dele é
defeito nosso, não algo que a merendeira possa corrigir. Ela vai para o log, e
para a tela vai o que interessa — que os registros do período continuam
guardados.

### O bloqueio entra na publicação, e não no pedido

A [decisão 5 da E4](../04-banco-de-dados/decisoes-de-modelagem.md) punha o
bloqueio "na mesma transação em que registra o `DocumentoGerado`", e o registro
nasce no pedido. O que ela não previa é o caminho da falha: bloquear no pedido
obrigaria a **desbloquear sozinho** quando a geração falhasse — e desbloqueio
sem rastro é exatamente o que a US023 não admite, porque o único caminho de
saída do bloqueio é a reabertura pela direção, com justificativa guardada.

Bloquear junto com a publicação mantém a regra de pé ("o que saiu em documento
não se edita", RN#1 da US007) e deixa a falha sem efeito colateral nenhum. O
que se paga é uma janela em que um mapa incluído ainda aceita edição: o tempo
do preenchimento, que é de centenas de milissegundos. Para alguém alcançá-la,
a outra merendeira teria de salvar exatamente aquele dia dentro dela.

### Um mapa pode entrar em mais de um documento

Não é permissividade, é a US023 fechando. O desbloqueio é de **um mapa**, e o
CA#4 dela diz que, corrigido o mapa, "o documento do período pode ser gerado de
novo" — com os outros dias do período ainda bloqueados. Se a geração recusasse
mapa bloqueado, a correção terminaria num beco: o dia consertado e nenhum
documento possível. O bloqueio é sobre **editar**, nunca sobre sair de novo.

O documento antigo continua existindo, e é o que a RN#2 da US023 exige. Depois
de uma correção, a lista da US021 mostra dois documentos do mesmo período — e
quem diz qual vale é
[a ordem dela](documentos-gerados.md#dois-documentos-do-mesmo-período), do mais
novo para o mais velho, com a data de geração em cada cartão. Era assunto da
tela dos documentos gerados, e lá se resolveu.

### O arquivo expira, e apagar é mesmo apagar

A validade de sete dias (RN#2 da US012) é carimbada pelo banco, num lugar só, e
o link assinado apenas a acompanha — fossem dois prazos, um deles envelheceria
sozinho. Vencido o prazo, três coisas acontecem: o link deixa de assinar, a
política do balde deixa de servir o arquivo, e a
[`expire-documents`](../../supabase/functions/expire-documents/) o **apaga**.

Apagar de verdade não é zelo: "o sistema não mantém cópia permanente do
documento" é regra da US012, e o que ficaria guardado é um documento com o
brasão da prefeitura e o mapa de uma escola — a regra de sigilo do projeto
valendo para o que o sistema produz. O registro fica, e é ele que diz que os
mapas do período continuam guardados.

A mesma rotina encerra a geração que ficou **em processamento** além de uma
hora. A geração é síncrona, então só chega lá a que morreu no meio; sem isso,
um registro ficaria em processamento para sempre, prometendo à merendeira um
arquivo que nunca vem.

Ela varre o **balde**, e não a tabela: o balde é quem sabe o que ainda está lá.
Pela tabela, cada passagem reprocessaria todo documento já gerado na história
da escola, e um arquivo que tivesse perdido o registro nunca seria alcançado.

**O agendamento não está em migration**, e não pode estar: ele precisa da chave
secreta, que não entra em código. É um `pg_cron` diário chamando a função por
HTTP, e o passo a passo está na
[integração contínua e publicação](integracao-continua-e-publicacao.md#o-agendamento-da-limpeza),
junto com o resto do que se publica à mão. Uma vez por dia basta: a janela é de
sete dias, e um arquivo que sai algumas horas depois do prazo já não era servido
a ninguém desde o instante em que venceu.

### O que ficou para as telas

Duas coisas da US012 não são desta issue, e vale dizer onde estão:

- **apontar os dias pendentes do período antes de gerar** (CA#3) é da tela de
  seleção — a função não recusa dia pendente, porque registro parcial é
  permitido e sai no documento como o formulário em branco naquela refeição;
- **compartilhar** é da tela do documento gerado, e está pronto: na web,
  [compartilhar é baixar](documentos-gerados.md#na-web-compartilhar-é-baixar)
  ([decisão 9](decisoes-tecnicas.md)), com o botão nativo quando o navegador
  souber compartilhar arquivo; a folha de compartilhamento do Android é da E6.

## O modelo é o arquivo da prefeitura como ele vem

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
