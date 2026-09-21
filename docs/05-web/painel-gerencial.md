# O painel gerencial

A **US017** é a funcionalidade de destaque do perfil administrador, e o que a
define é o papel dele: gerencial, **fora** do fluxo do mapa. Os dados já são
capturados no registro diário (US004 e US005) — o painel só os agrega, por mês,
em três números e dois gráficos simples.

O código está em [`web/src/admin/`](../../web/src/admin/) (a agregação, a
consulta, os três cartões e o seletor de mês), em
[`web/src/pages/AdminDashboard.tsx`](../../web/src/pages/AdminDashboard.tsx) (a
tela) e em
[`web/src/components/ui/select.tsx`](../../web/src/components/ui/select.tsx) (o
menu suspenso, aparado ao que a tela usa).

## O que o painel não faz

Ele não abre mapa, não mostra o que está escrito num dia e não tem link para
dia nenhum. É leitura agregada, e é a RN#1 da história — mas não é só uma
regra: é a mesma linha que a [reabertura de um mapa](desbloqueio-de-mapa.md)
respeita ao devolver o dia sem corrigi-lo. **O mapa é da merendeira.** A guarda
de rota já barraria a direção no registro; o que a tela garante é que ela nem
seja convidada a tentar, e um caso de teste confere que os únicos links da
página são os três destinos da barra lateral.

Também não escreve nada: não há uma única mutação em
[`dashboard-queries.ts`](../../web/src/admin/dashboard-queries.ts).

## Uma consulta só, e ela já existia

O painel lê **os dias do mês** — a mesma consulta da
[visão do mês](visao-do-mes.md) da merendeira, com a mesma chave de cache. Não
há view agregada, função no banco nem migration nesta issue: a agregação
acontece no navegador, sobre as vinte e poucas linhas de um mês.

Uma view pareceria mais séria e não seria. Ela seria uma **segunda definição de
mês**, livre para divergir da que as telas da merendeira usam, em troca de
poupar uma soma de sessenta números. Pelo mesmo motivo `monthProgress` — o
andamento do mês — é reaproveitado inteiro: se o painel inventasse o seu próprio
"dia completo", a direção e a merendeira discordariam sobre o que falta no mês,
cada uma olhando uma tela, e as duas estariam certas.

O RNF#1 pede menos de cinco segundos. O que custa é a ida ao servidor, e um mês
inteiro sai do Supabase em algumas centenas de milissegundos — o mesmo trecho
que a geração do documento mede em 200–320 ms. Somar as linhas depois disso é
tempo de quadro de vídeo.

## O dia não letivo sai pelo atributo, nunca pela ausência de refeições

É a RN#2 da história, e é o ponto em que um atalho razoável estaria errado.

Marcar um dia como não letivo **preserva** as refeições já digitadas — decisão 1
da E4, tomada para que desmarcar devolva o que estava lá (CA#3 da US006). Então
um painel que excluísse "dias sem refeição" contaria, na média e no ranking, as
refeições de um dia que não houve — e ninguém perceberia, porque o número sairia
plausível. Cada agregação filtra `nonSchoolDay` explicitamente, e há um caso de
teste para isso em cada uma das três.

## A média divide pelos dias que têm o número, não pelos dias letivos

"Média por dia letivo" divide o total pelos dias **com o número informado**. É a
diferença entre "cada dia serviu 312 refeições" e "o mês ainda não acabou":
dividir pelos 22 dias letivos no dia 10 daria uma média de menos de metade da
real, e a direção olharia para um número que sobe porque o mês passa, não porque
a escola serviu mais.

Mês sem nenhum dia informado mostra um travessão, e não um zero — zero faria a
direção procurar o dia em que a escola não serviu nada.

## As merendas mais bem aceitas, e o caso de uma vez só

O agrupamento é pela descrição normalizada (minúsculas, sem espaço repetido),
exatamente como o banco normaliza o nome de um gênero. É a decisão 3 da E4 com
a sua limitação declarada: "Arroz com frango" e "arroz c/ frango" contam
separado, e o lugar de resolver isso é a ingestão do cardápio (US019), não uma
adivinhação no painel. A nota no pé do cartão diz isso à direção, em vez de
deixá-la descobrir sozinha por que a mesma merenda aparece duas vezes.

Só entram refeições **avaliadas**. Uma merenda servida e não avaliada não diz
nada sobre aceitação, e contá-la como não-ótimo seria inventar uma avaliação que
a merendeira não deu.

O problema real do ranking é outro: num mês uma merenda aparece uma ou duas
vezes, então **100% de uma vez só é o caso comum**, não a campeã da escola. Duas
saídas foram consideradas — exigir um mínimo de repetições, ou trocar o
percentual por uma nota média ponderada. A escolhida foi a terceira: ordenar por
percentual de ótimo, desempatar pelo número de vezes, e **dizer quantas vezes
foi** em cada linha. Um corte silencioso apagaria da lista uma merenda que
existiu; a nota ponderada inventaria uma escala que a E3 não definiu e faria o
número parar de bater com o título do cartão. Dizer "1 vez no mês" custa uma
linha de texto e deixa quem lê decidir o que o número vale.

## Os gráficos são `div`s

As [decisões técnicas](decisoes-tecnicas.md) previam que uma biblioteca de
gráficos nascesse aqui. **Não nasceu, e a previsão estava errada.** O desenho da
E3 tem uma barra empilhada de três valores e cinco barras de proporção: não há
eixo, escala, tooltip nem série temporal. São `div`s com `width` em porcentagem,
e cem quilobytes para desenhar retângulos seriam peso sem contrapartida.

O que veio da E3 e ficou é o que importava: a **paleta de dados** da decisão 6 —
`--chart-1` azul, `--chart-2` cinza, `--chart-3` vermelho —, separada do acento
da marca e validada para daltonismo, já com a variante do tema escuro nos
mesmos tokens.

**A barra não tem trilho de fundo**, e isso custou uma volta que só apareceu
rodando a tela com dados de verdade. Com um `bg-muted` atrás, o cinza do "bom"
(`#f0efec`) ficava indistinguível do trilho (`#f4f4f5`) — a mesma cor a olho —,
e uma refeição sem nenhum "ótimo" aparecia como uma barra quase vazia com um
pedaço vermelho no fim, quando o claro era o "bom" e a refeição estava longe de
ser um fracasso. As três fatias somam o todo, então trilho não é informação: é
uma quarta cor disputando com uma das três. Pelo mesmo motivo a fatia do "bom"
leva um fio de borda em sombra interna — é o mesmo fio que o desenho da E3 dá
ao ponto da legenda, e sem ele o fim da fatia some quando ela é a última.

A cor não carrega a informação sozinha. Cada barra de aceitação tem o percentual
escrito ao lado e um `aria-label` com a distribuição inteira em palavras
("Lanche da tarde: 0 ótimo, 0 bom, 2 ruim, de 2 avaliações"); a legenda é
`aria-hidden`, porque ela só explica a cor. As larguras são a proporção exata,
sem arredondar — três inteiros arredondados somam 99 ou 101, e a sobra vira um
degrau na ponta da barra. O arredondamento fica no rótulo, onde é lido, e não na
geometria, onde se acumula.

## O menu suspenso do mês, e os 17 kB que ele quase cobrou

O mês se escolhe num menu suspenso, e não nas setas ‹ › da visão do mês: as duas
telas navegam o tempo por motivos diferentes. A merendeira anda de mês em mês a
partir de hoje, conferindo o que falta; a direção pula para um mês qualquer do
ano para comparar, e sete toques numa seta é o gesto errado para essa pergunta.
A lista tem doze meses — o ano letivo tem dez — e não pergunta ao servidor quais
deles têm registro: seria uma consulta a mais para poupar uma rolagem, e um mês
vazio na lista responde "não tem nada em julho" tão bem quanto a ausência dele.

O mês aberto vai na barra de endereço (`?mes=2026-09`), como na visão do mês e
pelo mesmo motivo: recarregar com F5 não pode jogar a direção de volta no mês de
hoje quando ela estava olhando o mês passado.

**O componente quase não coube.** O menu do shadcn/ui traz o Radix Select e o
Floating UI juntos, e a carga inicial foi de 204,0 kB para 221,0 kB — acima do
teto de 205 kB que a CI vigia. O `lazy()` da decisão 14 não protegia: ele
separava o nosso código, e o grupo `vendor` do rolldown continuava varrendo todo
o `node_modules` para um pedaço só, que é carga inicial. A correção está em
[`web/vite.config.ts`](../../web/vite.config.ts) e é uma etiqueta —
`tags: ['$initial']` —, descrita em
[integração contínua e publicação](integracao-continua-e-publicacao.md#a-divisão-por-rota-não-cobria-as-dependências).
Com ela, 203,8 kB: menos do que a `main` tinha antes do painel, e o menu
viajando nos 20,6 kB do arquivo que só a direção baixa.

## O que mudou no desenho da E3

Duas coisas, e as duas vieram do que a implementação descobriu — mesmo
precedente das issues #63, #64, #66 e #69, com `design/telas/` e o PNG
atualizados neste mesmo Pull Request:

- **cada linha do ranking ganhou "N vezes no mês"**, pelo motivo da seção
  acima. Os percentuais do desenho foram refeitos junto, porque passaram a ter
  de fechar com a contagem: 84% de uma vez só não existe;
- **o cartão de dias diz "2 por registrar"** onde dizia "1 pendente". Para a
  direção, o dia vazio e o dia incompleto são a mesma coisa — dia que falta —, e
  a tela junta os dois.

O canvas de design precisa ser republicado a partir de `design/telas/`; a regra
vale nos dois sentidos e está em [design/README.md](../../design/README.md).
