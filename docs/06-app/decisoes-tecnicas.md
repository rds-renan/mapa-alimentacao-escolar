# Decisões técnicas — E6 (aplicativo)

> Etapa E6 do projeto (refs #98). A stack do aplicativo Android e os recortes combinados ao abrir a etapa, decididos antes da primeira linha de código porque condicionam todas as issues da etapa. Faz o mesmo papel que as [decisões técnicas da E5](../05-web/decisoes-tecnicas.md) fizeram para a web, e alimenta a tabela de codificação exigida na entrega final ao lado delas.
>
> O aplicativo não é uma segunda web. Ele existe para a metade do produto que a web deixou para ele de propósito — o registro inteiro sem conexão (decisão 2 da E5) e a folha de compartilhamento do Android (decisão 9 da E5) —, contra o **mesmo banco e o mesmo contrato**. Onde uma decisão da E5 continua valendo, este documento aponta para ela em vez de repeti-la.

## 1. O aplicativo é da merendeira; a web é da direção e o plano B

**Decisão**: o aplicativo tem um único perfil, o da merendeira, e cobre o fluxo dela inteiro — registro do dia, visão do mês, catálogo de gêneros, geração e compartilhamento do documento. Conta de direção que tentar entrar é recusada com um aviso apontando para a web. A web continua fazendo tudo o que faz hoje, para os dois perfis, e é o caminho de quem ficar sem celular ou sem o aplicativo instalado.

**Por quê**: os dois fluxos já eram separados por regra (RN#1 da US020: o menu não dá acesso a nada da área do administrador), e a direção está fora do fluxo diário — o papel dela é gerencial, e a administração de acessos, o modelo oficial e o painel não ganham nada em ser reescritos em outra tecnologia. Trazer a direção para o aplicativo dobraria as telas da etapa para servir a quem já está bem servido. A web como plano B é o que permite que o aplicativo seja só Android sem deixar ninguém de fora: a merendeira que trocar de aparelho, perder o celular ou não conseguir instalar continua registrando pelo navegador, e o dia que ela registrar lá é o mesmo dia, no mesmo banco.

**Histórias**: US016, US020.

## 2. Flutter, só Android, falando direto com o Supabase

**Decisão**: o aplicativo é Flutter, em Dart, e vive em `app/`, no monorepo. Compila apenas para Android. Como a web, não tem servidor próprio: fala direto com o Supabase pelo cliente oficial, `supabase_flutter`, sob as mesmas políticas de RLS, e grava o dia pela mesma `save_meal_map` — o contrato está na [gravação do dia](../05-web/gravacao-do-dia.md), e o aplicativo não ganha uma variante dele.

**Por quê**: o Flutter está decidido desde o [plano de projeto](../planodeprojeto.md). Restringir a Android não é recorte de esforço, é o público: as merendeiras usam Android, e iOS traria conta de desenvolvedor, assinatura e distribuição próprias sem ninguém para usar. Usar o mesmo contrato de gravação é o que a decisão 3 da E5 prometeu ao escolher o dia como unidade: as duas plataformas não inventam protocolos diferentes contra o mesmo banco, e a convergência (decisão 5 da E5) continua sendo decidida num lugar só, no servidor.

**O que não atravessa, e o que protege o lugar dele**: a decisão 8 da E5 gera os tipos TypeScript a partir das migrations e a CI reprova quando eles envelhecem. A CLI do Supabase não gera tipos em Dart, então no aplicativo os modelos que conversam com o servidor são escritos à mão, seguindo o contrato da `save_meal_map`. O risco é o mesmo que a E5 descreveu — um modelo que mente sobre o banco —, e quem o contém é a trava de versão mínima (decisão 12): quando o schema mudar de um jeito que o aplicativo antigo não entende, o banco recusa o aplicativo antigo em vez de aceitar o que ele manda.

**Histórias**: transversal; US010, US011.

## 3. Material 3, com os tokens da E3 mandando

**Decisão**: a interface usa os componentes Material 3 do próprio Flutter, sem biblioteca de componentes de terceiros. Os tokens da [decisão 6 da E3](../03-ux/decisoes-de-design.md) — acento `#397ba1`, paleta, escala tipográfica, espaçamento, raios e alvo de toque mínimo de 44 px — viram `ThemeData`, em versão clara e escura, e o que o `ThemeData` não tem campo para guardar entra numa extensão de tema própria.

**Por quê**: a decisão 6 da E3 já dizia que o que atravessa as plataformas é o token, não o componente. Na web, o shadcn/ui cumpriu esse papel por entregar o componente como arquivo no projeto; no Flutter, o Material 3 cumpre o mesmo sem dependência nenhuma, e com uma vantagem que a web não tinha: é o comportamento que o Android já ensinou à merendeira. A folha que sobe de baixo para escolher o gênero, o teclado numérico, o botão voltar e o foco de acessibilidade se comportam como em qualquer outro aplicativo do aparelho dela. A alternativa considerada, uma adaptação do shadcn/ui para Flutter, daria mais parecença visual com a web ao custo de um pacote de terceiro com cara de desktop, que precisaria ser reescalado para o dedo do mesmo jeito. O tema escuro é o mesmo conjunto de tokens com outra paleta (RNF#1 da US024), e a preferência mora no aparelho, como na web.

**Histórias**: US003, US004, US024; transversal.

## 4. Riverpod para o estado

**Decisão**: o estado do aplicativo é gerenciado com Riverpod. O que vem do servidor e do banco local chega às telas como provedores assíncronos; o rascunho, a fila e a sessão são provedores próprios, pequenos, com a regra de negócio fora dos widgets.

**Por quê**: é o papel que a TanStack Query faz na web (decisão 4 da E5), sem a biblioteca ser a mesma: o valor assíncrono do Riverpod já distingue carregando, erro e dado, e a tela não reinventa esses três estados em cada lugar. Dois motivos pesaram contra as alternativas. Primeiro, a fila precisa ler e escrever estado **fora** de qualquer tela — ela trabalha enquanto a merendeira está no mês, no registro ou no menu —, e o Riverpod não depende da árvore de widgets para isso. Segundo, nos testes de widget cada provedor é substituível por um falso sem pacote de simulação, o que torna testável a regra que mais importa (decisão 13). O Bloc resolveria o mesmo com mais cerimônia por tela, e o estado nativo do Flutter deixaria o cache e os estados de carregamento escritos à mão.

**A fronteira da E5 vale igual**: o que é leitura de servidor e o que é escrita que ainda não subiu não se misturam. Persistir leitura para abrir sem rede é assunto do banco local (decisão 6); garantir que a escrita não se perde é assunto da fila (decisão 8).

**Histórias**: US008, US010, US011.

## 5. go_router, e a guarda de rota continua não sendo a segurança

**Decisão**: navegação com `go_router`. Sem sessão, toda rota leva ao login; com sessão de merendeira, a casa é a visão do mês. O botão voltar do Android segue a pilha: do registro do dia volta ao mês, do mês sai do aplicativo.

**Por quê**: é o pacote de roteamento mantido pelo próprio time do Flutter, e o redirecionamento por sessão faz o que a guarda do React Router faz na web, num lugar só em vez de espalhado pelas telas. O que a decisão 6 da E5 disse continua valendo inteiro: **a guarda é conveniência de interface, não controle de acesso**. Um aplicativo instalado é ainda mais fácil de inspecionar que uma página, e quem decide o que a merendeira lê e escreve são as políticas de RLS da E4.

**Histórias**: US016, US020.

## 6. O banco local é Drift sobre SQLite, um arquivo por usuária

**Decisão**: o que o aplicativo guarda no aparelho vive num banco SQLite acessado pelo Drift: os meses já consultados, o catálogo de gêneros, a lista de documentos gerados, o rascunho e a fila de envio. Cada usuária tem o próprio arquivo de banco, escolhido pelo identificador dela no login.

**Por quê**: a web guardou só o que ainda não subiu (decisão 3 da E5), porque abrir do zero sem rede não era promessa dela. No aplicativo é — é o CA#1 da US010 —, e isso muda a natureza do que se guarda: deixa de ser uma fila de dias e passa a ser uma cópia do que ela consulta, com consultas por mês, por estado e por nome de gênero. Isso é banco relacional, e o SQLite é o banco que o Android já traz. O Drift acrescenta o que faria falta escrevendo SQL em texto: consultas tipadas, migrations versionadas do esquema local e **consultas que avisam quando o resultado muda** — quando a fila confirma um dia, a visão do mês se redesenha sozinha, sem que alguém precise lembrar de avisá-la. É a lição que o [teste de ponta a ponta da web](../05-web/teste-ponta-a-ponta.md#o-que-ele-achou-antes-de-fechar) cobrou, resolvida pela ferramenta em vez de por disciplina. O banco em memória é o que roda nos testes. Hive e Isar foram descartados porque os dois ficaram sem manutenção de quem os criou.

**Um arquivo por usuária** é o que cumpre a separação dos dados no aparelho sem uma coluna de dono em cada tabela e um filtro em cada consulta — que é exatamente o tipo de filtro que um dia alguém esquece. As duas merendeiras dividem o mesmo mapa da escola, mas a fila e o rascunho são de quem digitou.

**A lista de documentos gerados** entra no banco local porque a RNF#1 da US021 pede que ela abra sem rede com o que já foi sincronizado. O que fica no aparelho é a lista, não o arquivo: abrir e compartilhar o documento continuam exigindo rede, como a própria RNF diz. É também essa lista que o aviso de documento pronto (decisão 11) consulta ao abrir.

**Histórias**: US008, US009, US010, US011, US021.

## 7. Sem rede: o registro inteiro sim, a administração do catálogo e a geração não

**Decisão**: funcionam sem conexão o registro do dia inteiro — refeições, aceitação, número de refeições, dia não letivo, alteração do cardápio e gêneros utilizados, inclusive o **cadastro de gênero novo** feito da folha de escolher gênero —, a visão do mês, a leitura do catálogo e a lista de documentos. Exigem conexão a manutenção do catálogo (renomear, trocar a unidade, desativar e reativar um gênero) e a geração do documento. Cada tela que exige rede diz isso na tela, com os textos do [catálogo de avisos](../03-ux/avisos-e-mensagens.md).

**Por quê**: o recorte segue a dor, não a lista de telas. O que a entrevista pediu que funcionasse sem rede foi o preenchimento, feito em casa, à noite, onde a conexão falha — e esse está inteiro, porque o gênero novo sai de graça pelo contrato: a `save_meal_map` cria o gênero pelo nome se ele ainda não existir (decisão 9 da E4). A manutenção do catálogo é outra coisa: é administração de recursos, ocasional, e levá-la para a fila significaria resolver conflito de renomeação e de troca de unidade entre dois aparelhos — a troca de unidade reescreve os dias já registrados (issue #64) — para um gesto que ninguém precisa fazer sem sinal. A geração exigir rede não é decisão nova: a decisão 10 da E3 já recusava uma fila de geração, porque o passo seguinte, compartilhar pelo WhatsApp, também precisa de rede — a fila não compraria nada e custaria estado a mais.

**Consequência honesta**: o CA#1 da US010 diz que "todo o fluxo de registro e catálogo (US001–US009) funciona sem nenhuma conexão". O registro cumpre; o catálogo cumpre na leitura e no cadastro pelo registro, e **não** cumpre na manutenção. Fica registrado aqui, como a decisão 2 da E5 registrou a parte dela, e não descoberto na E7.

**Histórias**: US009, US010, US012, US021.

## 8. O envio acontece com o aplicativo aberto

**Decisão**: a fila de envio trabalha enquanto o aplicativo está aberto — ao abrir, quando a conexão volta e a cada dia que ela altera. Nada é agendado para rodar com o aplicativo fechado: o que ficou na fila sobe na próxima abertura. A unidade continua sendo o dia, os identificadores continuam sendo UUID gerados no aparelho, e o dia só sai da fila depois que o servidor confirma (RN#1 da US011), como na [camada local](../05-web/camada-local.md) da web.

**Por quê**: o agendamento em segundo plano do Android existe, mas cobra o que este produto não tem para pagar. Cada fabricante mata tarefa de fundo do seu jeito para economizar bateria, e o comportamento real varia de aparelho para aparelho — a fila passaria a ter um segundo caminho de execução, sem tela, que falha em silêncio justamente onde ninguém está olhando. O ganho, por outro lado, é pequeno: a merendeira abre o aplicativo para registrar, e é na abertura que a fila sobe. O cenário que o segundo plano salvaria — registrar sem rede, fechar e nunca mais abrir antes da geração — é coberto pela seleção de mapas, que mostra o dia esperando envio fora do documento e oferece "Enviar agora" (issue #108), e pela colega, que vê o dia faltando.

**A leitura da US011**: a RNF#1 pede que "a sincronização ocorra em segundo plano, sem bloquear o uso do app". O segundo plano ali é o da tela — o envio não trava a merendeira enquanto ela registra —, e isso o aplicativo cumpre. Rodar com o aplicativo fechado não é o que a história pede.

**Histórias**: US010, US011.

## 9. A senha se resolve dentro do aplicativo, por código de 6 dígitos

**Decisão**: nada do que é conta abre o navegador. A merendeira que esqueceu a senha pede um código, recebe por e-mail um código de 6 dígitos e digita, na mesma tela, o código e a senha nova. O convite da direção é o mesmo caminho: a conta nasce na web e a senha é definida pela redefinição (ver a [administração da escola](../05-web/administracao.md)). O modelo de e-mail passa a trazer as duas coisas — o link, para quem estiver na web, e o código, para quem estiver no aplicativo. A sessão fica guardada em armazenamento seguro do aparelho e persiste entre aberturas (RNF#2 da US016).

**Por quê**: um aplicativo que abre o navegador para a pessoa trocar a senha e depois a deixa lá, sem caminho de volta, parece amador — e para uma usuária pouco habituada a tecnologia, a volta é exatamente onde ela se perde. O caminho óbvio para evitar isso, um link que reabre o aplicativo, foi descartado porque não volta ao aplicativo de forma confiável: depende do cliente de e-mail, do navegador padrão e da versão do Android. O código é o que o Supabase já oferece na recuperação de senha, com o mesmo tamanho de 6 dígitos que o projeto já configura, e não depende de nada disso — ela lê o número num aplicativo e digita no outro. Guardar a sessão em armazenamento seguro, e não num arquivo de preferências comum, é o mínimo para um aparelho que fica aberto na cozinha de uma escola.

**Histórias**: US016.

## 10. Documento pronto é aviso ao abrir, não notificação por push

**Decisão**: o aplicativo não usa notificação por push. Ao abrir, ele consulta os documentos gerados da merendeira e, se algum ficou pronto e ainda não foi visto, mostra um aviso em destaque com "Compartilhar", que leva à tela do documento. O "já visto" é guardado no aparelho. A notificação do sistema desenhada na E3 vira esse aviso na tela, e o desenho, a imagem e o [catálogo de avisos](../03-ux/avisos-e-mensagens.md) mudam junto (issue #110).

**Por quê**: a notificação da E3 nasceu de uma premissa que a E5 desmentiu — a de que a geração poderia terminar muito depois do pedido, com a merendeira fora da tela. A geração responde em menos de um segundo ([geração do documento](../05-web/geracao-do-documento.md)), então o caso real é outro: o aplicativo morrer durante o pedido, ou ela sair antes de compartilhar. Os dois se resolvem na próxima abertura, e é na abertura que o aviso aparece. O push, para cobrir esse caso, traria o Firebase Cloud Messaging, um projeto no Firebase, o registro do aparelho e uma migration para guardá-lo, e um disparo a partir da Edge Function — tudo para avisar de uma coisa que ela mesma acabou de pedir.

**O que isto desfaz**: a decisão 12 da E4 previa uma migration própria, na E6, para os tokens de notificação. Ela não nasce. O "já visto" fica no aparelho porque é estado de leitura de uma pessoa num aparelho — como a preferência de tema —, e não fato da escola.

**Histórias**: US012, US021.

## 11. Distribuição por GitHub Releases, sem loja

**Decisão**: o APK chega às merendeiras pelo GitHub Releases do repositório. Uma tag `app-v*` dispara uma Action que compila o APK assinado e cria a release com o arquivo anexado e as notas geradas. A chave de assinatura fica fora do repositório — nos segredos do GitHub e numa cópia privada do autor. A primeira instalação é feita a partir do arquivo mandado pelo WhatsApp; daí em diante, o próprio aplicativo baixa a release nova e chama o instalador do Android, sem navegador (decisão 12). A CI dos Pull Requests compila o APK para provar que ele compila, mas não o anexa: a versão que chega às merendeiras sai só pela release.

**Por quê**: publicar na Play Store faria sentido para um produto aberto ao público, e este tem duas usuárias. A loja cobraria conta de desenvolvedor, revisão a cada versão e, para contas pessoais novas, um teste fechado com um número mínimo de testadores durante semanas antes de liberar a produção — um prazo que a E6 não comporta. O GitHub Releases entrega o que falta sem nada disso: versões numeradas, arquivo anexado, notas do que mudou e um endereço estável de onde o aplicativo busca a última versão. E ele amarra cada APK a uma tag, e cada tag a um commit, o que mantém a cronologia do repositório como evidência — o mesmo motivo por que a web publica a partir da `main`. A chave de assinatura tem cópia fora do GitHub porque, perdida, nenhum aparelho aceita mais atualização assinada por outra — a merendeira teria que desinstalar, e desinstalar apaga o que está no aparelho.

**Histórias**: transversal; entrega da E6.

## 12. Trava de versão mínima desde a primeira versão

**Decisão**: o banco guarda a versão mínima do aplicativo que ele aceita. O aplicativo confere essa versão ao abrir e antes de mandar a fila; abaixo do mínimo, para de enviar, **mantém tudo o que está no aparelho** e oferece a atualização. A `save_meal_map` recusa o aplicativo abaixo do mínimo pelo cabeçalho de versão que ele manda; a web não manda cabeçalho e segue como está. A regra de operação é uma só: **o APK novo sai antes da migration que sobe o mínimo**.

**Por quê**: um aplicativo instalado não aprende comportamento novo — ele só respeita a trava que já veio com ele. Se a primeira versão sair sem a trava, a primeira migration que mudar o contrato encontra um aplicativo velho mandando o que o banco não aceita mais, e esse aplicativo não sabe o que fazer com o erro: a fila fica tentando para sempre, e a faixa diz a ela que vai tentar de novo. Com a trava, o erro vira um estado que o aplicativo conhece e explica. É também o que torna aceitável a decisão 2 escrever os modelos à mão: o descompasso entre aplicativo e banco deixa de ser um defeito silencioso e passa a ser uma atualização pedida. A ordem da regra de operação existe porque o contrário tranca todo mundo para fora: subir o mínimo antes de haver APK que o satisfaça deixa as merendeiras sem ter para onde atualizar. Um aviso "leve" de versão nova, sem trava, foi considerado e descartado — aviso que se pode ignorar é aviso que se ignora, e o único motivo para atualizar que importa aqui é o que a trava já cobre.

**Histórias**: US010, US011.

## 13. Unidade e widget na CI; o caminho crítico, à mão no aparelho

**Decisão**: testes de unidade e de widget com o `flutter_test`, rodando na CI em todo Pull Request que toca `app/`, junto com formatação, análise estática e compilação do APK (issue #100). A prioridade é a mesma da decisão 11 da E5: a fila, o reenvio, a convergência, as regras de estado do mapa e agora a leitura sem rede do banco local. O caminho crítico — entrar, registrar um dia sem rede, voltar à rede, ver o dia subir, gerar e compartilhar o documento — é percorrido à mão num aparelho de verdade antes de cada release. Não há teste ponta a ponta com emulador na CI.

**Por quê**: o que quebra em silêncio no aplicativo é o mesmo que na web — a fila —, e a fila é o tipo de lógica que teste de unidade cobre bem; o banco em memória do Drift (decisão 6) e os provedores substituíveis do Riverpod (decisão 4) existem nesta stack também por isso. O ponta a ponta automatizado custaria um emulador Android na CI — lento, instável e caro de manter — para provar o que, no aplicativo, depende justamente do que o emulador imita mal: a rede do aparelho caindo e voltando, o sistema matando o aplicativo, a folha de compartilhamento abrindo o WhatsApp. Percorrer isso à mão num aparelho real antes de cada release prova mais e custa menos. E, como a E5 já registrou, a E7 é outra coisa: teste com usuária real, que revela problema de uso, não regressão.

**Histórias**: transversal; US010, US011, US012, US014.

## 14. O que fica de fora desta decisão, e quando cada coisa se decide

- **Compartilhamento pela folha do Android** — o pacote que abre a folha nasce com a tela de documento gerado (issue #109).
- **Download e instalação da atualização** — como baixar o APK e chamar o instalador, e a permissão de instalar aplicativos que isso exige, se decidem com a trava de versão (issue #113).
- **Detecção de conexão** — se a fila precisa de um pacote para saber que a rede voltou, ou se basta tentar e falhar, se decide com a fila (issue #103).
- **Armazenamento seguro da sessão** — o pacote que guarda a sessão no cofre do Android se escolhe com a autenticação (issue #101).
- **Formulários, validação e datas** — como na web, nascem com a primeira tela que precisar delas, se precisarem.
- **iOS** — fora do escopo, pela decisão 2.

## Ordem de ataque

Primeiro a base: o projeto Flutter com os tokens da E3 e os ambientes (issue #99), e logo em seguida a CI (issue #100), para que tudo o que vier depois já nasça verificado. Depois, a mesma ordem que a E5 seguiu — a porta de entrada, a camada de dados e só então as telas —, com uma diferença: a camada de dados do aplicativo tem dois andares, o banco local (issue #102) e a fila sobre ele (issue #103). As telas vêm na ordem do fluxo da merendeira, do mês ao documento (issues #104 a #109), seguidas do aviso de documento pronto e do tema escuro (issues #110 e #111). A release e a trava de versão mínima (issues #112 e #113) entram juntas, antes do primeiro APK entregue — a trava precisa estar na primeira versão, porque é a única que o aplicativo mais antigo em uso vai conhecer.
