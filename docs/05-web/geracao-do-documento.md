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
| Um arquivo anônimo | O nome de **duas pessoas** nas propriedades do pacote |

A estrutura, essa sim, é regular e serve de gabarito: página A4 deitada, uma
tabela de cinco colunas — dia, cardápio realizado, gêneros utilizados,
alterações, número de refeições — e, por dia, um **bloco de quatro linhas**: as
três refeições e a linha "Mudança no cardápio, justificativa:". As colunas do
dia, dos gêneros, das alterações e do número de refeições são mescladas
verticalmente ao longo do bloco. Os cinco dias do arquivo têm o esqueleto
idêntico, célula por célula.

Essa regularidade é o que torna o preenchimento possível. Os três primeiros
vícios da tabela acima são o que o gerador precisa **normalizar** — estão em
"[o que o gerador muda de propósito](#o-que-o-gerador-muda-de-propósito)". O
quarto é um problema de sigilo, e está logo abaixo.

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

## O que o gerador muda de propósito

Três coisas do modelo não sobrevivem a um mês gerado, e o gerador as troca por
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

Fora esses três, o gerador não muda nada do modelo.

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
saíram idênticos; os dois dias por página do original se mantiveram; o
cabeçalho repetiu sozinho em todas as páginas; nenhum dia ficou partido. Até as
imperfeições do original se mantiveram — a coluna do dia quebra "01/ 09" em
duas linhas porque é estreita, exatamente como quebra "24/ 08" no arquivo da
escola. Isso é fidelidade, não defeito: corrigir alargaria a coluna e o
documento deixaria de ser o formulário deles.

**Desempenho**: 336 ms e cerca de 62 MB para o mês inteiro, contra o teto de 30
segundos do RNF#2 da US012. O risco de tempo, que o plano de projeto também
previa, não se confirmou — sobra folga de duas ordens de grandeza.

**O que ainda não foi verificado**: a conferência foi feita no LibreOffice. O
documento precisa ser aberto **no Word** antes da implementação — é o programa
de quem recebe na prefeitura, e é o único juiz que importa nessa pergunta.

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

## O que fica para a implementação

O spike responde "como preencher". A Edge Function da US012 ainda precisa
resolver, na issue dela:

- ler o modelo vigente do bucket privado e gravar o resultado com validade de
  até sete dias (RN#2 da US012);
- registrar `generated_document` e bloquear os mapas incluídos, numa transação
  só (RN#4 da US012, US007);
- apontar os dias pendentes do período **antes** de gerar (CA#3 da US012);
- decidir o rótulo do período quando a seleção não for um mês fechado — o
  cabeçalho tem um campo "MÊS/ANO", e a merendeira pode selecionar dias avulsos;
- abrir o documento gerado no Word e confirmar o que o LibreOffice já mostrou.

E uma pergunta que o spike levanta para a direção da escola, não para o código:
o modelo guardado no sistema deve ser o arquivo da prefeitura **como ele vem** —
com a semana de agosto preenchida — ou uma versão limpa dele? O gerador funciona
nos dois casos, porque só usa o primeiro bloco como gabarito e descarta o resto.
Guardar o arquivo como veio tem a vantagem de ser exatamente o que a secretaria
mandou, sem intermediário.
