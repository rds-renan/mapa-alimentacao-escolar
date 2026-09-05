# Decisões de modelagem — E4

> Etapa E4 do projeto (refs #44). O porquê de cada escolha do modelo de dados que não é óbvia lendo o [diagrama de classes](diagrama-de-classes.md), para que o desenvolvimento (E5/E6) não precise reconstruir o raciocínio. Cada decisão referencia as histórias afetadas. Faz o mesmo papel que as [decisões de design](../03-ux/decisoes-de-design.md) fizeram na E3.

## 1. A escola é uma entidade, mesmo com uma só

**Decisão**: existe a classe `Escola`, raiz de usuários, catálogo, mapas, modelos e documentos. No MVP há uma única linha.

**Por quê**: as histórias falam em "os mapas da escola" (RN#2 da US016) e o cabeçalho do documento oficial leva nome e município (US015). Ter a escola como entidade custa uma coluna nas tabelas-raiz e dá ao banco um critério limpo para separar o que cada perfil vê. O contrário — fixar a escola em configuração — economizaria pouco hoje e obrigaria a remodelar se o app um dia atender outra escola.

**Histórias**: US015, US016.

## 2. Credenciais no serviço de autenticação; o domínio guarda só o papel

**Decisão**: `Usuario` é uma extensão da conta de autenticação do Supabase (mesmo identificador), com nome, papel, situação e escola. Senha, sessão e e-mail de login ficam no serviço de autenticação, com o autocadastro desativado. Desativar um acesso é marcar `ativo = falso` e bloquear a conta no serviço — nunca apagar a linha.

**Por quê**: o autocadastro fechado é regra da US016 (CA#3), e o Supabase já resolve credencial e sessão persistente (RNF#2 da US016). Apagar um usuário quebraria a autoria dos mapas, documentos e desbloqueios que ele deixou (CA#2 da US016), e a autoria é parte da auditoria do sistema.

**Histórias**: US016, US023.

## 3. Um mapa por data; letivo ou não letivo é estado do mesmo objeto

**Decisão**: `Mapa` tem no máximo uma instância por data em cada escola, e o atributo `naoLetivo` decide a natureza do dia. Dia não letivo exige observação; dia letivo exige, para ficar completo, o número de refeições e as três refeições. As refeições de um dia marcado como não letivo **não são apagadas** — ficam ignoradas pelo documento e pelo painel enquanto a marcação durar.

**Por quê**: a RN#1 da US006 diz que um dia é uma coisa ou outra, nunca as duas; um único objeto com uma chave por data é a forma mais direta de garantir isso. Preservar as refeições ao marcar não letivo é o que permite "desfazer a marcação e registrar o dia normalmente" (CA#3 da US006) sem perder o que já estava digitado — coerente com o contrato "nada foi perdido" da E3. O painel exclui dias não letivos pelo atributo, não pela ausência de refeições (RN#2 da US017).

**Histórias**: US001, US005, US006, US017.

## 4. Os estados do dia são derivados — só o bloqueio é armazenado

**Decisão**: `vazio`, `pendente` e `completo` são calculados a partir do conteúdo do mapa; `nao_letivo` é o atributo da decisão 3; `no_documento` é o atributo `bloqueado`, gravado.

**Por quê**: com salvamento automático a cada campo (US010), um estado "completo" gravado ficaria desatualizado a cada toque, e cada cliente teria de recalculá-lo e regravá-lo — fonte clássica de inconsistência entre aparelhos. Derivar é mais barato e nunca mente. O bloqueio é a exceção porque quem o muda não é quem edita o mapa: é o servidor, ao gerar o documento, ou o administrador, ao desbloquear. Um cliente offline precisa ler esse fato do registro, não deduzi-lo cruzando documentos e desbloqueios.

**Histórias**: US007, US008, US012, US023.

## 5. Bloqueio e desbloqueio: o servidor escreve, a merendeira só lê

**Decisão**: a geração do documento marca `bloqueado` nos mapas incluídos, na mesma transação em que registra o `DocumentoGerado`. O desbloqueio é uma operação do administrador que grava um `DesbloqueioMapa` (quem, quando, justificativa) e limpa o atributo. O banco rejeita qualquer alteração de um mapa bloqueado ou de suas refeições, alterações e gêneros utilizados feita por perfil de merendeira, e rejeita que ela escreva no atributo `bloqueado`. O histórico de desbloqueios é somente inserção: nada nele é editado ou apagado.

**Por quê**: a RN#1 da US007 é regra de auditoria, e regra de auditoria precisa valer no banco, não só na tela — um cliente desatualizado não pode sobrescrever um mapa que já saiu em documento. O desbloqueio precisa deixar rastro permanente (CA#3 e RNF#1 da US023) e não pode apagar o documento nem o registro de que ele foi gerado (RN#2 da US023); por isso ele é um registro próprio, e não um "desfazer" do bloqueio. O mapa "reaberto para correção" (CA#2 da US023) deriva daí: não bloqueado e com pelo menos um desbloqueio.

**Histórias**: US007, US012, US013, US023.

## 6. A refeição descreve o que foi servido em texto livre

**Decisão**: `Refeicao.descricao` é texto livre — a linha que a merendeira transcreve do cardápio ("Arroz, feijão, ovo cozido e salada"). Não há entidade "item do cardápio" nem "prato".

**Por quê**: o cardápio oficial é documento externo no MVP e o mapa é uma transcrição dele (US001, US019); o documento oficial imprime exatamente essa linha por refeição. Estruturar itens obrigaria a merendeira a decompor cada refeição em partes, o oposto do registro em menos de 2 minutos (RNF#1 da US001). O custo cai sobre o painel: "as merendas mais bem aceitas" (CA#3 da US017) agrupam pela descrição normalizada (minúsculas, sem espaços repetidos), então "Arroz com frango" e "arroz c/ frango" contam separado. É limitação aceita para o MVP; a ingestão do cardápio (US019) é o lugar natural para estruturar isso depois.

**Histórias**: US001, US002, US017, US019.

## 7. Alteração do cardápio é entidade própria, zero ou mais por refeição

**Decisão**: `AlteracaoCardapio` pertence a uma refeição e guarda item previsto, item servido e justificativa obrigatória. Uma refeição pode ter várias. Os motivos frequentes oferecidos na tela (falta de entrega do fornecedor, item impróprio, quantidade insuficiente) são sugestões da interface; o que se grava é o texto.

**Por quê**: a decisão 8 da E3 mostra a troca dentro do cartão da refeição e oferece "Outra alteração", então a cardinalidade é um-para-muitos por refeição, não um campo do mapa. A justificativa como `not null` é a RN#1 da US002 no banco. Manter os motivos como texto, e não como tabela, evita cadastro para uma lista que só existe para reduzir digitação (RNF#1 da US002) — e o documento oficial quer o texto, não um código.

No documento oficial, o espaço reservado às alterações recebe a troca e a justificativa; os gêneros e quantidades usados são os da própria refeição (decisão 8), sem um segundo registro de gêneros só para a alteração.

**Histórias**: US002, US003.

## 8. Catálogo da escola: unidade no gênero, quantidade inteira no uso

**Decisão**: `Genero` tem nome, unidade padrão e situação (ativo), único por nome normalizado dentro da escola. `GeneroUtilizado` liga refeição e gênero com quantidade inteira maior que zero, um gênero por refeição no máximo. A unidade é texto curto — a interface sugere as comuns (quilo, saco, pote, lata, litro, unidade), mas a lista não é fechada. Gênero em uso não pode ser excluído; só desativado.

**Por quê**: unidade no catálogo e quantidade inteira são a decisão 2 da E3 e a RN#1 da US003. A unidade como enumeração fixa contradiria a premissa da US009 — o catálogo é delas, sem depender de ninguém para incluir o que a cozinha usa. A unicidade por nome evita "Arroz" duas vezes quando as duas merendeiras cadastram o mesmo item; o que fazer quando isso acontece offline é assunto da decisão 9. Desativar em vez de excluir é o CA#3 da US009, e a chave estrangeira restritiva o garante.

**Histórias**: US003, US009.

## 9. O dia é a unidade de sincronização

**Decisão**: para o funcionamento offline, o mapa do dia inteiro — mapa, refeições, alterações e gêneros utilizados — é gravado como uma unidade, numa única operação atômica no servidor, que faz o *upsert* do mapa, substitui os filhos pelos enviados e cria no catálogo os gêneros que ainda não existirem. Todos os identificadores são UUID gerados no aparelho. O mapa guarda quando e por quem foi editado pela última vez.

**Por quê**: sincronizar linha a linha exigiria marcar exclusões (tombstones) em cada tabela-filha e resolver conflitos em quatro níveis; tratando o dia como unidade, o conflito só existe num lugar e a regra da US011 (prevalece a edição mais recente, e o caso é sinalizado) se aplica com a data da última edição. UUID no aparelho é o que permite criar o registro sem rede (RN#1 da US010) e enviá-lo depois sem renumerar. Criar o gênero na mesma operação é a consequência da decisão 7 da E3 no modelo: o gênero pode nascer junto com a refeição. Se o nome já existir na escola, a operação adota o gênero existente em vez de duplicar. O protocolo do cliente — fila local, retentativas, indicador de estado — é assunto da E5/E6, não do modelo.

**Histórias**: US009, US010, US011.

## 10. Documento gerado: registro permanente, arquivo temporário

**Decisão**: `DocumentoGerado` é gravado quando a merendeira pede a geração e nunca é apagado. Guarda quem pediu, quando, o modelo usado, a situação (`em_processamento`, `disponivel`, `falhou`), o caminho do arquivo e a data em que ele sai do ar. Os mapas incluídos ficam numa associação muitos-para-muitos; período e quantidade de mapas derivam dela. O arquivo vive num *bucket* privado e é removido ao expirar; o registro passa a mostrar "fora do ar". Só o servidor escreve nessa tabela.

**Por quê**: a lista de documentos gerados (US021, US022) precisa existir mesmo quando o arquivo já se foi — é ela que diz "os mapas desse período continuam guardados" —, e o desbloqueio não pode apagar o rastro da geração (RN#2 da US023). O arquivo expira porque o sistema não mantém cópia permanente (RN#2 da US012). A situação em três valores vem da decisão 10 da E3: a geração acontece no servidor e pode terminar depois, com a merendeira fora da tela. Derivar período e contagem evita gravar o que a associação já diz, e a seleção pode ser de dias avulsos — o "período" é só o primeiro e o último dia incluídos.

**Histórias**: US012, US013, US021, US022, US023.

## 11. O modelo oficial tem versões, e exatamente uma vigente

**Decisão**: cada envio do administrador cria um `ModeloDocumento`; um índice garante uma única versão vigente por escola. As anteriores ficam. O arquivo mora num *bucket* privado, acessível só ao administrador e ao servidor.

**Por quê**: "existe sempre exatamente um template vigente" (RN#1 da US015) é uma regra que o banco consegue garantir sozinho. Guardar as versões permite que cada documento gerado registre com qual modelo saiu — quando o formato muda por decisão externa (o caso citado na US015), dá para saber o que foi entregue antes e depois. O arquivo nunca entra no repositório nem fica público (RNF#1 da US012; regra de sigilo do projeto).

**Histórias**: US012, US015.

## 12. O que fica fora do banco, de propósito

- **Cardápio oficial** — referência externa; a ingestão é pós-MVP (US019) e mesmo lá o mapa não dependerá dela.
- **Preferências do aparelho** — o tema escuro é escolha de cada usuária, no aparelho dela (RN#1 da US024).
- **Credenciais, sessões e redefinição de senha** — do serviço de autenticação (decisão 2).
- **Tokens de notificação** — a única notificação do MVP ("documento pronto") exige guardar o identificador do aparelho; isso entra com o app Android, na E6, como migration própria, porque só lá existe aparelho para registrar.
- **Cópia permanente dos documentos** — o arquivo expira; o que fica é o registro (decisão 10).

## 13. Nomes em português, no singular

**Decisão**: classes, tabelas e colunas em português, no singular, sem acento nem cedilha nos identificadores (`refeicao`, `genero_utilizado`, `alteracao_cardapio`). A tabela de usuários chama-se `usuario`, e não `profiles`, apesar da convenção comum no Supabase.

**Por quê**: toda a documentação, as histórias e as telas usam esse vocabulário; o modelo é a continuação delas, e o documento da faculdade é lido em português. Um vocabulário só, da entrevista ao SQL, é o que mantém o rastreio história → classe → tabela legível.
