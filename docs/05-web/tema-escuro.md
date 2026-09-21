# O tema escuro

A história é curta e o motivo é concreto: **o mapa é preenchido em casa, e com
frequência à noite** (US024, achado da E1). Uma tela branca inteira na mão de
quem está no quarto, com a luz apagada, é a lanterna que a história veio
apagar.

A paleta escura já existia. Ela nasceu junto com os tokens, na
[fundação da web](fundacao-da-web.md), de propósito: acrescentá-la depois
obrigaria a revisar cada tela já implementada, nas duas plataformas. O que esta
issue faz é **ligá-la** — a escolha, onde ela mora e como a página nasce já
vestida.

O código está em [`web/src/theme/`](../../web/src/theme/), e a paleta continua
onde sempre esteve, em [`web/src/index.css`](../../web/src/index.css).

## Três escolhas, e não duas

O desenho da E3 trazia "Tema escuro" como uma chave de liga/desliga
([decisão 9](../03-ux/decisoes-de-design.md)). Numa chave não cabem três
estados, e o terceiro é o que mais importa: **seguir o aparelho**.

É o padrão de quem nunca abriu esta preferência, e não é conveniência de
implementação. O celular delas já troca de tema sozinho ao anoitecer — é
exatamente a hora em que o mapa é preenchido. Quem nunca tocar no controle
recebe o tema escuro na hora certa sem ter pedido nada; com uma chave, o
primeiro toque desligaria isso para sempre, sem caminho de volta.

O desenho da tela 2a foi atualizado junto com o código, pelo precedente da
issue #63: quando a implementação diverge, `design/telas/` e o PNG vão no mesmo
PR.

O rótulo deixou de ser "Tema escuro" e passou a ser **"Tema"**: com uma chave,
o nome dizia o que ela ligava; com três opções, ele nomeia o assunto e as
opções dizem cada estado.

## A escolha mora no aparelho

Não vai ao banco — é a [decisão 12 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)
e a RN#1 da US024. Guardada no `localStorage`, sob a chave `mae.theme`.

Isso tem três consequências que valem estar escritas:

- **Duas merendeiras que dividam o mesmo computador** não disputam a
  preferência uma da outra — quem escolhe é o aparelho, não a conta.
- **Sair da conta não apaga o tema.** O que sai apaga é o que é da pessoa
  ([a camada local](camada-local.md)); o tema não é dela, é do aparelho em que
  ela está.
- **Ela não atravessa aparelhos.** Escolher escuro no celular não escurece o
  computador da secretaria, e isso é o comportamento certo: são ambientes de
  luz diferentes.

## A página nasce vestida

Um script curto no `<head>` do
[`index.html`](../../web/index.html) aplica o tema **antes da primeira
pintura**, e ele repete em oito linhas o que `theme.ts` faz.

A repetição é o ponto. Módulo chega depois do primeiro desenho da tela, então o
React só conseguiria escurecer a página depois de ela já ter aparecido branca —
um lampejo a cada abertura do aplicativo, que é o incômodo da história
acontecendo de novo, em miniatura. Pelo mesmo motivo ele é inline e não um
arquivo: arquivo é uma ida à rede, e numa internet fraca a ida dura mais do que
a pintura.

O script inteiro fica dentro de um `try`. Navegador com armazenamento bloqueado
estoura ao ler o `localStorage`, e o aplicativo não abrir por causa de uma
preferência de cor seria trocar um incômodo por uma parede.

### O que a classe `.dark` não alcança

Ligar a classe troca a paleta de tokens inteira de uma vez. Mas barra de
rolagem, seletor de data e caixa de texto são desenhados pelo navegador, não
por nós — e sem `color-scheme` no elemento raiz a tela escura vem com uma barra
de rolagem branca do lado e o calendário nativo aceso na cara de quem escolheu
o escuro.

A `<meta name="theme-color">` acompanha pelo mesmo motivo: no claro é o azul da
marca, como sempre foi; no escuro é o fundo da página. Uma faixa azul acesa no
alto de uma tela quase preta seria a mesma luz, num pedaço menor.

## Onde a escolha fica

**No menu da merendeira** (tela 2a), que é o lugar que a E3 lhe deu — abrir o
menu já é ver qual tema está valendo, e trocar não tira ninguém de onde estava.

**No pé da barra lateral da direção**, ao lado de quem está logada e do "Sair".
A direção não tem menu: os dois fluxos são separados e não há caminho de um
para o outro (RN#1 da US020), então a barra é o único canto fixo que ela tem.
Sem isto, quem trabalha à noite no computador da secretaria seria a única
pessoa do sistema sem escolha de tema.

O bloco inteiro da barra é de computador, como o resto dela: no celular a
direção fica com o padrão "Sistema", que já acompanha o aparelho.

## Quem marca a escolha é a pílula, não a cor da palavra

O caminho natural seria apagar as duas opções não escolhidas com o cinza de
apoio. Ele esbarra no contraste: cinza de apoio sobre o cinza do trilho dá
**4,40** no tema claro, abaixo dos 4,5 que o AA pede para texto normal
([decisão 6 da E3](../03-ux/decisoes-de-design.md)).

As três palavras ficam legíveis o tempo todo, e o que diz qual está valendo é o
fundo claro com sombra embaixo dela — que é como o próprio aparelho delas
desenha um controle destes. A opção escolhida também é dita em palavras pelo
leitor de tela, porque são botões de rádio de verdade: a navegação por setas
vem do navegador, sem código.

## Contraste: o escuro passa com folga

Cada par de cor usado nas telas foi medido nas duas paletas. **No tema escuro,
todo par de texto passa o AA, e o menor deles é 5,25** — o escuro é
confortavelmente melhor que o claro, que tem pares raspando no limite.

| Par                           | Claro    | Escuro |
| ----------------------------- | -------- | ------ |
| Texto sobre o cartão          | 19,90    | 16,97  |
| Texto de apoio sobre o cartão | 4,83     | 6,91   |
| Texto do botão principal      | 4,64     | 8,77   |
| Etiqueta "Preenchido"         | 4,79     | 9,35   |
| Etiqueta "Pendente"           | 4,76     | 12,27  |
| Erro sobre o fundo dele       | **4,41** | 6,24   |
| Aba ativa da direção          | **4,10** | 5,25   |
| Gráfico: "bom" sobre o cartão | **1,15** | 2,29   |

Os três números em negrito são do **tema claro** e são anteriores a esta issue
— vêm da paleta fechada na fundação. Ficam registrados aqui porque foi esta
medição que os encontrou, e porque mexer neles é mexer nos tokens da E3, que é
decisão de design e não de implementação.

### Os gráficos do painel

A escala de aceitação tem variante escura própria (`--chart-1/2/3`), e ela é
**melhor** que a clara: o "bom" sai de 1,15 para 2,29 sobre o cartão. Ele
continua não carregando a informação sozinho — o número ao lado diz a mesma
coisa em texto e o `aria-label` diz a distribuição inteira, que é o que mantém
a leitura de pé no escuro e no leitor de tela
([o painel gerencial](painel-gerencial.md)).

Os estados dos dias seguem a mesma regra da US008: cor **e** ícone, nunca só
cor. É o que faz "No documento" e "Vazio", que partilham o mesmo cinza, se
separarem pelo cadeado nos dois temas.

## Verificação

Os testes rodam com `npm test`, ao lado do código.

[`theme.test.ts`](../../web/src/theme/theme.test.ts) — a regra, sem React:

| Cenário                            | O que se afirma                                    |
| ---------------------------------- | -------------------------------------------------- |
| Aparelho sem nada guardado         | nasce em "sistema"                                 |
| Escolha gravada e lida de novo     | permanece entre sessões (CA#1 da US024)            |
| Lixo no armazenamento              | volta ao padrão, sem quebrar                       |
| Armazenamento bloqueado            | não derruba o aplicativo, nem ao ler nem ao gravar |
| "Sistema" com o aparelho no escuro | resolve para escuro                                |
| Escolha explícita                  | ignora o aparelho                                  |
| Sem `matchMedia`                   | fica no claro                                      |
| Aplicar o tema                     | liga a classe, o `color-scheme` e a cor da barra   |

[`theme-choice.test.tsx`](../../web/src/theme/theme-choice.test.tsx) — o
controle:

| Cenário                              | O que se afirma                          |
| ------------------------------------ | ---------------------------------------- |
| As opções oferecidas                 | claro, escuro e sistema, os três à vista |
| Quem nunca escolheu                  | abre em "Sistema"                        |
| Escolher "Escuro"                    | escurece a tela na hora                  |
| Escolher "Claro" com aparelho escuro | clareia, e a escolha vence o aparelho    |
| Fechar e abrir de novo               | volta escuro (CA#1 da US024)             |
| O aparelho anoitece com o app aberto | em "Sistema", a tela escurece junto      |
| O mesmo, com escolha explícita       | a tela não se mexe                       |
| Voltar para "Sistema"                | volta a acompanhar o aparelho na hora    |

E nas telas, onde o controle de fato mora:
[`month-view.test.tsx`](../../web/src/month/month-view.test.tsx) verifica as
três escolhas dentro do menu da merendeira, e
[`administration.test.tsx`](../../web/src/admin/administration.test.tsx), no pé
da barra da direção.

Fora dos testes, as telas foram percorridas nos dois temas contra o Supabase
local — login, visão do mês, menu, registro do dia com um cartão aberto,
painel com os dois gráficos, gestão, mapas e a confirmação de reabertura.
