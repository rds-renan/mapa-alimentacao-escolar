# Documentos gerados e compartilhamento no aplicativo

A US014 (incluindo o CA#1, a folha de compartilhamento do Android) e a US021 no
aplicativo — as telas [6 e 2b da E3](../03-ux/telas.md#2b--documentos-gerados),
issue #109. O raciocínio da tela, as cinco situações de um documento e o
porquê de a 6 e a 2b serem uma tela só estão em
[documentos gerados](../05-web/documentos-gerados.md), na web, e valem aqui.
O que segue registra o que é do aplicativo. O código está em
[`app/lib/pages/generated_documents_page.dart`](../../app/lib/pages/generated_documents_page.dart)
(a tela), em [`app/lib/documents/`](../../app/lib/documents/) (`generated.dart`
com as regras, `document_card.dart` com o cartão, `document_sharer.dart` com a
folha) e em [`app/lib/local/`](../../app/lib/local/) (a cópia local e a porta
para o servidor).

## Os critérios de aceite

| Critério | Onde |
|---|---|
| O arquivo é baixado para o aparelho e compartilhado pela folha do Android | `PlatformDocumentSharer`: baixa os bytes, grava na pasta temporária do aplicativo e abre a folha do sistema com o `.docx` anexado |
| Lista dentro dos 7 dias; os vencidos aparecem como indisponíveis | `availabilityOf` (porto de `generated.ts`): "Fora do ar", sem botão, com a nota de que os mapas continuam guardados |
| A lista abre sem rede, do banco local; abrir e compartilhar exigem rede | tabela `generated_documents` no Drift; sem rede o botão fica desabilitado e um aviso diz por quê, antes do toque |
| Falha de geração tratada com os textos da E3 | a recusa do pedido é da [seleção de mapas](selecao-de-mapas-e-geracao.md#a-porta-da-geração); aqui, a geração que morreu no meio aparece como "Não saiu", dizendo que nenhum mapa foi bloqueado |

## O que muda em relação à web

**Compartilhar é a folha do Android, e não há botão de baixar.** Na web
compartilhar é baixar (decisão 9 da E5); no aparelho a folha **é** o caminho —
é por ela que o arquivo chega ao WhatsApp da secretaria. Um segundo botão
"Baixar" seria uma pasta de Downloads que a merendeira não procura. O arquivo
é o mesmo (CA#2 da US014) e o envio continua sendo sempre ação dela (RN#1 da
US014).

**O arquivo vem pela sessão, sem link assinado.** A web assina um link de um
minuto porque o navegador precisa de um endereço para baixar. O aplicativo
precisa só dos bytes, e a política do balde que assinaria o link é a mesma que
autoriza `storage.download`: o registro tem de existir, ser da escola, estar
disponível e dentro do prazo. O arquivo é baixado **a cada pedido** — o que
vale é o que está no ar agora, e ele some depois de sete dias —, para a pasta
temporária do aplicativo, que o sistema limpa quando precisa de espaço.

**A lista é do aparelho.** Segue o [banco local](banco-local.md): `watch` lê só
o SQLite, `refresh` busca as vinte últimas gerações e substitui a cópia. A tela
abre mostrando o que já está no aparelho e atualiza por baixo, ao abrir e
quando a rede volta. O que o servidor deixou de devolver sai da cópia também.
O período e a quantidade de mapas continuam derivados da ligação
`document_meal_map` (decisão 10 da E4); as datas moram numa coluna só, em texto
separado por vírgula, porque só se leem juntas — nunca se consulta "documentos
que incluem o dia X". A migration do esquema local é só aditiva
(`schemaVersion` 4).

**Sem nada no aparelho, a falha tem saída.** Primeira abertura sem rede, ou com
o servidor fora: se há cópia, a tela mostra a cópia e nada mais; se não há, diz
que foi só a lista que não veio e oferece "Tentar de novo".

**O recém-pronto chega pela navegação.** A [seleção de mapas](selecao-de-mapas-e-geracao.md)
troca de lugar com esta tela (`pushReplacement`) passando o identificador do
documento em `extra`. É um fato daquela ida, não do servidor: abrir a tela pelo
menu amanhã mostra só a lista, e o bloqueio de três dias atrás não é notícia.
A tela 6 é o primeiro cartão, com o botão em destaque, o nome do arquivo e o
aviso do bloqueio, dito uma vez.

O [aviso da tela-casa](aviso-de-documento-pronto.md) usa a mesma porta: o
documento que ela ainda não tinha visto é notícia, e o cartão dele vira a
tela 6.

**Não há "geração em curso" vinda de outra tela.** A web reencontra a mutação
com chave que vive acima das rotas. No aplicativo a geração dura menos de um
segundo e o pedido é da tela de seleção; o registro `processing` aparece aqui
como "Gerando" se um dia vier da lista.

**O texto do aviso do alto não é o da web.** A frase da web promete que o
documento "aparece aqui quando ficar pronto, não é preciso esperar na tela". No
aplicativo, a geração exige rede e não tem fila (decisão 7 da E6), então a frase
diz o que de fato vale: gerar e compartilhar precisam de internet, e a lista
abre sem ela. O aviso de documento pronto ao abrir é o [da issue #110](aviso-de-documento-pronto.md).

## O pacote da folha

`share_plus` abre a folha do sistema, e `path_provider` dá a pasta temporária
onde o arquivo é gravado antes — a folha lê um arquivo, não bytes. É a pendência
que a [decisão 14 da E6](decisoes-tecnicas.md) deixou para esta issue. Os dois
ficam atrás de `DocumentSharer`, como os outros portões (decisão 4): a folha é
do sistema e não roda em teste.

Quem fecha a folha sem escolher nada não errou nada, e a tela não reclama. Se o
arquivo não vem (rede, link vencido, disco), vale a frase `fileFailed`: ele
continua no ar até a data que o cartão mostra, e dá para tentar de novo.

## Verificação

`flutter test`, junto do código:

- [`generated_test.dart`](../../app/test/documents/generated_test.dart) — as regras
  sem Flutter: a situação em cada fronteira de prazo (amanhã, hoje à noite,
  vencido), o período nas suas formas, as linhas de apoio.
- [`documents_repository_test.dart`](../../app/test/local/documents_repository_test.dart) —
  a cópia local: ordem, substituição, a falha que não toca a cópia, a leitura
  da resposta do servidor.
- [`generated_documents_page_test.dart`](../../app/test/pages/generated_documents_page_test.dart) —
  a tela: as cinco situações, compartilhar, a falha do arquivo, sem rede com
  cópia e sem cópia, a lista vazia e o recém-gerado.

**O que não está coberto e vai à mão no aparelho:** a folha do Android de
verdade — abrir o WhatsApp com o `.docx` anexado e conferir que ele chega com o
nome certo e abre —, e o `storage.download` contra o Supabase de produção, que
os testes substituem por um falso. É o passo "gerar e compartilhar" do caminho
crítico da [decisão 13](decisoes-tecnicas.md).
