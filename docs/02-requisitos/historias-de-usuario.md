# Histórias de usuário — MAE (Mapa da Alimentação Escolar)

> Etapa E2 do projeto. As histórias seguem o template do PIT (ID, título, requerente, ação, comentários, critérios de aceitação, regras de negócio, requisitos não funcionais, prioridade A–E e pontos de história) e derivam diretamente da priorização feita no Design Thinking ([docs/01-design-thinking/design-thinking.md](../01-design-thinking/design-thinking.md)).
>
> **Requerentes:**
> - *Merendeira* — usuária principal. Todo o fluxo do mapa é dela: registro diário, catálogo de gêneros, geração e compartilhamento do documento.
> - *Administrador* — figura de direção/responsável superior. Não participa do fluxo diário do mapa: cuida apenas do que é gerencial (acessos, template oficial e dados da escola). Pode consultar os registros, mas nunca os cria.
> - *Equipe de projeto* — usado quando a história não veio do levantamento e sim do próprio desenho do sistema, sem que ninguém a tenha pedido. Nesses casos os comentários dizem de onde ela surgiu e a quem serve, para que o documento não ponha na boca das usuárias um pedido que elas não fizeram.
>
> **Sobre o cardápio oficial:** o cardápio semanal enviado pelo setor de nutrição é a referência que o mapa deve seguir, mas no MVP permanece um documento externo — não é um objeto do sistema. A merendeira o transcreve diretamente para o mapa, no ritmo que preferir; não existe restrição de cadastrar cardápio para registrar o mapa. A ingestão do cardápio pelo app, pré-preenchendo os mapas, é evolução planejada para o pós-MVP (US019) — e mesmo lá o mapa nunca dependerá dela.
>
> **Escala de pontos:** Fibonacci (1, 2, 3, 5, 8, 13). **Prioridade:** A (essencial — sem isso o app não substitui o improviso atual) → E (desejável).

---

## Registro diário

### US001 — Registro ágil do mapa diário

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero registrar o mapa de qualquer dia de forma rápida e no momento que me for conveniente, para que o preenchimento caiba na minha rotina.
- **Comentários:** É o coração do app. O registro é um cadastro comum e flexível: a merendeira pode transcrever o cardápio da semana para os dias seguintes assim que ele chega e completar cada dia depois (quantidades, aceitação, número de refeições), ou registrar o dia inteiro de uma vez — em qualquer ordem. O dia cobre as três refeições da escola integral: lanche da manhã, almoço e lanche da tarde. O cardápio traz apenas a refeição de cada período; os gêneros usados, embora elas saibam e normalmente preencham, não são obrigatórios.
- **Critérios de aceitação:**
  - CA#1 Qualquer dia do mês pode ser aberto e registrado, em qualquer ordem, sem depender de outros dias nem de qualquer cadastro prévio.
  - CA#2 O registro de cada refeição descreve o que foi servido; informar os gêneros usados (do catálogo — US009) e suas quantidades é opcional.
  - CA#3 Um registro pode ser salvo incompleto e concluído depois; o dia aparece como pendente até estar completo.
- **Regras de negócio:**
  - RN#1 Cada dia letivo tem exatamente três refeições: lanche da manhã, almoço e lanche da tarde.
  - RN#2 O cardápio oficial é a referência do que servir; o mapa documenta o que foi de fato executado.
  - RN#3 Gêneros usados e quantidades nunca são obrigatórios para concluir o registro de uma refeição.
- **Requisitos não funcionais:**
  - RNF#1 O registro de um dia comum deve ser concluído em menos de 2 minutos.
- **Prioridade:** A — **Pontos de história:** 5

### US002 — Alteração de cardápio com justificativa

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero registrar as trocas em relação ao cardápio oficial — item previsto, item servido no lugar e o motivo — para que o mapa documente a alteração no mesmo formato exigido hoje.
- **Comentários:** Trocas acontecem por falha de fornecedor, falta de gênero etc. Como o cardápio é documento externo, é a merendeira quem aponta a alteração; o formato replica o que elas já escrevem à mão no mapa: item previsto, substituto e justificativa.
- **Critérios de aceitação:**
  - CA#1 O registro de alteração tem três campos: item previsto no cardápio, item servido e justificativa.
  - CA#2 Não é possível concluir uma alteração sem justificativa.
  - CA#3 A alteração aparece destacada na revisão do dia e no documento gerado.
- **Regras de negócio:**
  - RN#1 Toda divergência em relação ao cardápio oficial exige justificativa.
- **Requisitos não funcionais:**
  - RNF#1 A justificativa aceita texto livre curto, com sugestões de motivos frequentes para reduzir digitação.
- **Prioridade:** A — **Pontos de história:** 3

### US003 — Quantidades em unidades inteiras padronizadas

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero informar as quantidades dos gêneros usados escolhendo números inteiros na unidade padrão de cada item, para não digitar texto livre nem errar formato.
- **Comentários:** Achado direto da entrevista: as medidas são sempre inteiras e padronizadas por item (1 kg de arroz, 1 pote de manteiga, 1 saco de leite em pó) — nunca frações. A unidade padrão de cada gênero vem do catálogo (US009). Informar gêneros é opcional (RN#3 da US001); quando informados, valem as regras abaixo. O widget definitivo (stepper +/− ou teclado numérico) será definido na etapa de UX (E3).
- **Critérios de aceitação:**
  - CA#1 Cada gênero exibe sua unidade padrão ao lado do campo de quantidade.
  - CA#2 O campo aceita apenas números inteiros positivos; frações e texto são impossíveis de inserir.
  - CA#3 A quantidade registrada aparece no documento no formato "N unidade" (ex.: "2 kg").
- **Regras de negócio:**
  - RN#1 Quantidades são sempre inteiras, na unidade padrão cadastrada para o gênero.
- **Requisitos não funcionais:**
  - RNF#1 Em campos numéricos, o teclado exibido é o numérico do Android.
- **Prioridade:** A — **Pontos de história:** 3

### US004 — Grau de aceitação em um toque

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero registrar o grau de aceitação de cada refeição tocando em um de três botões (ótimo, bom ou ruim), para avaliar a refeição sem digitar nada.
- **Comentários:** A avaliação é feita por observação de sobras, reação das crianças e repetições — conhecimento que elas já têm; o app só captura.
- **Critérios de aceitação:**
  - CA#1 Cada uma das três refeições do dia tem seu próprio registro de aceitação.
  - CA#2 A aceitação é escolhida entre exatamente três opções: ótimo, bom, ruim.
  - CA#3 Não é possível concluir o registro de uma refeição servida sem informar a aceitação.
- **Regras de negócio:**
  - RN#1 O grau de aceitação é por refeição, não por dia nem por item.
- **Requisitos não funcionais:**
  - RNF#1 A seleção é feita em um único toque, sem listas suspensas ou digitação.
- **Prioridade:** A — **Pontos de história:** 2

### US005 — Número de refeições único por dia

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero informar o número de refeições servidas no dia em um único campo, para refletir o processo real da escola integral.
- **Comentários:** Como todas as crianças permanecem o dia inteiro, o número é único por dia — informado pelas professoras à direção, que repassa às merendeiras.
- **Critérios de aceitação:**
  - CA#1 O registro do dia tem um único campo de número de refeições, aplicado às três refeições.
  - CA#2 O campo aceita apenas números inteiros positivos.
  - CA#3 O número informado aparece no documento gerado conforme o padrão oficial.
- **Regras de negócio:**
  - RN#1 O número de refeições é um valor único por dia letivo.
- **Requisitos não funcionais:**
  - RNF#1 O campo usa teclado numérico.
- **Prioridade:** A — **Pontos de história:** 1

### US006 — Registro de dia não letivo

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero marcar um dia como não letivo registrando apenas uma observação, para documentar o dia sem preencher refeições.
- **Comentários:** Ex.: conselho de classe, feriado, recesso. No mapa oficial esses dias aparecem só com a observação.
- **Critérios de aceitação:**
  - CA#1 Ao marcar o dia como não letivo, os campos de refeições são dispensados e só a observação é solicitada.
  - CA#2 A observação é obrigatória para concluir o registro de dia não letivo.
  - CA#3 É possível desfazer a marcação e registrar o dia normalmente.
- **Regras de negócio:**
  - RN#1 Um dia é letivo (três refeições) ou não letivo (apenas observação) — nunca os dois.
- **Requisitos não funcionais:**
  - RNF#1 A marcação de dia não letivo é acessível na mesma tela do registro diário.
- **Prioridade:** A — **Pontos de história:** 2

### US007 — Edição livre até a geração do documento

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero editar o registro de qualquer dia enquanto o documento oficial daquele período não foi gerado, para entregar o mapa sem erros.
- **Comentários:** "O mapa não pode conter erro" — a responsabilidade pelo documento correto é delas, e só entregam quando está certo. A edição livre é o que permite o fluxo flexível da US001 (adiantar dias transcrevendo o cardápio e completar depois). Uma correção excepcional após a geração seria papel do administrador (direção), mediante justificativa e regeração do documento — possibilidade registrada aqui como contexto, fora do escopo destas histórias.
- **Critérios de aceitação:**
  - CA#1 Qualquer dia não bloqueado pode ser reaberto e editado, passando pelas mesmas validações do registro original.
  - CA#2 Um dia incluído em documento já gerado aparece como bloqueado e não pode ser editado.
  - CA#3 A edição feita offline é preservada e sincronizada como qualquer registro.
- **Regras de negócio:**
  - RN#1 Registro que participou de documento gerado não pode mais ser editado pela merendeira (segurança e auditoria).
- **Requisitos não funcionais:**
  - RNF#1 A edição reutiliza a mesma interface do registro, sem fluxo separado a aprender.
- **Prioridade:** A — **Pontos de história:** 3

### US008 — Visão do mês com status de preenchimento

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero ver os dias do mês com a indicação de quais já foram registrados, para saber o que falta antes de gerar o mapa.
- **Comentários:** Hoje o controle do que falta é de cabeça/caderno. A visão do mês também é a porta de entrada para registrar ou editar um dia — essencial no fluxo flexível, em que dias podem ficar parcialmente preenchidos.
- **Critérios de aceitação:**
  - CA#1 O app exibe os dias do mês com status visual: completo, pendente, não letivo ou bloqueado (já em documento gerado).
  - CA#2 Tocar em um dia abre seu registro (novo ou para edição).
  - CA#3 A visão funciona offline com os dados locais.
- **Regras de negócio:**
  - RN#1 Fins de semana não contam como pendência.
- **Requisitos não funcionais:**
  - RNF#1 O status de cada dia é identificável por cor e ícone (não só cor).
- **Prioridade:** B — **Pontos de história:** 3

### US009 — Catálogo de gêneros alimentícios com unidade padrão

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero manter o catálogo de gêneros alimentícios com a unidade padrão de cada um, para que as quantidades registradas sejam sempre consistentes.
- **Comentários:** Base da US003: cada item tem sua unidade fixa (arroz em kg, manteiga em pote, leite em pó em saco). Quem conhece os itens é quem cozinha — por isso o catálogo é delas, sem depender de ninguém para incluir um gênero novo no meio do registro.
- **Critérios de aceitação:**
  - CA#1 Cada gênero tem nome e unidade padrão obrigatórios.
  - CA#2 Um gênero novo pode ser adicionado durante o registro do dia, sem sair do fluxo.
  - CA#3 Um gênero usado em registros não pode ser excluído (apenas desativado); desativados permanecem nos registros antigos.
- **Regras de negócio:**
  - RN#1 Um gênero tem exatamente uma unidade padrão.
- **Requisitos não funcionais:**
  - RNF#1 Busca por nome no catálogo durante o registro.
- **Prioridade:** A — **Pontos de história:** 3

### US020 — Menu do aplicativo

- **Requerente:** Equipe de projeto
- **Ação:** Como merendeira, quero um menu com o que não faz parte do registro do dia — documentos gerados, catálogo de gêneros e as preferências do aplicativo — para alcançar essas telas sem que elas ocupem espaço no caminho que percorro todos os dias.
- **Comentários:** Requisito de design surgido na E3, sem origem no levantamento. Ao tirar o catálogo de gêneros do caminho do registro — o gênero passou a ser buscado e cadastrado numa folha sobre a tela do dia, sem sair dela —, o catálogo ficou sem porta de entrada. O menu resolve isso e passa a ser o lugar das telas ocasionais, que não têm por que disputar espaço com o registro.
- **Critérios de aceitação:**
  - CA#1 O menu é alcançado a partir da visão do mês e não interrompe registro em andamento.
  - CA#2 Reúne documentos gerados, catálogo de gêneros, preferências do aplicativo e sair.
  - CA#3 O menu abre offline; cada tela alcançada por ele trata a falta de rede por conta própria.
- **Regras de negócio:**
  - RN#1 O menu não dá acesso a nada da área do administrador.
- **Requisitos não funcionais:**
  - RNF#1 O menu é alcançável em um toque a partir da tela inicial do aplicativo.
- **Prioridade:** A — **Pontos de história:** 2

### US024 — Tema escuro

- **Requerente:** Equipe de projeto
- **Ação:** Como merendeira, quero usar o aplicativo em tema escuro, para preencher o mapa à noite em casa sem a tela clara incomodando.
- **Comentários:** Pedido do autor do projeto, com justificativa de uso: o preenchimento acontece em casa e com frequência à noite (E1). Entra no MVP também por economia de trabalho — a paleta escura definida junto com os tokens de design custa pouco agora, enquanto acrescentá-la depois obrigaria a revisar cada tela já implementada nas duas plataformas.
- **Critérios de aceitação:**
  - CA#1 O tema é escolhido nas preferências, dentro do menu (US020), e a escolha permanece entre sessões.
  - CA#2 Todas as telas do fluxo da merendeira existem nos dois temas.
  - CA#3 O contraste de texto e dos estados atende AA nos dois temas.
- **Regras de negócio:**
  - RN#1 A escolha é de cada usuária, no aparelho dela — não é configuração da escola.
- **Requisitos não funcionais:**
  - RNF#1 A paleta escura é definida no mesmo conjunto de tokens compartilhado entre a web e o aplicativo.
- **Prioridade:** A — **Pontos de história:** 3

## Confiabilidade offline

### US010 — Funcionamento 100% offline com salvamento automático

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero preencher o mapa inteiro sem internet e ter cada alteração salva automaticamente, para nunca perder o que já digitei.
- **Comentários:** Responde à dor mais visceral da entrevista: o app improvisado fecha sozinho e apaga parte do preenchimento. A escola não tem sinal de operadora e o Wi-Fi é instável; o preenchimento é feito em casa. Offline-first é o requisito não funcional central do sistema.
- **Critérios de aceitação:**
  - CA#1 Todo o fluxo de registro e catálogo (US001–US009) funciona sem nenhuma conexão.
  - CA#2 Cada alteração é persistida no aparelho imediatamente, sem botão "salvar".
  - CA#3 Se o app for fechado (ou morto pelo sistema) no meio do preenchimento, ao reabrir tudo está como estava.
- **Regras de negócio:**
  - RN#1 Nenhuma funcionalidade de registro pode depender de rede para concluir.
- **Requisitos não funcionais:**
  - RNF#1 Persistência local a cada alteração de campo (autosave contínuo).
  - RNF#2 O app deixa claro, sem alarmar, que está operando offline e que os dados estão seguros no aparelho.
- **Prioridade:** A — **Pontos de história:** 13

### US011 — Sincronização automática quando houver rede

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero que os registros feitos offline subam sozinhos para o servidor quando houver conexão, para que o mapa fique disponível para a colega e para a geração do documento.
- **Comentários:** As duas merendeiras revezam a responsabilidade do mapa e ambas acessam todos os registros da escola — a sincronização é o que mantém as duas vendo a mesma coisa.
- **Critérios de aceitação:**
  - CA#1 Ao detectar conexão, o app envia os registros pendentes sem ação da usuária.
  - CA#2 O app indica o estado de sincronização (pendente / sincronizado).
  - CA#3 Registros do mesmo dia feitos em aparelhos diferentes convergem sem perda silenciosa: prevalece a edição mais recente e o caso é sinalizado.
- **Regras de negócio:**
  - RN#1 O dado local nunca é descartado antes de confirmado no servidor.
- **Requisitos não funcionais:**
  - RNF#1 A sincronização ocorre em segundo plano, sem bloquear o uso do app.
- **Prioridade:** A — **Pontos de história:** 8

## Documento oficial e envio

### US012 — Geração do documento oficial

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero gerar o mapa pronto no padrão oficial a partir dos registros do período, para não formatar nada manualmente.
- **Comentários:** O documento é gerado no servidor a partir do template oficial vigente (gerenciado pelo administrador — US015), preenchido com os dados do período. É o fim do posicionamento manual de blocos de texto sobre PDF. Valoriza a apresentação legível e padronizada do documento digitado.
- **Critérios de aceitação:**
  - CA#1 A merendeira escolhe o período e recebe o documento no mesmo formato do template oficial vigente.
  - CA#2 O documento reflete fielmente os registros: itens, alterações com justificativa, quantidades, aceitação, número de refeições e dias não letivos.
  - CA#3 Dias pendentes no período são apontados antes da geração.
  - CA#4 O documento é entregue por link temporário para download/compartilhamento.
- **Regras de negócio:**
  - RN#1 A geração usa sempre o template oficial vigente cadastrado pelo administrador.
  - RN#2 Link e arquivo gerados expiram em até 7 dias; o sistema não mantém cópia permanente do documento.
  - RN#3 A geração exige conexão (ocorre no servidor) e depende dos registros sincronizados.
  - RN#4 Os registros incluídos no documento gerado ficam bloqueados para edição (ver US007).
- **Requisitos não funcionais:**
  - RNF#1 O template oficial fica em armazenamento privado, inacessível publicamente.
  - RNF#2 A geração de um documento leva no máximo 30 segundos em conexão instável.
- **Prioridade:** A — **Pontos de história:** 13

### US013 — Seleção de mapas para um documento único

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero selecionar quais mapas entram no documento — dias avulsos, uma semana ou o mês inteiro — e gerar um único documento com todos eles, para resolver a prestação de contas mensal em uma ação só.
- **Comentários:** Pedido espontâneo das entrevistadas. O documento não é preso ao formato de uma semana: a entrega real é mensal (a diretora leva os mapas em papel à secretaria de educação uma vez por mês), então o caso típico é selecionar o mês inteiro e gerar um documento só.
- **Critérios de aceitação:**
  - CA#1 A seleção de mapas aceita dias avulsos, semana ou mês, com atalhos para "semana" e "mês".
  - CA#2 A seleção gera um único documento contendo todos os mapas selecionados.
  - CA#3 O documento gerado segue o fluxo normal de compartilhamento (US014).
- **Regras de negócio:**
  - RN#1 As regras de geração da US012 (template vigente, link temporário, bloqueio dos registros incluídos) valem para o documento inteiro, qualquer que seja a seleção.
- **Requisitos não funcionais:**
  - RNF#1 Selecionar o mês inteiro leva poucos toques (sem marcar dia por dia).
- **Prioridade:** A — **Pontos de história:** 5

### US014 — Compartilhamento pelo WhatsApp

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero compartilhar o documento gerado direto no WhatsApp pela folha de compartilhamento do Android, para seguir o caminho institucional que já existe.
- **Comentários:** Estratégia de aceitação institucional: o app não altera nenhuma etapa do processo da prefeitura — o documento segue por WhatsApp para a secretaria, que imprime e coleta assinaturas em papel, como hoje. Muda apenas como o documento nasce.
- **Critérios de aceitação:**
  - CA#1 Após a geração, um toque abre a folha de compartilhamento do Android com o documento anexado.
  - CA#2 O documento compartilhado é idêntico ao gerado (mesmo arquivo, mesmo padrão).
  - CA#3 O compartilhamento funciona para o documento de qualquer seleção de mapas (US013).
- **Regras de negócio:**
  - RN#1 O app não envia o documento sozinho — o envio é sempre uma ação da merendeira, pelo aplicativo que ela escolher.
- **Requisitos não funcionais:**
  - RNF#1 Usa a folha de compartilhamento nativa do Android (sem integração direta com API do WhatsApp).
- **Prioridade:** A — **Pontos de história:** 2

### US021 — Documentos gerados acessíveis à merendeira

- **Requerente:** Equipe de projeto
- **Ação:** Como merendeira, quero voltar aos documentos que já gerei enquanto eles ainda existem, para compartilhar de novo sem depender de ter acertado o envio na primeira tentativa.
- **Comentários:** Requisito de design surgido na E3, a serviço da merendeira. A tela do documento gerado era um beco: ao sair dela, o arquivo ficava inalcançável até expirar. Três situações banais caem nisso — o aplicativo fechar durante a folha de compartilhamento do Android, o envio falhar, ou a geração terminar depois da sincronização, quando ela já não está na tela. Não se confunde com a US018: aqui o arquivo ainda existe; lá ele expirou e precisa ser gerado de novo.
- **Critérios de aceitação:**
  - CA#1 A lista mostra os documentos ainda dentro da janela de validade, com o período, quantos mapas contém, quando foi gerado e quando sai do ar.
  - CA#2 Um documento disponível pode ser compartilhado de novo pela folha de compartilhamento do Android (US014).
  - CA#3 Documentos fora da janela aparecem como indisponíveis, informando que os registros do período continuam guardados.
- **Regras de negócio:**
  - RN#1 A janela de validade é a da geração (US012): o arquivo expira em até 7 dias e não é guardado além disso.
  - RN#2 A lista não permite editar mapa nenhum — os registros incluídos continuam bloqueados (US007).
- **Requisitos não funcionais:**
  - RNF#1 A lista abre offline com o que já foi sincronizado; abrir ou compartilhar o arquivo exige rede.
- **Prioridade:** A — **Pontos de história:** 5

## Administração

O administrador é a figura de direção/responsável superior. Ele não participa do fluxo do mapa — nunca registra, e apenas consulta quando necessário. Seu papel é o gerencial que não faz sentido ficar na carga das merendeiras.

### US015 — Gestão do template oficial e dos dados da escola

- **Requerente:** Administrador
- **Ação:** Como administrador, quero gerenciar o template oficial do mapa e os dados institucionais da escola (como o nome que consta no documento), para que os documentos gerados sigam sempre o padrão vigente da prefeitura.
- **Comentários:** O formato do documento muda por decisão externa (como a troca recente de PDF por DOCX). Atualizar o template e os dados no sistema absorve essas mudanças sem alterar o fluxo das merendeiras.
- **Critérios de aceitação:**
  - CA#1 O administrador envia um novo template e este passa a ser o vigente para as próximas gerações.
  - CA#2 Os dados institucionais (ex.: nome da escola) são editáveis e refletidos no documento gerado.
  - CA#3 O template fica em armazenamento privado do sistema, nunca exposto publicamente; apenas o perfil administrador acessa essa função.
- **Regras de negócio:**
  - RN#1 Existe sempre exatamente um template vigente.
- **Requisitos não funcionais:**
  - RNF#1 Acesso protegido por autenticação e autorização por perfil.
- **Prioridade:** A — **Pontos de história:** 5

### US016 — Cadastro e gestão de merendeiras

- **Requerente:** Administrador
- **Ação:** Como administrador, quero cadastrar as merendeiras e gerenciar seus acessos, para que apenas pessoas autorizadas registrem o mapa da escola.
- **Comentários:** Não há autocadastro — o cadastro aberto fica desativado no sistema e o app oferece apenas login. O universo de usuárias é conhecido e pequeno; as contas nascem pelo administrador.
- **Critérios de aceitação:**
  - CA#1 O administrador cria o acesso de uma merendeira com credenciais iniciais.
  - CA#2 Um acesso pode ser desativado sem apagar os registros feitos por ele.
  - CA#3 Não existe fluxo de autocadastro no app — apenas login de contas criadas pelo administrador.
- **Regras de negócio:**
  - RN#1 Perfis: administrador (gerencial + consulta) e merendeira (todo o fluxo do mapa). O administrador não registra mapas.
  - RN#2 Todos os perfis da escola acessam os mapas dela para consulta.
- **Requisitos não funcionais:**
  - RNF#1 Autenticação obrigatória; dados protegidos por autorização por perfil no servidor.
  - RNF#2 A sessão persiste no aparelho — a merendeira não redigita senha no dia a dia (essencial para o uso offline).
- **Prioridade:** A — **Pontos de história:** 3

### US017 — Painel gerencial com histórico mensal

- **Requerente:** Administrador
- **Ação:** Como administrador, quero um painel com o histórico mensal da alimentação — aceitação das refeições, número de refeições servidas e as merendas mais bem aceitas — para acompanhar a escola sem entrar nos mapas.
- **Comentários:** É a funcionalidade de destaque do perfil administrador, coerente com seu papel: gerencial, fora do fluxo do mapa. Os dados já são capturados no registro diário (US004 e US005) — o painel apenas os agrega em gráficos simples, sem complexidade. Substitui os "relatórios simples" que a E1 havia deixado para o pós-MVP.
- **Critérios de aceitação:**
  - CA#1 O painel mostra, por mês, a distribuição de aceitação (ótimo/bom/ruim) por refeição.
  - CA#2 O painel mostra o total de refeições servidas no mês e a média por dia.
  - CA#3 O painel destaca as merendas mais bem aceitas do período (itens com melhor avaliação).
  - CA#4 É possível navegar entre os meses do histórico.
- **Regras de negócio:**
  - RN#1 O painel é leitura agregada — não altera registros.
  - RN#2 Dias não letivos ficam fora dos cálculos.
- **Requisitos não funcionais:**
  - RNF#1 Gráficos simples e legíveis em celular; o painel carrega em menos de 5 segundos para um mês de dados.
- **Prioridade:** B — **Pontos de história:** 5

### US023 — Desbloqueio de mapa para correção

- **Requerente:** Equipe de projeto
- **Ação:** Como administrador, quero desbloquear um mapa já incluído em documento gerado, registrando a justificativa, para que a merendeira corrija um erro descoberto depois e o documento seja gerado de novo.
- **Comentários:** Fecha o beco criado pela RN#1 da US007: descoberto um erro após a geração, hoje o sistema não oferece caminho nenhum. É prioridade A por um motivo específico — no preenchimento manual elas simplesmente refazem a folha, então um aplicativo que trave a correção seria pior que o improviso que veio substituir, e trava insolúvel não pode existir. As merendeiras confirmaram que alterar mapa pronto é raro, o que define a frequência da função e não a necessidade dela. O administrador não edita o mapa: ele reabre, e quem corrige é a merendeira — a regra de que o mapa é delas continua de pé.
- **Critérios de aceitação:**
  - CA#1 O administrador localiza um mapa bloqueado e o reabre informando uma justificativa, obrigatória.
  - CA#2 O mapa reaberto volta a ser editável pela merendeira, sinalizado como reaberto para correção.
  - CA#3 O sistema guarda quem desbloqueou, quando e a justificativa informada.
  - CA#4 Corrigido o mapa, o documento do período pode ser gerado de novo.
- **Regras de negócio:**
  - RN#1 O administrador nunca edita o mapa — apenas desbloqueia.
  - RN#2 O desbloqueio não apaga o documento já gerado nem o registro de que ele foi gerado.
- **Requisitos não funcionais:**
  - RNF#1 O histórico de desbloqueios é permanente, como os registros do mapa.
- **Prioridade:** A — **Pontos de história:** 5

## Pós-MVP

### US018 — Histórico consultável com reemissão

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero consultar os mapas de períodos passados e reemitir o documento de qualquer um deles, para nunca mais refazer um mapa extraviado.
- **Comentários:** O setor de nutrição já extraviou documentos entregues, forçando reimpressão. Como o sistema guarda os registros (não os arquivos), a reemissão gera o documento de novo sob as mesmas regras de expiração da US012.
- **Critérios de aceitação:**
  - CA#1 Registros de qualquer período passado podem ser consultados no app.
  - CA#2 A reemissão gera o documento do período novamente, no template vigente.
  - CA#3 A reemissão usa o mesmo fluxo de compartilhamento (US014).
- **Regras de negócio:**
  - RN#1 Os registros estruturados são permanentes; só os arquivos gerados expiram.
- **Requisitos não funcionais:**
  - RNF#1 A consulta do histórico recente funciona offline com os dados sincronizados no aparelho.
- **Prioridade:** C — **Pontos de história:** 5

### US019 — Ingestão do cardápio semanal com pré-preenchimento dos mapas

- **Requerente:** Merendeira
- **Ação:** Como merendeira, quero inserir o cardápio da semana no app e ter os mapas dos dias já preenchidos a partir dele, para apenas editar o que mudou em cada dia.
- **Comentários:** Evolução natural do fluxo de transcrição manual (US001): a ingestão — digitada ou, futuramente, importada do arquivo recebido pelo WhatsApp — faz o mesmo trabalho que a merendeira já faz, só que de uma vez. Fica fora do MVP por complexidade; o fluxo fecha sem ela, e a premissa se mantém mesmo no pós-MVP: o mapa nunca depende de cardápio para existir.
- **Critérios de aceitação:**
  - CA#1 O cardápio ingerido gera os registros dos dias da semana como pendentes, prontos para edição.
  - CA#2 Dias já registrados não são sobrescritos pela ingestão.
  - CA#3 O fluxo de registro sem cardápio continua funcionando exatamente igual.
- **Regras de negócio:**
  - RN#1 A ingestão do cardápio é sempre opcional — nenhuma funcionalidade passa a depender dela.
- **Requisitos não funcionais:**
  - RNF#1 A ingestão manual de uma semana completa leva menos de 10 minutos.
- **Prioridade:** D — **Pontos de história:** 8

### US022 — Documentos gerados acessíveis ao administrador

- **Requerente:** Equipe de projeto
- **Ação:** Como administrador, quero ver e baixar os documentos que já foram gerados, para acompanhar as entregas e ter como recuperar um arquivo quando o envio feito pela merendeira não chegar ao destino.
- **Comentários:** Revisão de escopo da E3, motivada por uma lacuna admitida do levantamento: a E1 ouviu as merendeiras, e a direção e a secretaria entraram no projeto como personagens, não como fontes. A direção trabalha em computador, e o acesso pelo painel é a alternativa quando o envio pelo aplicativo de mensagens falha. Não amplia o papel do administrador — ele continua sem ver mapas e sem gerar documentos: vê apenas os arquivos que já existem.
- **Critérios de aceitação:**
  - CA#1 A lista mostra os documentos existentes, com período, quantos mapas contém, quem gerou e quando sai do ar.
  - CA#2 Um documento disponível pode ser baixado.
  - CA#3 A tela não dá acesso aos mapas nem à geração de documentos.
- **Regras de negócio:**
  - RN#1 O administrador não gera nem regera documento: gerar é sempre ação da merendeira (US012).
  - RN#2 Vale a mesma janela de validade da US012 — expirado o arquivo, não há o que baixar.
- **Requisitos não funcionais:**
  - RNF#1 A tela é de leitura, em layout de desktop, dentro da área do administrador.
- **Prioridade:** C — **Pontos de história:** 3

---

**Resumo:** 24 histórias — 19 de prioridade A e 2 B (MVP), 2 C e 1 D (pós-MVP). As cinco últimas (US020–US024) entraram na revisão feita ao fim da E3, quando o desenho das telas revelou requisitos que o levantamento não tinha visto. O backlog priorizado e organizado por tema está em [backlog.md](backlog.md).
