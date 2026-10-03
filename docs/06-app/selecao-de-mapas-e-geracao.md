# Seleção de mapas e pedido de geração no aplicativo

A US012 e a US013 no aplicativo — a [tela 5 da E3](../03-ux/telas.md#5--seleção-de-mapas),
issue #108. A regra e o raciocínio são os da web, descritos em
[seleção de mapas e pedido de geração](../05-web/selecao-de-mapas.md): três
modos, **pendente nunca entra em documento**, dia bloqueado entra, dia que não
subiu fica de fora, uma só confirmação. O que segue registra só o que é do
aplicativo. O código está em
[`app/lib/pages/select_maps_page.dart`](../../app/lib/pages/select_maps_page.dart)
(a tela) e em [`app/lib/documents/`](../../app/lib/documents/) (`selection.dart`
com a regra, `messages.dart` com os textos, `generation_gateway.dart` com o
pedido e as peças da tela).

## Os critérios de aceite

| Critério | Onde |
|---|---|
| Dias avulsos, semana ou mês | `SegmentedButton` com os três modos; abre em "Mês inteiro", já marcado. Trocar de modo limpa a escolha |
| Dia pendente desabilitado; dia esperando envio fora do documento, com "Enviar agora" | `toOption`/`missingReason` (porto de `selection.ts`); a linha diz o motivo, e a faixa "Enviar agora" aparece quando há dia só no aparelho |
| A única confirmação do fluxo, antes do bloqueio | `AlertDialog` com o texto da E3. Não fecha com toque fora; o voltar do Android conta como "Voltar" |
| Sem rede, a tela explica a espera | o aviso toma o lugar da contagem e o botão fica desabilitado; reage a `ConnectivityGateway.onChange`, sem reabrir a tela |

## O que muda em relação à web

**O "esperando enviar" vem da fila, não de uma junção de duas leituras.** A
web funde o servidor com o rascunho na camada de dados. No aplicativo a visão
do mês só lê o banco local, e o rascunho mora na fila (`SyncEngine.pendingDays`).
A tela faz a junção ao desenhar: onde há rascunho vale o rascunho, **menos o
bloqueio e o identificador** (`DayRecord.withDraft`) — a mesma regra da web.
`DayRecord` ganhou `id` e `unsent` por isso; a visão do mês não os usa.

**O identificador do mapa precisa estar na cópia local.** A geração recebe os
identificadores **do servidor**. Desde a [#124](registro-do-dia.md), a fila
grava o dia confirmado na cópia local já com o identificador que o servidor
devolveu; antes disso, um dia que acabou de subir só o tinha depois de um
`refreshMonth`, e ficaria "sem registro" e fora do documento. A tela continua
refazendo a leitura do mês ao abrir, quando um dia sai da fila e depois de
"Enviar agora" — é ela que traz o que mudou por outro aparelho e o bloqueio.

**A geração termina mesmo que ela saia da tela.** O `Future` do pedido não
depende do widget, e a navegação para os documentos gerados só acontece se a
tela ainda estiver aberta (`mounted`). O que a web resolve com uma mutação com
chave, aqui é isso — sem estado global, porque o aplicativo não tem como
reencontrar a geração em curso ao voltar, e ela dura menos de um segundo.

**Antes de sair, a tela relê o mês.** Os mapas acabaram de ficar bloqueados, e
a visão do mês é lida da cópia local: sem o `refreshMonth` ela mostraria o dia
ainda editável, e a edição seria recusada pelo servidor. Se a rede cair nesse
meio-tempo a leitura falha em silêncio — o documento já saiu, e o mês se
atualiza na próxima vez que ela abrir a tela.

**O texto de "sem internet" não é o da E3.** A frase desenhada — "assim que
houver, os mapas sobem e o documento fica pronto em Documentos gerados" —
promete uma geração que acontece sozinha, e essa fila não existe (decisão 7 da
E6; decisão 10 da E3). A do aplicativo diz o que de fato acontece: sem
internet não dá para gerar, e é só tocar de novo quando voltar. A web ainda
carrega a frase da E3.

**A caixa de marcar é desenho próprio.** O `Checkbox` do Material, desabilitado,
fica cinza mesmo marcado, e nos modos "Mês inteiro" e "Semana" todas as linhas
são só para ver. A linha inteira é o toque e diz o estado pela semântica
(`checked`/`enabled`); a caixa (`CheckMark`) só desenha, com a borda em
`onSurfaceVariant` — no tema escuro o `outline` tem a mesma cor da superfície
atrás dele (a lição do interruptor, na [#105](registro-do-dia.md)).

## A porta da geração

`GenerationGateway` isola `functions.invoke('generate-document')` como os outros
portões (decisão 4 da E6), com falso nos testes, e lança sempre
`GenerationFailure` com a frase pronta. `generationFailureMessage` alcança a
frase que o servidor escreveu em `FunctionException.details` (o equivalente do
`readFailure` da web); sem resposta, vale a da E3 — "a internet caiu no meio do
caminho; nenhum foi bloqueado". Qualquer falha ganha a linha "nenhum foi
bloqueado" se a frase ainda não a disser, porque é sempre verdade: o bloqueio
acontece junto com a publicação do documento.

Gerada com sucesso, a tela **troca** de lugar com os documentos gerados
(`pushReplacement`): o voltar leva ao mês, e não de volta a uma seleção cujos
dias acabaram de mudar. O identificador do documento que acabou de sair vai
junto, em `extra`, e é com ele que a [tela de documentos](documentos-gerados.md)
desenha o cartão recém-gerado (issue #109).

## Verificação

`flutter test`, junto do código:

- [`selection_test.dart`](../../app/test/documents/selection_test.dart) — a regra
  sem Flutter: quem entra, o motivo de quem não entra, o rascunho sobre o
  servidor, o rótulo do período (um, dois, três meses, dois anos) e a frase da
  recusa.
- [`select_maps_page_test.dart`](../../app/test/pages/select_maps_page_test.dart) —
  os critérios, um a um: mês inteiro marcado ao abrir, dia bloqueado que vai
  junto, mês com pendente e com dia sem registro, modo semana, dias avulsos, o
  dia esperando enviar até "Enviar agora" o subir, sem rede, a confirmação (e
  "Voltar" que não gera nada), a geração com os 22 identificadores e a falha
  com "Tentar de novo".

**O que não está coberto e vai à mão no aparelho:** a largura dos três modos
numa tela estreita — o teste de widget usa uma fonte larga demais para dizer
qualquer coisa útil sobre isso — e o caminho inteiro contra o Supabase de
verdade (a Edge Function nunca é chamada nos testes).
