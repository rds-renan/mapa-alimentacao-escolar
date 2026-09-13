# A gravação do dia

O dia inteiro sobe numa chamada só. `save_meal_map` recebe o mapa, as três
refeições, a alteração do cardápio e os gêneros utilizados num único objeto, e
grava tudo ou não grava nada. É a operação que a fila de envio do cliente chama
([decisão 3](decisoes-tecnicas.md)) e a tradução em código da
[decisão 9 da E4](../04-banco-de-dados/decisoes-de-modelagem.md), que escolheu o
dia como unidade de sincronização.

Ela mora em [`supabase/migrations/20260911120000_gravacao_atomica_do_dia.sql`](../../supabase/migrations/20260911120000_gravacao_atomica_do_dia.sql).
Este documento é o contrato: o que o cliente manda, o que ele recebe de volta e
o que decidir em cada resposta.

## Por que existe

Sincronizar linha a linha exigiria marcar exclusões nas quatro tabelas-filhas e
resolver conflito em quatro níveis. Tratando o dia como unidade, o conflito
existe num lugar só — e cabe numa comparação de data, que é exatamente o que o
CA#3 da US011 pede.

Ela ficou fora da E4 de propósito. Migration é imutável, então um contrato
escrito antes de existir quem o consome custaria duas: uma para criá-lo e outra
para corrigi-lo assim que a primeira tela aparecesse. Pior que o retrabalho
seria o efeito colateral — um contrato que nasce antes do seu consumidor passa a
parecer imutável, e a aplicação acaba se moldando a regras que ninguém decidiu.

## O que entra

```json
{
  "id": "uuid gerado no aparelho",
  "map_date": "2026-09-10",
  "updated_at": "2026-09-10T18:30:00-03:00",
  "non_school_day": false,
  "note": null,
  "meals_served": 312,
  "meals": [
    {
      "id": "uuid",
      "type": "morning_snack",
      "description": "Pão com manteiga e leite com achocolatado",
      "acceptance": "great",
      "food_items": [
        { "food_item_id": "uuid", "name": "Pão", "unit": "quilo", "quantity": 4 }
      ],
      "menu_change": {
        "id": "uuid",
        "reason": "Não veio o frango na entrega da semana.",
        "food_items": [
          { "name": "Ovo", "unit": "bandeja", "quantity": 3 }
        ]
      }
    }
  ]
}
```

| Campo | Obrigatório | Observação |
|---|---|---|
| `id` | não | UUID do aparelho. Serve para criar o dia; se o servidor já tem um dia nessa data, vale o dele. |
| `map_date` | **sim** | É ela que identifica o dia, junto com a escola. |
| `updated_at` | não | Quando a merendeira editou, no relógio do aparelho. Ausente, vale o instante da chegada. |
| `non_school_day` | não | Falso por omissão. |
| `note` | só em dia não letivo | A observação que diz o motivo. No dia letivo é descartada. |
| `meals_served` | não | O registro pode ficar parcial (CA#3 da US001). Em dia não letivo é descartado. |
| `meals` | não | O que não vier deixa de existir — a lista é o dia inteiro, não um acréscimo. |
| `meals[].type` | **sim** | `morning_snack`, `lunch` ou `afternoon_snack`. |
| `meals[].description`, `acceptance` | não | Nulos são o registro pendente, de propósito. |
| `food_items[].food_item_id` | não | Quando existe, é o gênero do catálogo. |
| `food_items[].name`, `unit` | ver adiante | O `unit` só é exigido quando o gênero vai nascer. |
| `food_items[].quantity` | **sim** | Inteira e maior que zero (RN#1 da US003). |
| `menu_change.reason` | **sim**, quando há alteração | Sem justificativa a alteração não existe. |
| `menu_change.food_items` | **sim**, quando há alteração | Lista vazia é recusada: sem os gêneros que entraram, a troca não descreve nada. |

A escola **não** está no payload, e é de propósito: ela vem sempre do perfil de
quem chamou. Não há como pedir gravação na escola de outra pessoa.

A descrição da refeição continua sendo o cardápio **previsto**, mesmo quando
houve troca — é isso que dá sentido à justificativa
([decisão 7 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)). A alteração
guarda só o que entrou no lugar e por quê.

## O que sai

```json
{
  "status": "saved",
  "meal_map_id": "c0000010-0000-4000-8000-000000000010",
  "sent_meal_map_id": "c0000010-0000-4000-8000-000000000010",
  "map_date": "2026-09-10",
  "locked": false,
  "updated_at": "2026-09-10T21:30:00+00:00",
  "updated_by": "22222222-2222-4222-8222-222222222222",
  "food_items": [
    { "sent_id": null, "id": "5005748a-…", "name": "Achocolatado",
      "unit": "pote", "created": true }
  ]
}
```

| Campo | Para que serve |
|---|---|
| `status` | `saved` ou `superseded`. |
| `meal_map_id` | O identificador que **valeu**. Pode não ser o enviado. |
| `sent_meal_map_id` | O que o aparelho mandou, para ele saber o que trocar. |
| `updated_at`, `updated_by` | O carimbo que passou a valer no servidor. |
| `food_items` | Um item por gênero citado, com o identificador que valeu. `created` diz se ele acabou de nascer. |

O cliente **precisa** adotar o `meal_map_id` e os `food_items[].id` devolvidos:
são eles que fazem o próximo envio encontrar o registro em vez de tentar criá-lo
de novo.

## Conflito e reenvio: a mesma comparação

Tudo gira em torno de uma linha: **prevalece a edição mais recente**, comparando
o `updated_at` que chegou com o que está gravado.

| Situação | O que acontece |
|---|---|
| O dia não existe | Nasce, com o identificador enviado. |
| O enviado é **mais recente** | Grava. É a edição nova. |
| O enviado é **igual** | Grava. É o reenvio da fila, e reescrever o mesmo dia dá o mesmo dia. |
| O enviado é **mais antigo** | Não grava. Volta `superseded` com o estado do servidor. |

O caso do "igual" é o que torna a fila idempotente. Quando a rede cai entre a
gravação e a confirmação, o cliente reenvia sem saber se chegou; como a data da
edição é a mesma, o segundo envio reescreve o dia com o mesmo conteúdo, em vez
de criar um segundo mapa ou virar conflito falso.

Isso só funciona porque o carimbo é **a edição no aparelho**, não a chegada no
servidor. É a diferença entre "a última que ela mexeu" e "a última que chegou":
um mapa preenchido na sexta sem sinal e enviado no domingo precisa perder para a
correção feita no sábado pela colega. Carimbar a chegada inverteria o resultado,
e ainda quebraria o reenvio, porque o carimbo mudaria a cada tentativa.

Por isso o gatilho `stamp_meal_map_update` foi substituído nesta migration: ele
carimba o relógio do servidor quando a escrita vem direto pela tabela, e sai da
frente quando quem escreve é o servidor. Continua valendo o que a E4 já tinha
aprendido — reabertura não é edição e não pode mover o carimbo, senão a direção
viraria "última editora" e ganharia toda convergência (CA#3 da US011, US023).

Um detalhe de proteção: uma data de edição no futuro é reduzida ao instante da
chegada. Sem isso, um aparelho com o relógio adiantado ganharia todo conflito
para sempre.

**`superseded` nunca é resolvido em silêncio.** O cliente recarrega o dia do
servidor e avisa a usuária de que a colega editou depois — a regra é sinalizar,
não escolher por ela.

### O dia é a data, não o identificador

Duas merendeiras podem criar o mesmo dia offline, cada uma com o seu UUID. Quem
manda é o par (escola, data): o identificador que já está no servidor prevalece,
o do aparelho é descartado e o `meal_map_id` devolvido é o que vale. Sem isso o
índice único da tabela recusaria o segundo envio e a fila travaria para sempre
num item que nunca entraria.

## O catálogo dentro da gravação

O gênero pode nascer junto com a refeição — a merendeira não precisa parar para
cadastrá-lo antes (US009). A busca segue três passos, nesta ordem:

1. **Pelo identificador**, dentro da escola. É o caminho do reenvio: acha o que
   ele mesmo criou da primeira vez.
2. **Pelo nome**, ignorando maiúsculas e espaços repetidos. É o caminho da
   convergência: se a colega já cadastrou "Arroz", o "arroz " deste aparelho
   adota aquele em vez de duplicar.
3. **Criando**, com o nome e a unidade enviados. Só aqui o `unit` é exigido.

O gênero adotado mantém a unidade que já tinha: quem manda na unidade é o
catálogo, não o envio. Dois nomes que normalizam para o mesmo gênero dentro da
mesma refeição viram uma linha só, valendo a última quantidade.

Um identificador que existe mas é de outra escola é ignorado, e o gênero nasce
com identificador novo.

## Os erros, e o que a tela faz com eles

Todas as mensagens já são legíveis por quem vai lê-las — não há tradução a fazer
no cliente.

| Quando | Código | Como chega no HTTP | O que o cliente faz |
|---|---|---|---|
| Sem sessão | `42501` | 401 | Manda para o login. |
| Direção tentando registrar | `42501` | 403 | Não deveria acontecer: a rota já separa os perfis. |
| Mapa bloqueado | `23514` | 400 | Mostra a mensagem e o mapa como bloqueado; tira o item da fila. |
| Payload incoerente (sem data, refeição desconhecida, alteração sem gêneros, quantidade inválida, dia não letivo com refeição) | `23514` | 400 | Mostra a mensagem apontando o campo; tira o item da fila, porque reenviar dá o mesmo erro. |
| Dois aparelhos criando o mesmo dia no mesmo instante | `40001` | — | Mantém na fila e reenvia: na segunda vez o dia já existe e vale a comparação de datas. |

A distinção que importa para a fila: **`23514` e `42501` não se resolvem
reenviando** — é preciso corrigir ou avisar. `40001` se resolve reenviando.

## O que ela não faz

- **Não gera documento nem bloqueia mapa.** O bloqueio nasce na geração
  (US012), pela edge function, e sai por `unlock_meal_map` (US023). A coluna
  `locked` é só lida aqui.
- **Não decide se o dia está completo.** "As três refeições preenchidas" é
  critério de leitura, não restrição de gravação: o registro pode ficar parcial
  de propósito (CA#3 da US001).
- **Não consolida os gêneros por dia.** Isso é da geração do documento; aqui
  eles ficam por refeição
  ([decisão 7 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)).
- **Não guarda histórico de versões.** O que perde o conflito não é arquivado:
  prevalece a edição mais recente e o caso é sinalizado, e só.

## Onde as peças internas moram, e por quê

Resolver o gênero, validar a quantidade e montar a resposta são três funções
próprias, e nenhuma delas vive no `public`: ficam no schema `internal`.

O PostgREST publica como rota tudo que está nos schemas expostos, e o `public` é
um deles. Uma função que executa *metade* de uma gravação não é operação do
produto — é superfície de API que não precisa existir, e que um dia alguém
chamaria fora de ordem.

A alternativa seria deixá-las no `public` e revogar o `execute`. No papel dá no
mesmo; na prática, as rotas continuariam existindo e recusando caso a caso, e a
recusa dependeria de o Supabase não voltar a conceder `execute` por *default
privilege* na próxima função criada — que é exatamente como elas ganharam
permissão da primeira vez, e o motivo de o `revoke ... from public` sozinho não
ter bastado. Fora do schema exposto não há o que revogar nem o que reconceder.

`save_meal_map` é o caso oposto e continua executável por qualquer um, como
`unlock_meal_map`: a rota dela **tem** que existir, porque é por ela que o
aplicativo grava. Quem recusa é a própria função, nas primeiras linhas. Fechar a
porta devolveria um erro de permissão sem texto, e quem chegou sem sessão
precisa ser mandado ao login — não informado de que a função existe e não é
dele.

## Verificação

Os cenários estão versionados em
[`supabase/tests/gravacao-do-dia.test.sql`](../../supabase/tests/gravacao-do-dia.test.sql),
em pgTAP, e rodam com `supabase test db` — 66 asserções sobre um banco recém-
resetado. Mais cinco chamadas pela API REST, com o token de cada perfil, para
cobrir o caminho que o pgTAP não cobre: o do papel do banco de verdade,
atravessando o PostgREST.

O que está coberto:

| Cenário | Resultado |
|---|---|
| Dia novo com três refeições, gênero do catálogo, gênero novo e alteração | gravado |
| Carimbo é a edição do aparelho, não a chegada | confirmado |
| Reenvio da mesma carga | reescreve, sem duplicar mapa nem gênero |
| Edição mais antiga chegando depois | `superseded`, e nada muda |
| Edição mais recente chegando depois | prevalece, e os filhos são substituídos |
| Mesmo dia com UUID diferente | adota o identificador do servidor |
| Alteração sem gêneros | recusada, e a refeição já inserida não fica |
| Mapa bloqueado | recusado |
| Direção tentando registrar | recusada |
| Sem sessão | recusado |
| Merendeira de outra escola | grava na escola dela, no catálogo dela |
| Gênero de outra escola pelo identificador | nasce um novo, sem colidir |
| Nome variando caixa e espaços | adota o existente, mantendo a unidade |
| Gênero novo sem unidade | recusado |
| Quantidade zero, fracionada e ausente | recusadas, dizendo qual gênero |
| Dia não letivo sem observação, ou com refeição | recusado |
| Dia não letivo com observação | gravado, descartando o número de refeições |
| Dia não letivo voltando a letivo | a observação sai na mesma operação |
| Dia letivo com observação enviada por engano | descartada |
| Refeição desconhecida, data ausente | recusadas |
| Relógio adiantado no aparelho | reduzido ao instante da chegada |
| Reabertura pela direção | não move o carimbo da última edição |
| Peças internas | fora do schema exposto; 404 na API |
| Escolas | nenhum registro atravessou |
