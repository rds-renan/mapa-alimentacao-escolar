# A reabertura de um mapa

Um mapa incluído em documento gerado fica bloqueado (RN#1 da **US007**), e até
aqui era só isso: descoberto um erro depois da geração, o sistema não oferecia
caminho nenhum. A **US023** abre a saída — a direção reabre o dia com
justificativa, a merendeira corrige, e o documento do período é gerado de novo.

É a história que o próprio Renan reclassificou para prioridade A na revisão da
E3, com um argumento que não é sobre frequência: no preenchimento manual elas
simplesmente refazem a folha, então um aplicativo que trave a correção seria
pior que o improviso que veio substituir. As merendeiras confirmaram que
alterar mapa pronto é raro — isso define o tamanho da função, não a necessidade
dela.

O código está em [`web/src/admin/`](../../web/src/admin/) (as consultas, os dois
cartões e o diálogo), em
[`web/src/pages/AdminMaps.tsx`](../../web/src/pages/AdminMaps.tsx) (a tela) e,
do lado da merendeira, em
[`web/src/month/`](../../web/src/month/) e
[`web/src/day/`](../../web/src/day/), que passaram a mostrar o dia reaberto.

## A issue não tem migration, e isso é o principal

Tudo o que o servidor precisa fazer aqui a **E4 já fez**:
`public.unlock_meal_map(map_id, unlock_reason)` exige o papel de direção, exige
justificativa não vazia, grava a linha em `meal_map_unlock` e desbloqueia o
mapa — **numa transação só**. Não existe caminho que reabra um mapa sem deixar
o registro de quem, quando e por quê
([projeto físico](../04-banco-de-dados/projeto-fisico.md)).

O que faltava era quem abrisse a porta. Nada do que está em
[`maps-queries.ts`](../../web/src/admin/maps-queries.ts) reimplementa essas
regras: reimplementá-las no navegador criaria uma segunda régua, livre para
divergir da que decide de verdade — e é a do banco que decide, porque é a que
vale também para quem não passa pela tela.

A função é `security definer`, e é por isso que ela atravessa o gatilho do
bloqueio: é a exceção prevista, não um furo. E ela **não move o carimbo de
última edição** — `stamp_meal_map_update()` devolve a linha intocada quando a
única diferença é o bloqueio. Sem isso a direção viraria "última editora" e
passaria a ganhar toda convergência entre aparelhos, decidindo a US011 pelo
evento errado. Era o erro que a E4 cometeu e corrigiu
([decisões técnicas](decisoes-tecnicas.md)), e agora há uma chamada de verdade
exercitando-o.

O que esta issue acrescentou no banco foi **teste**:
[`desbloqueio.test.sql`](../../supabase/tests/desbloqueio.test.sql), 28
asserções sobre uma função que estava de pé e nunca havia sido exercitada
inteira.

## Um terceiro destino para a direção

A E3 desenhou duas telas para a direção — Painel e Gestão — e é anterior à
revisão de escopo que criou a US023. A reabertura ganhou a terceira, **Mapas**,
e não um cartão dentro da Gestão: a Gestão é configuração (quem entra, com qual
modelo o documento sai, o que vai no cabeçalho dele), e reabrir um dia é outra
natureza — tem uma lista de dias e um histórico permanente, que num cartão
ficariam espremidos.

`design/telas/` e os PNGs foram atualizados no mesmo PR, que é o precedente da
#64 e da #68: quando a implementação e o desenho divergem, quem se move é o
desenho, no PR que o descobre.

**A direção continua sem caminho para o mapa.** Esta tela identifica o dia — a
data e em que documento ele saiu — e mais nada: não abre o registro, não mostra
o que está escrito nele e não o edita. Foi decisão explícita não lhe dar nem a
leitura do mapa: quem viu o erro foi a merendeira, e é ela que pede. Uma tela de
leitura do mapa pela direção seria história nova, não a US023.

### A lista mostra os sessenta dias mais recentes

Uma escola bloqueia cerca de vinte dias por mês, e a correção aparece dias
depois da geração — não meses. Sessenta cobre o trimestre corrente e o anterior,
e a tela **diz** que o corte existe, em vez de parecer completa e não ser. O
histórico tem o mesmo tratamento, com cinquenta, que é o corte da lista de
documentos gerados e pelo mesmo motivo: o registro é permanente e a tabela só
cresce; a tela, não.

### O documento em que o dia saiu

Cada linha diz "no documento de 30/09" — a informação que explica o bloqueio a
quem está olhando. Ela vem do vínculo `document_meal_map → generated_document`,
na mesma consulta, e um mapa pode estar em mais de um documento (é o que a
regeração depois de uma correção produz): a tela mostra o mais recente.

## A justificativa é a confirmação

O diálogo é confirmação **e** formulário, e não por economia de tela: a
justificativa é o que torna a reabertura admissível, então pedi-la já é a
decisão. Um "tem certeza?" antes disso seria um toque a mais dizendo o que a
frase seguinte diz.

É a única ação de toda a administração que interrompe, e pela razão que a
[decisão 11 da E3](../03-ux/decisoes-de-design.md) dá à confirmação da geração:
as outras têm volta na própria linha — desativar reativa, modelo se substitui —
e esta não tem. O que ela deixa é registro permanente.

O botão de confirmar é um `submit` comum, e não o `AlertDialogAction` da
biblioteca: aquele fecha o diálogo ao ser tocado, e este precisa continuar
aberto enquanto a chamada está no ar e depois dela, se ela falhar — com o que a
direção escreveu ainda no campo.

**Cada abertura começa em branco.** A justificativa é de um dia e de uma
correção; reaproveitar a da vez passada é o caminho mais curto para o registro
permanente dizer o motivo errado.

### As recusas chegam como a função as escreveu

`unlock_meal_map()` escreve as frases dela em português e para quem vai lê-las
— "A reabertura precisa de uma justificativa.", "Este mapa não está
bloqueado." —, então a tela entrega, e não traduz. O que separa esse caso do
outro é o código: erro do Postgres tem um; rede que não chegou a virar resposta,
não — e aí vale a frase escrita para a internet da escola, que diz primeiro o
que **não** mudou. Aqui isso é verificável, e não gentileza: a reabertura é uma
transação só, então ou registrou e desbloqueou, ou não fez nada.

## O que a merendeira vê

O CA#2 pede que o mapa reaberto volte a aceitar edição **e** apareça sinalizado.
A primeira metade já era verdade sozinha — reaberto é `locked = false`, e o
gatilho para de recusar a escrita. A segunda é o que esta issue acrescentou,
porque sem ela o dia reaberto ficaria idêntico a todos os outros na lista do mês
e ela não teria como achá-lo.

**Reaberto não é um estado do dia.** Os cinco estados da
[visão do mês](visao-do-mes.md) continuam cinco: um dia reaberto continua sendo
completo ou pendente, e continua contando no andamento do mês como o que é. O
sinal é uma etiqueta **ao lado** da do estado, com cor e ícone como a regra da
E3 exige (RNF#1 da US008) — e o cadeado aberto é, de propósito, o mesmo cadeado
do "no documento", do outro lado.

Na tela do dia, uma faixa no lugar da do bloqueio, e as duas nunca aparecem
juntas: o dia reaberto é, por definição, o que saiu do bloqueio.

> _"A direção reabriu este dia para correção. Ele voltou a aceitar edição, e o
> que você corrigir entra no próximo documento gerado."_

### A justificativa não chega a ela

Foi decisão de escopo: o texto que a direção escreve é **prestação de contas**,
e não recado. Ele fica no histórico, na área da direção, e a tela da merendeira
diz o fato — o dia foi reaberto para correção — sem o porquê. Quem diz o que
corrigir é a direção, por fora do sistema, que é como a conversa já acontece
hoje entre elas.

O caminho contrário estava sobre a mesa e é defensável: mostrar a justificativa
pouparia a conversa, e mudaria o que a direção escreve, porque o texto passaria
a ter dois destinatários. A escolha foi manter o registro com um só.

### Reaberto é "ainda fora de documento"

O histórico é permanente, então "já houve reabertura" é verdade para sempre. O
que a tela dela mostra é outra coisa: `locked = false` **e** pelo menos uma
reabertura. Voltando a um documento, o mapa é bloqueado de novo e o que ela
precisa ver é o bloqueio; o histórico continua lá, e continua sendo da direção.

### A fila do aparelho não precisou mudar

O caso existe: a merendeira edita sem rede, a geração acontece nesse meio-tempo,
e o envio é recusado porque o mapa está bloqueado. A
[camada local](camada-local.md) classifica isso como recusa que não passa — o
dia sai da fila e **continua guardado no aparelho**, que é o que a RN#1 da US011
exige.

Reaberto o mapa, a primeira tecla que ela digitar grava o rascunho de novo, e
gravar limpa a recusa: o dia volta à fila e sobe. Nada disso é novo — é o
comportamento que a #60 já tinha —, e vale registrar porque é exatamente o
desfecho que a US023 promete, acontecendo sem código a mais.

## O peso do pacote

A tela nova é da direção e carrega sob demanda, como as outras duas (decisão 14
da E5): ela não pesa no arranque de quem registra o mapa todo dia. O que entrou
na carga inicial foram os 0,5 kB do sinal do lado da merendeira — a etiqueta, a
faixa e o ícone do cadeado aberto —, e o teto de 205 kB ficou com **1,0 kB de
folga**. É pouco, e é bom que se saiba: a próxima coisa que precisar entrar no
pacote de todo dia vai ter de justificar o espaço ou dividir a rota.

## Verificação

No banco, com `supabase test db`:

[`desbloqueio.test.sql`](../../supabase/tests/desbloqueio.test.sql) — a função
inteira, com troca de papel de verdade (`set local role authenticated`), porque
metade do que se afirma é RLS:

| Cenário                                  | O que se afirma                                       |
| ---------------------------------------- | ----------------------------------------------------- |
| A merendeira tenta reabrir               | recusado, e o histórico não ganha linha                |
| A merendeira edita mapa bloqueado        | recusado — é o beco que a história abre                |
| Justificativa vazia, só espaço, nula     | as três recusadas, e o bloqueio não se mexe            |
| Mapa que não está bloqueado              | recusado; não se reabre o que nunca foi fechado        |
| Mapa fora da escola                      | não existe para a direção                              |
| A direção reabre                         | desbloqueia e registra quem, quando e por quê          |
| A hora do registro                       | é a do servidor                                        |
| O documento já gerado                    | continua registrado, e continua incluindo o mapa       |
| Inserir reabertura pela API              | recusado — quem grava é a função                       |
| Apagar o histórico                       | não dá erro: não alcança linha nenhuma                 |
| Depois da reabertura                     | a merendeira volta a editar, e a correção dela vale    |
| Reabrir o mesmo mapa de novo             | as duas reaberturas ficam no histórico                 |

Na web, com `npm test`:

[`map-unlock.test.tsx`](../../web/src/admin/map-unlock.test.tsx) — os critérios
de aceite da issue, um a um:

| Cenário                             | O que se afirma                                          |
| ----------------------------------- | -------------------------------------------------------- |
| A lista                             | só os bloqueados, do mais recente, agrupados por mês      |
| Cada linha                          | diz em qual documento o dia saiu                          |
| A tela                              | não abre nem mostra o conteúdo do mapa                    |
| A lista não veio                    | oferece tentar de novo                                    |
| Escola sem dia em documento         | explica quando um dia fica bloqueado                      |
| Sem justificativa                   | o botão de reabrir não funciona; espaço não conta         |
| Reabrir                             | manda a justificativa, desbloqueia e some da lista        |
| Cada abertura do diálogo            | começa com a justificativa em branco                      |
| Cancelar                            | não reabre nada                                           |
| Recusa do banco                     | chega com a frase da própria função, sem fechar o diálogo |
| Sem rede                            | diz que o mapa continua bloqueado                         |
| O histórico                         | de qual dia, por quem, quando e por quê                   |
| A reabertura recém-feita            | entra no histórico na hora                                |
| O histórico não veio                | diz que ele não se perdeu                                 |
| O dia reaberto, para a merendeira   | volta a aceitar edição e diz que foi reaberto             |
| A justificativa, na tela dela       | não aparece                                               |
| Na visão do mês                     | sinalizado, sem deixar de ser preenchido                  |
| O dia que voltou a um documento     | aparece como bloqueado, e não como reaberto               |

Ponta a ponta, contra o Supabase local, pela API REST: as duas consultas
aninhadas desta tela (o documento de cada mapa bloqueado, e o dia e o nome de
quem reabriu, no histórico); a reabertura recusada para a merendeira, para o
anônimo e sem justificativa; a reabertura feita pela direção, conferindo que
`updated_by` continuou sendo a merendeira; o `DELETE` do histórico pela
merendeira, que responde 204 e não apaga nada; e a correção do dia reaberto por
`save_meal_map`, que voltou a ser aceita.
