# Documentos gerados

A [tela 6](../03-ux/telas.md#6--documento-gerado) mostra o documento pronto; a
[tela 2b](../03-ux/telas.md#2b--documentos-gerados) lista os que ainda estão no
ar. Na web elas são **uma tela só**, e a razão está na própria história das
duas: a 2b nasceu na E3 porque a 6 é um beco — saindo dela, o arquivo ficava
inalcançável até expirar ([decisão 10 da E3](../03-ux/decisoes-de-design.md)).
Juntá-las resolve o beco pela raiz. O documento recém-gerado é o primeiro
cartão da lista, no mesmo lugar onde ele estará amanhã.

![Documentos gerados](../assets/e3-2b-documentos-gerados.png)

O que a tela 6 tinha e a lista não teria fica dentro daquele primeiro cartão,
e só nele: a confirmação de que saiu, o nome do arquivo e o aviso do bloqueio
— a consequência irreversível, dita **uma vez**, no momento em que acontece.
Quem chega aqui pelo menu vê só a lista, que é o certo: o bloqueio de três
dias atrás não é notícia.

## Na web, compartilhar é baixar

O CA#1 da US014 fala da folha de compartilhamento do Android, que é recurso de
plataforma e é entregue na E6. Na web vale a
[decisão 9 da E5](decisoes-tecnicas.md#9-na-web-compartilhar-é-baixar): **baixar
é o caminho**, e o botão de compartilhamento nativo aparece quando o navegador
souber fazê-lo.

"Souber" não é "ter `navigator.share`". Existe navegador que tem a função e
recusa arquivos — e um botão que promete e não entrega é pior do que um botão
que não existe. A pergunta se faz com um arquivo de mentira do mesmo tipo:

```ts
navigator.canShare({ files: [new File([new Uint8Array(1)], 'mapa.docx', { type: DOCX })] })
```

Mesmo assim o navegador pode mudar de ideia diante do arquivo de verdade, e
aí o caminho não é um erro: é baixar. A promessa desta tela é entregar o
arquivo, e ela se cumpre dos dois jeitos.

O que a estratégia de aceitação institucional exige se preserva inteiro: **o
arquivo é o mesmo** (CA#2 da US014) e o envio é sempre ação da merendeira, pelo
aplicativo que ela escolher (RN#1 da US014). O sistema nunca envia sozinho.

## O nome do arquivo mora no registro

O nome com que o documento chega em quem o recebe
(`mapa-da-alimentacao-escolar-setembro-2026.docx`) não é detalhe: o arquivo vai
para o WhatsApp da secretaria e vive lá ao lado de dezenas de outros. Até esta
issue ele só existia **dentro da geração** — a Edge Function o calculava e o
embutia no link assinado que devolvia na hora.

Isso bastava enquanto o link era usado ali mesmo. Não basta para esta tela, que
assina um link novo dias depois. Então o nome passou a ser gravado:
`generated_document.file_name`, carimbado por `complete_document_generation`
junto com o caminho e a validade
([migration](../../supabase/migrations/20260920120000_nome_do_arquivo_publicado.sql)).

A alternativa era recalcular a regra no navegador, a partir das datas dos mapas
incluídos. Seria uma segunda implementação da mesma regra, em outra linguagem,
livre para divergir em silêncio — e o preço da divergência é o mesmo documento
chegando à secretaria com dois nomes. `document_template` já fazia assim,
`file_name` ao lado de `file_path`, pelo mesmo motivo: o caminho no balde é
endereço, não nome.

## O balde assina o link, e o servidor não entra nisso

A geração precisava de uma Edge Function porque o **modelo oficial** mora num
balde privado e não pode passar pelo navegador (RNF#1 da US012). Ler o que já
saiu não precisa: as políticas da E4 já deixam a merendeira ler
`generated_document` da sua escola, e a política do balde já deixa ler o objeto
quando o registro existe, é da escola, está disponível e ainda dentro do prazo.

Então a tela pede o link ela mesma, com `createSignedUrl`, e o nome gravado vai
junto no parâmetro `download` — é o que faz o arquivo chegar com o nome certo,
e não com o identificador que ele tem no balde.

O link vale **um minuto**. Não é zelo: ele é pedido no toque do botão e usado
no instante seguinte, e um link de uso imediato que durasse horas seria um
documento da prefeitura circulando por engano. A validade que importa continua
sendo a do banco, de sete dias — o link apenas cabe dentro dela.

Por ser de uso único e de vida curta, pegar o arquivo é uma **mutação**, e não
uma consulta: guardar em cache algo que vence em um minuto seria guardar um
link morto.

## As cinco situações de um documento

Nenhuma delas está gravada. A situação é a comparação entre o prazo que o banco
carimbou e o dia em que a merendeira está olhando, e por isso ela se calcula na
leitura — como o estado do dia na visão do mês.

| Situação | Quando | O que a tela faz |
|---|---|---|
| Gerando | o registro está em `processing` | diz que aparece aqui quando ficar pronto |
| Disponível | no ar, com mais de um dia de folga | baixa, e diz a data em que sai |
| Sai amanhã / Sai hoje | no ar, vencendo hoje ou amanhã | baixa; a etiqueta já diz o prazo |
| Fora do ar | passou dos 7 dias | sem botão, e a nota do CA#3 |
| Não saiu | o registro está em `failed` | sem botão, e diz que nada foi bloqueado |

"Sai amanhã" é conta de **calendário**, e não de vinte e quatro horas: é assim
que se pensa num prazo, e um documento que vence às 23h de hoje não sai "em um
dia" para quem olha às 8h da manhã. O desenho da E3 só previu "Sai amanhã"; o
"Sai hoje" existe porque o último dia também acontece.

A cor nunca é o único sinal (RNF#1 da US008). "Fora do ar" e "Não saiu" são os
dois cinzas que precisam se separar, e quem os separa é o ícone.

### As duas situações que a E3 não desenhou

"Gerando" e "Não saiu" não estão no desenho, e estão aqui porque o registro da
geração **sobrevive à falha** ([decisão 10 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)).
Sem elas, uma geração que morreu no meio sumiria sem explicação, e a merendeira
ficaria esperando um arquivo que nunca vem. A frase da falha obedece à regra de
linguagem da E3 — diz primeiro o que **não** se perdeu —, e é verificável: o
bloqueio acontece na mesma transação que publica o documento, então geração que
falhou não bloqueou nada.

A geração em curso aparece nesta tela mesmo tendo sido pedida na outra: a
mutação vive no cliente da Query, que está acima das rotas. É o que cumpre a
promessa do aviso do alto — "não é preciso esperar na tela".

## O período, que também é derivado

Período e quantidade de mapas nascem da ligação `document_meal_map`, e não de
colunas ([decisão 10 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)). O
título do cartão tem três formas, e a régua entre elas é não mentir:

| O que entrou | Título |
|---|---|
| Um dia | `10 de setembro` |
| Todos os dias úteis do mês | `Setembro · mês inteiro` |
| Qualquer outro recorte | `1 a 12 de setembro` |

"Mês inteiro" é conta, não palpite: o mês fechado, no MAE, é exatamente os dias
úteis — o dia não letivo também tem mapa, e o fim de semana só entra quando
alguém registrou. Faltando um dia útil, o título volta a ser o intervalo, que é
o que o documento realmente cobre; quais dias entraram é o que a tabela do
arquivo mostra, linha a linha.

## Dois documentos do mesmo período

Depois de uma correção (US023), o período é gerado de novo e passam a existir
dois documentos cobrindo os mesmos dias. A
[geração](geracao-do-documento.md#um-mapa-pode-entrar-em-mais-de-um-documento)
deixou a pergunta em aberto: qual deles vale?

**A ordem responde.** A lista vem do mais novo para o mais velho, e cada cartão
diz quando foi gerado — "gerado hoje, 14h32", "gerado em 1 de setembro". O mais
recente está no topo, que é onde ela olha. Esconder o antigo seria sumir com um
arquivo que ainda existe e que ela talvez já tenha enviado; marcá-lo como
"substituído" exigiria inventar uma regra de "mesmo período" que a E3 não
desenhou, para resolver o que a ordem já resolve.

A hora só aparece no documento gerado **hoje**, que é justamente quando ela
distingue duas gerações. Num documento de três dias atrás, a hora é ruído.

## A lista não abre mapa nenhum

RN#2 da US021, e é literal: não há caminho daqui para o registro do dia. A
lista é sobre o arquivo; os mapas que entraram nele estão bloqueados, e o
caminho para corrigir um é a direção reabri-lo (US023).

## O que a lista mostra, e até onde

As **vinte últimas** gerações. O registro é permanente de propósito, então a
tabela só cresce; a tela, não. Vinte cobre bem mais de um ano de uso — a escola
gera um documento por mês, mais as regerações de correção —, e o que cai fora
disso já não é "voltar ao documento que acabei de gerar", que é do que esta
tela trata. Reemissão fora da janela dos sete dias continua sendo a US018,
pós-MVP.

## Sem internet

O RNF#1 da US021 pede que a lista abra offline com o que já foi sincronizado, e
que abrir ou compartilhar o arquivo exija rede. A segunda metade vale aqui
inteira: sem rede, o aviso toma a tela e os botões ficam desabilitados —
explicar a espera em vez de deixar o toque falhar em silêncio.

A primeira metade é do aplicativo. A web não promete navegar offline
([decisão 2 da E5](decisoes-tecnicas.md)): sem rede desde o começo, a própria
lista não chega, e o que ela vê é a mensagem de falha, que diz primeiro que os
mapas continuam guardados. Quem já estava com a lista na tela a mantém — é
cache da Query, não promessa.

## Verificação

Os testes rodam com `npm test`, ao lado do código, e se dividem em dois pela
mesma razão de sempre: o que pode estar errado aqui é a regra, não o desenho.

[`generated.test.ts`](../../web/src/documents/generated.test.ts) — a situação e
o período, sem React e sem rede. O relógio é sempre explícito, porque é dele
que sai a resposta:

| Cenário | O que se afirma |
| --- | --- |
| No ar, com folga | disponível, e baixa |
| Vencendo amanhã, e vencendo hoje à noite | ainda baixa |
| Passado o prazo | fora do ar, e não baixa |
| Geração em curso | não oferece arquivo |
| Geração que falhou | fica no registro, e não oferece arquivo |
| Um dia só | o título é a data |
| Todos os dias úteis do mês | "Setembro · mês inteiro" |
| O mesmo mês, menos um dia útil | volta a ser intervalo |
| Seleção entre meses, e entre anos | nomeia os dois lados sem mentir |
| Gerado hoje / em outro dia | a hora aparece só hoje |

[`generated-documents.test.tsx`](../../web/src/documents/generated-documents.test.tsx)
— os critérios de aceite da issue, um a um:

| Cenário | O que se afirma |
| --- | --- |
| A lista abre | período, quantos mapas, quando saiu e quando sai do ar |
| Dois documentos | o mais novo vem primeiro |
| Qualquer documento | nada leva para o registro do dia (RN#2 da US021) |
| Nenhum documento ainda | aponta para onde se gera o primeiro |
| A lista não vem | diz primeiro o que não se perdeu, e oferece tentar |
| Documento vencido | "Fora do ar", sem botão, e os mapas continuam guardados |
| Geração que falhou | à vista, dizendo que nada foi bloqueado |
| Toque em "Baixar" | assina o link com o nome que a geração gravou |
| O link não sai | diz que o arquivo continua no ar |
| A rede cai com a lista na tela | a espera é explicada e o botão não engana |
| Navegador sem compartilhamento de arquivo | só "Baixar" |
| Navegador com a API | "Compartilhar", e manda o arquivo (CA#2 da US021) |
| Chegando de uma geração | o primeiro cartão é a tela 6, com o aviso do bloqueio |
| Chegando pelo menu | é a lista e nada mais |

No banco, [`geracao-do-documento.test.sql`](../../supabase/tests/geracao-do-documento.test.sql)
ganhou dois cenários: o nome do arquivo é carimbado junto com a publicação, e
publicar sem nome não passa.

## O peso do pacote, que continua apertado

Esta issue somou **3,1 kB em gzip** à carga inicial: o pacote foi de 200,0 kB
para **203,1 kB**, contra o
[teto de 205 kB](integracao-continua-e-publicacao.md#o-teto-que-é-um-lembrete-e-não-uma-meta)
que a CI verifica. **Sobram 1,9 kB.**

A issue anterior já avisou que o teto acenderia antes do painel gerencial, e
ele vai acender: a próxima tela não cabe. O que se faz quando acender continua
o mesmo — carregar a rota pesada com `lazy()`, ou subir o teto num commit que
diga por quê. A área da direção é a candidata óbvia ao `lazy()`: a merendeira
nunca a abre, e é ela que vai trazer a biblioteca de gráficos.
