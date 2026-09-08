# Projeto físico — MAE

> Etapa E4 do projeto (refs #42, #43). Último artefato da modelagem: o banco de verdade. Enquanto o [modelo ER](modelo-er.md) descreve tabelas e restrições, o projeto físico é o SQL que as cria, mais o que o modelo lógico não mostra e que é decisão de banco — as políticas de acesso por perfil, os gatilhos que sustentam as regras que nenhuma restrição alcança e os baldes privados de arquivo.
>
> O SQL vive em [`supabase/migrations/`](../../supabase/migrations/) e é a fonte da verdade; este documento o apresenta. Como subir o banco na sua máquina está no [README do supabase/](../../supabase/README.md).

## As migrations

| Arquivo | O que faz |
|---|---|
| `20260907120000_schema_inicial.sql` | Os quatro tipos enumerados, as doze tabelas, chaves, índices e restrições de coerência |
| `20260907120100_regras_e_auditoria.sql` | Funções de apoio, os gatilhos do bloqueio, a proteção da coluna `locked`, o carimbo de última edição e `unlock_meal_map()` |
| `20260907120200_rls.sql` | Row Level Security ligada nas doze tabelas, com as políticas por perfil |
| `20260907120300_storage.sql` | Os dois baldes privados e suas políticas |

Migration é imutável depois de aplicada: corrigir é escrever a próxima.

## O que o banco passou a garantir sozinho

O [modelo ER](modelo-er.md#o-que-o-banco-garante-e-o-que-fica-para-a-aplicação) prometeu uma divisão entre o que o banco garante e o que fica para a aplicação. Estas são as três regras que exigiram mais que uma restrição de coluna.

### Mapa bloqueado não aceita edição

A RN#1 da US007 vale no banco, não só na tela — um cliente desatualizado não pode sobrescrever um mapa que já saiu em documento oficial. Um gatilho em `meal_map` e em tudo que pende dele (`meal`, `meal_food_item`, `menu_change`, `menu_change_food_item`) recusa a escrita quando o mapa está bloqueado. Cada tabela informa ao gatilho como chegar até o mapa, e a linha é lida como `jsonb` porque `NEW` não existe em `DELETE` e `OLD` não existe em `INSERT`.

A mensagem devolvida já é a que a pessoa pode ler: *"Este mapa já está em um documento gerado e não pode ser alterado"*, com a dica de que a direção pode reabri-lo.

**Um detalhe que custou uma reescrita**: os gatilhos são `security invoker` de propósito. Escritos como `security definer`, `current_user` seria sempre o dono das funções e o guarda nunca dispararia — foi o primeiro jeito que escrevi, e ele deixava passar tudo.

### A merendeira não escreve na coluna `locked`

RLS controla linhas, não colunas. Um segundo gatilho recusa qualquer `UPDATE` que mexa em `locked` fora do servidor: o bloqueio nasce na geração do documento e sai pela reabertura. Sem ele, a política de update do mapa — que a merendeira precisa ter — daria a ela a chave da própria cadeia.

### A reabertura e o seu registro são a mesma operação

`unlock_meal_map(map_id, reason)` exige perfil de direção, exige justificativa não vazia, grava a linha em `meal_map_unlock` e desbloqueia o mapa — tudo numa transação. Não existe caminho que reabra um mapa sem deixar o registro de quem, quando e por quê (CA#3 da US023). É `security definer`, e é por isso que ela atravessa o gatilho do bloqueio: é a exceção prevista, não um furo.

O histórico é somente inserção: `meal_map_unlock` não tem política de `insert`, `update` nem `delete` para ninguém.

## Quem pode o quê

| Tabela | Merendeira | Direção | Servidor |
|---|---|---|---|
| `school` | lê | lê e edita | — |
| `profile` | lê a escola, edita o próprio | lê, cria e desativa | — |
| `food_item` | lê, cria e edita | lê | — |
| `meal_map` | lê e escreve (se não bloqueado) | lê; reabre pela função | bloqueia na geração |
| `meal`, `meal_food_item`, `menu_change`, `menu_change_food_item` | lê e escreve (se o mapa não estiver bloqueado) | lê | — |
| `document_template` | lê | lê e substitui | lê na geração |
| `generated_document`, `document_meal_map` | lê | lê | escreve |
| `meal_map_unlock` | lê | lê | — |

Duas ausências são deliberadas. **A direção não registra mapa** (RN#1 da US016): não há política de `insert` de `meal_map` para o perfil `admin`, e a tentativa é recusada pelo próprio banco. **A merendeira não cria documento gerado** (RN#1 da US022): quem escreve essa tabela é a edge function da geração.

Gênero em uso tem duas defesas: a merendeira não tem política de `delete` — a linha simplesmente não existe para o comando, e ele apaga zero linhas —, e a chave estrangeira restritiva barra quem tiver privilégio para tentar. O caminho é desativar (CA#3 da US009).

## Os baldes de arquivo

Dois, ambos **privados** — o modelo oficial traz o brasão da prefeitura e não pode ficar exposto (RNF#1 da US012, e a regra de sigilo do projeto):

- `document-templates` — leitura e escrita só para a direção; o servidor o lê na geração.
- `generated-documents` — leitura para os dois perfis da escola, e só enquanto o documento estiver disponível e dentro da janela de 7 dias. A política consulta `generated_document` para decidir: expirou, o arquivo deixa de ser legível mesmo que ainda esteja no balde.

## Verificação

As migrations foram aplicadas do zero num Supabase local e as regras exercitadas uma a uma, com o papel `authenticated` e o token de cada perfil. O que foi verificado:

| Cenário | Resultado |
|---|---|
| Merendeira edita mapa livre | permitido |
| Merendeira edita mapa bloqueado | recusado pelo gatilho |
| Merendeira edita refeição de mapa bloqueado | recusado pelo gatilho |
| Merendeira tenta desbloquear ou bloquear um mapa | recusado pelo gatilho de coluna |
| Direção tenta registrar mapa | recusado pela política |
| Direção reabre com justificativa | permitido, com o desbloqueio registrado |
| Merendeira tenta reabrir | recusado |
| Reabertura sem justificativa | recusada |
| Merendeira corrige o mapa reaberto | permitido |
| Reabertura não altera "última edição por" | confirmado |
| Gênero repetido variando caixa e espaços | recusado pelo índice único |
| Segunda alteração na mesma refeição | recusada pelo índice único |
| Dia não letivo com número de refeições | recusado pela restrição de coerência |
| Quantidade zero | recusada |
| Apagar gênero em uso | zero linhas para a merendeira; chave estrangeira barra o resto |
| Segunda versão vigente do modelo | recusada pelo índice parcial |
| Perfil de outra escola consultando mapas e gêneros | zero linhas |
| Merendeira tenta criar documento gerado | recusado pela política |
| Baldes do Storage | os dois privados |
| Estados do dia derivados da leitura | completo, pendente, não letivo e no documento, um de cada |

## Dados de desenvolvimento

`supabase/seed.sql` traz uma escola, três acessos, oito gêneros e quatro dias — um de cada estado. **Tudo fictício**: nome de escola, município, pessoas e e-mails, com as merendeiras anonimizadas como na documentação pública. Nenhum dado real, credencial ou documento oficial entra no repositório.

## O que ainda não está aqui

- **A gravação do dia como unidade atômica** ([decisão 9](decisoes-de-modelagem.md)) — a operação única que faz o *upsert* do mapa, substitui os filhos e cria o gênero que ainda não existir. Ela entra na E5, junto com o cliente que a chama, e não aqui: migration é imutável, então escrevê-la antes custaria uma para criá-la e outra para corrigi-la assim que a lógica que a usa existisse. Pior que o retrabalho seria o efeito colateral — um contrato que nasce antes de quem o consome passa a parecer imutável, e a aplicação acaba se moldando a regras que ninguém decidiu.
- **A geração do documento** — edge function que lê o modelo vigente, monta o arquivo, grava `generated_document` e bloqueia os mapas incluídos. É a US012, da E5.
- **A expiração dos arquivos** — a rotina que apaga o que passou dos 7 dias e deixa o registro como "fora do ar".
