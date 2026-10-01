# Aviso de documento pronto ao abrir o aplicativo

O que ficou no lugar da notificação do sistema desenhada na E3, issue #110 — a
[decisão 10 da E6](decisoes-tecnicas.md#10-documento-pronto-é-aviso-ao-abrir-não-notificação-por-push)
explica por que o push não nasceu; aqui está o que o aplicativo faz. O desenho
está no [catálogo de avisos](../03-ux/avisos-e-mensagens.md#ao-abrir-o-aplicativo).
O código está em
[`app/lib/documents/ready_notice.dart`](../../app/lib/documents/ready_notice.dart)
(o aviso), em
[`seen_documents.dart`](../../app/lib/documents/seen_documents.dart) (a regra e
o "já visto") e na [tela-casa](../../app/lib/pages/home_page.dart), onde ele
mora.

## Os critérios de aceite

| Critério | Onde |
|---|---|
| Documento pronto e ainda não visto aparece em destaque ao abrir, com "Compartilhar" levando à tela do documento | `DocumentReadyNotice`, no alto da tela-casa; "Compartilhar" abre a [tela de documentos](documentos-gerados.md) com o documento como o recém-pronto (o cartão da tela 6) |
| O "já visto" fica no aparelho, sem migration | `SeenDocuments`, em `shared_preferences`; o esquema do Drift não muda (`schemaVersion` continua 4) |
| Artboard, PNG e catálogo de avisos | `design/telas/AvisosAoAbrir.dc.html`, `docs/assets/e3-avisos-ao-abrir-o-app.png`, [avisos e mensagens](../03-ux/avisos-e-mensagens.md) |
| Mudança registrada na #80 | comentário na issue |

## Quando o aviso aparece

Ao abrir, a tela-casa lê a lista de documentos do banco local (a cópia da
[#109](documentos-gerados.md)) e, por baixo, pede a lista ao servidor. A busca
falhar não muda nada: o aviso fala do que já está no aparelho, e a rede só o
melhora — a mesma postura da visão do mês, que nunca condiciona a tela a abrir.

Entra no aviso o documento **pronto** — o mesmo critério de "dá para abrir
agora" (`downloadable`) — que ela **ainda não viu**. Um documento que saiu do ar
ou que não terminou não é notícia (`unseenReady`). Com mais de um, o aviso fala
do mais recente e conta quantos são: "2 documentos ficaram prontos", "O mais
recente é de 1 a 12 de setembro · 10 mapas.". O texto da E3 ("O documento ficou
pronto") é a frase da notificação que o aviso substitui.

Primeira abertura depois de instalar: tudo o que está no ar conta como não
visto, então a merendeira pode ver o aviso de um documento de poucos dias atrás.
É aceito de propósito — o documento ainda dá para compartilhar, e distinguir
"gerado antes de eu instalar" não compra nada.

## Quando algo é "visto"

De dois jeitos, e os dois valem para tudo o que estava pronto naquela hora:

- **Abrir a tela de documentos**, venha ela pelo aviso ou pelo menu. Listar um
  documento é vê-lo: a tela marca cada documento pronto que a lista mostra.
  Isto cobre também o documento que ela mesma acabou de gerar — a geração
  troca de lugar com a tela de documentos, que o marca na hora.
- **O X do aviso.** Sem ele o aviso seria uma pendência que ela não consegue
  dispensar sem abrir a tela; com ele, quem não quer compartilhar agora tira o
  destaque sem perder o documento, que continua na lista.

## Onde o "já visto" mora

No aparelho, uma chave por perfil (`mae.seen_documents.<id do perfil>`), como o
arquivo de banco por perfil: duas contas no mesmo aparelho não herdam o que a
outra viu. É estado de leitura de uma pessoa num aparelho, e não fato da escola
— por isso não vai para o Supabase, e por isso nem o Drift o guarda: ele
ganharia uma migration para uma lista de identificadores que não se consulta
junto com mais nada.

`shared_preferences` entrou por isso, e é o primeiro uso de armazenamento de
preferência no aplicativo — o tema escuro (#111) é o próximo e vai à mesma
porta. A sessão continua em `flutter_secure_storage` (decisão 9): ela é
segredo, e esta lista não é.

Guardam-se os últimos 100 identificadores. A lista do servidor traz as últimas
vinte gerações, então o que passa disso já não volta, e guardar para sempre
seria só acumular.

**Falha de armazenamento não derruba nada.** Sem ler, vale "nada visto"; sem
gravar, vale o que está na memória até fechar o aplicativo. O pior caso é o
aviso voltar uma vez a mais, e nunca deixar de aparecer o que ela não viu.

## O que não está aqui

- **Nada roda em segundo plano.** O aviso só se calcula com o aplicativo
  aberto; é a decisão 10, e é o que faz o push desnecessário.
- **O aviso não reage à rede que volta.** A tela de documentos reage, e é lá
  que a lista fica em dia; a tela-casa só busca ao abrir. Se a rede estava fora
  na abertura, o aviso fala do que o aparelho já sabia — e reabrir o aplicativo
  completa.
- **Nenhum aviso de documento que falhou.** "Não saiu" é assunto da tela de
  documentos; o aviso é só do que ela pode compartilhar.

## Verificação

`flutter test`, junto do código:

- [`seen_documents_test.dart`](../../app/test/documents/seen_documents_test.dart) —
  a regra (pronto e não visto, na ordem; falhou, em curso e vencido ficam de
  fora; o que sai amanhã ainda avisa) e o armazenamento (sobrevive a reabrir,
  um por perfil, o limite, marcar antes de ler não perde o que estava
  guardado).
- [`ready_notice_test.dart`](../../app/test/pages/ready_notice_test.dart) — a
  tela-casa: aparece ao abrir, não aparece sem documento novo nem para o que já
  foi visto, o plural, "Compartilhar" abre o documento e some o aviso, abrir
  pelo menu também o marca, o X dispensa e grava, sem rede avisa do que já está
  no aparelho.

**O que não está coberto e vai à mão no aparelho:** o caso real que justifica
tudo isto — fechar o aplicativo no meio do pedido de geração e reabri-lo — e o
`shared_preferences` de verdade, que os testes substituem por um mapa em
memória.
