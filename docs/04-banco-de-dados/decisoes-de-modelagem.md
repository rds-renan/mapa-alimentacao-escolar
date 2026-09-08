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

## 6. A refeição é uma linha de texto livre, transcrita do cardápio

**Decisão**: `Refeicao.descricao` é texto livre — a linha que a merendeira transcreve do cardápio previsto ("Arroz, feijão, frango desfiado e salada"). Não há entidade "item do cardápio" nem "prato", e a linha não é reescrita quando houve troca (ver [decisão 7](#7-a-alteração-registra-o-que-entrou-não-o-que-saiu)).

**Por quê**: o cardápio oficial é documento externo no MVP e o mapa é uma transcrição dele (US001, US019); o documento oficial imprime exatamente essa linha por refeição. Estruturar itens obrigaria a merendeira a decompor cada refeição em partes, o oposto do registro em menos de 2 minutos (RNF#1 da US001). O custo cai sobre o painel: "as merendas mais bem aceitas" (CA#3 da US017) agrupam pela descrição normalizada (minúsculas, sem espaços repetidos), então "Arroz com frango" e "arroz c/ frango" contam separado. É limitação aceita para o MVP; a ingestão do cardápio (US019) é o lugar natural para estruturar isso depois.

**Histórias**: US001, US002, US017, US019.

## 7. A alteração registra o que entrou, não o que saiu

**Decisão**: a refeição guarda o **cardápio previsto** e permanece fiel a ele mesmo quando algo foi trocado — a descrição e a aceitação não mudam. Quando houve troca, nasce uma `AlteracaoCardapio`, no máximo uma por refeição, com dois conteúdos: os **gêneros e quantidades usados na troca** e uma **justificativa em texto livre**. Não existe campo para o item substituído.

**Por quê**: porque é o que o formulário oficial pede, e a US002 dizia o contrário. Ela afirmava que a alteração tem três campos — item previsto, item servido e justificativa — e que esse formato "replica o que elas já escrevem à mão no mapa". A conferência do documento durante a modelagem mostrou que não replica: o formulário tem uma coluna chamada *"em caso de alterações no cardápio, descreva os gêneros utilizados e as quantidades abaixo"* e, sob as três refeições, uma linha *"Mudança no cardápio, justificativa:"*. Em nenhum lugar ele pergunta o que saiu.

A permanência da descrição não é detalhe de implementação, é o que dá sentido ao registro: se a refeição já fosse reescrita com o que foi servido, não haveria divergência aparente e a justificativa não teria o que justificar. O documento mostra o previsto de um lado e os gêneros da troca do outro; a diferença entre os dois é a alteração.

Registrar o item substituído seria defensável em auditoria, mas seria trabalho que o documento não usa e que ninguém pediu — e a missão do MAE é simplificar o que elas já fazem, não acrescentar campos. A correção da US002 e das telas está na issue #47.

**Por que duas listas de gênero e não uma**: `GeneroUtilizado` e `GeneroDaAlteracao` têm a mesma forma, mas alimentam **colunas diferentes** do documento oficial — os gêneros da refeição e os gêneros da troca. Unificá-las numa tabela só, com uma marca dizendo a qual coluna a linha pertence, tornaria anulável justamente a coluna que carrega a distinção e complicaria a unicidade sem ganhar nada. Separadas, o modelo se parece com o documento que produz.

**Uma alteração por refeição, e não várias**: como a justificativa é texto livre e cobre a modificação inteira, e os gêneros são uma lista, duas trocas na mesma refeição são um registro só — mais itens na lista, e o texto cobre as duas. Isso encerra o botão "Outra alteração" da decisão 8 da E3.

**Granularidade**: os gêneros são capturados **por refeição**, embora o formulário os peça por dia numa célula única. As merendeiras sabem de cabeça o que foi de cada refeição, e um modelo mais fino sempre produz um documento mais grosso — a geração junta as três refeições numa célula, e as justificativas do dia numa linha. O contrário seria impossível.

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

**Decisão**: `DocumentoGerado` é gravado quando a merendeira pede a geração e nunca é apagado. Guarda quem pediu, quando, o modelo usado, a situação (em processamento, disponível ou falhou), o caminho do arquivo e a data em que ele sai do ar. Os mapas incluídos ficam numa associação muitos-para-muitos; período e quantidade de mapas derivam dela. O arquivo vive num *bucket* privado e é removido ao expirar; o registro passa a mostrar "fora do ar". Só o servidor escreve nessa tabela.

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

## 13. O domínio fala português; o schema fala inglês

**Decisão**: o vocabulário do domínio — histórias, telas, [diagrama de classes](diagrama-de-classes.md) e [modelo conceitual](modelo-conceitual.md) — é o português das entrevistas: mapa, refeição, gênero, alteração do cardápio. A partir do [modelo ER](modelo-er.md), os identificadores de tabela, coluna e tipo são em inglês, no singular (`meal_map`, `meal`, `food_item`, `menu_change`). O **conteúdo** continua em português: nomes de gêneros, descrições das refeições, observações, justificativas e toda a interface. Valor de enumeração é estrutura, não conteúdo — vai para o inglês (`morning_snack`, `lunch`, `afternoon_snack`), e a interface o traduz na exibição. O [glossário](modelo-er.md#glossário-domínio--banco) no fim do modelo ER liga os dois vocabulários.

**Por quê**: o schema não é lido apenas por quem lê a documentação — ele entra no código. O Supabase gera os tipos TypeScript a partir das tabelas, então cada nome escolhido aqui aparece nos componentes da web (E5) e do aplicativo (E6), ao lado de palavras que são inglês por construção. Um modelo em português produziria linhas como `supabase.from('refeicao').select()` dentro de um `onChange`, alternando idioma a cada expressão. Há ainda um detalhe que o português esconde: identificadores não levam acento nem cedilha, então `refeicao`, `alteracao_cardapio` e `genero` não são a palavra correta em idioma nenhum — enquanto `meal` e `menu_change` são.

O que se perde é o rastreio num vocabulário só, e é uma perda real: a força desta documentação é que "mapa" significa a mesma coisa da entrevista à tabela. O preço se paga com o glossário — uma tabela que já existia como rastreio classe → tabela e que agora também traduz. A fronteira fica num lugar só, e num lugar que a própria faculdade pede: modelo conceitual é artefato de domínio, modelo lógico é artefato de implementação.

Três nomes mereceram cuidado. **`meal_map`** guarda a identidade do artefato institucional: o mapa é o documento que dá nome ao MAE, e um `daily_record` qualquer apagaria isso. **`profile`** segue a convenção do próprio Supabase, e `user` é palavra reservada no PostgreSQL. **`food_item`** traduz "gênero alimentício" sem sugerir receita, como `ingredient` sugeriria.

**Consequência para a E5 e a E6**: a mesma fronteira vale no código — identificadores em inglês, textos de interface em português, sem exceção no meio.
