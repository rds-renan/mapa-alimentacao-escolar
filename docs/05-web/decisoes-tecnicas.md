# Decisões técnicas — E5 (web)

> Etapa E5 do projeto. A stack da aplicação web e o porquê de cada escolha, decidido antes da primeira linha de código porque essas decisões condicionam todas as issues da etapa. Faz o mesmo papel que as [decisões de design](../03-ux/decisoes-de-design.md) fizeram na E3 e as [decisões de modelagem](../04-banco-de-dados/decisoes-de-modelagem.md) na E4, e alimenta diretamente a tabela de codificação exigida na entrega final.
>
> O que **não** está aqui é tão deliberado quanto o que está: a convenção do projeto é não adicionar dependência por antecipação. A seção final registra o que ficou de fora e em que momento cada coisa se decide.

## 1. Vite + React + TypeScript, sem servidor próprio

**Decisão**: a web é uma aplicação de página única construída com Vite, em React e TypeScript, falando direto com o Supabase pelo `supabase-js`. Gerenciador de pacotes `npm`, padronização com ESLint e Prettier. O código vive em `web/`, no monorepo.

**Por quê**: o React já estava decidido desde o [plano de projeto](../planodeprojeto.md); o que faltava era o entorno. Não existe camada de servidor a manter: o que precisa rodar no servidor — a geração do documento a partir do template oficial — já é Edge Function no Supabase, por decisão da E4, e tudo o mais é acesso autenticado ao banco com as políticas de RLS decidindo o que cada perfil enxerga. Um framework com renderização no servidor traria rotas de servidor, uma segunda hospedagem e um modelo mental a mais para sustentar um aplicativo que é inteiramente atrás de login e sem nada a indexar. O TypeScript não é preferência estética: os tipos do banco são gerados a partir das migrations da E4 (decisão 8), e é isso que faz o schema em inglês render no código o que a decisão 13 da E4 prometeu.

## 2. Na web, o offline garante que nada se perde; o offline integral é do aplicativo

**Decisão**: a web persiste localmente o dia em edição e a fila de envios pendentes, e sobe tudo sozinha quando a rede volta. Ela **não** promete operar integralmente sem conexão — abrir o aplicativo do zero, navegar o mês e consultar o catálogo continuam exigindo rede. O funcionamento 100% offline da US010 é entregue no aplicativo Android, na E6.

**Por quê**: a US010 tem duas metades e elas não custam o mesmo. A segunda — "nunca perder o que já digitei" — é a dor visceral da entrevista, e é ela que a persistência local resolve, na web como no aplicativo. A primeira — "preencher o mapa inteiro sem internet" — descreve o uso real, que acontece no celular, em casa, à noite, e é para esse uso que existe a E6. Entregar offline integral duas vezes, em duas tecnologias, com service worker e cache de leitura na web para o que ninguém vai fazer na web, custaria o item mais caro da etapa no caminho crítico do prazo — e o caminho crítico é justamente a web.

**Consequência honesta**: o CA#1 da US010 ("todo o fluxo de registro e catálogo funciona sem nenhuma conexão") é cumprido na E6, não na E5. O CA#2 e o CA#3 são cumpridos nas duas. A US011 inteira é cumprida nas duas. Isto fica registrado aqui, e não descoberto na E7.

**Histórias**: US010, US011.

## 3. O rascunho mora no IndexedDB, e o dia continua sendo a unidade

**Decisão**: cada alteração de campo é escrita imediatamente num rascunho local no IndexedDB, e o envio ao servidor é uma fila persistida no mesmo lugar. A unidade de gravação é o dia inteiro — mapa, refeições, alteração e gêneros utilizados —, exatamente como a decisão 9 da E4 definiu, chamando a operação atômica do servidor. Os identificadores são UUID gerados no cliente.

**Por quê**: o IndexedDB e não o `localStorage` porque o objeto salvo é o dia inteiro, com listas dentro, e porque o `localStorage` é síncrono — escrever a cada tecla numa thread que também desenha a tela é como se fabrica travamento. O UUID gerado no cliente é o que torna a fila **idempotente**: reenviar um item que já chegou reescreve o mesmo dia com o mesmo identificador, em vez de duplicar registro — sem isso, toda falha de rede ambígua viraria mapa repetido. E manter o dia como unidade evita que a web invente um protocolo de sincronização diferente do que o aplicativo vai usar na E6, contra o mesmo banco.

**Como ficou**: um depósito só no IndexedDB, porque o rascunho e a fila são a
mesma coisa — estar guardado ali é ser dia que o servidor ainda não confirmou. O
que se grava é, campo por campo, o payload de `save_meal_map`, sem tradução no
meio. Os detalhes, e o defeito de concorrência que os testes acharam no caminho,
estão na [camada local](camada-local.md).

**Histórias**: US001, US007, US010, US011.

## 4. A fronteira: TanStack Query cuida do servidor, o rascunho é nosso

**Decisão**: o estado que vem do servidor — lista de mapas do mês, catálogo, documentos gerados, dados da escola — é gerenciado pela TanStack Query, com seu cache, revalidação e retentativas. O rascunho não enviado e a fila são um módulo próprio, pequeno, sobre o IndexedDB. As duas coisas não se misturam: a tela do dia lê o rascunho quando ele existe e o servidor quando não existe.

**Por quê**: cache, invalidação e estados de carregando/erro são problema resolvido, e reescrevê-los à mão consumiria a etapa sem entregar nada que a usuária veja. A tentação seria usar a persistência de cache da própria Query e chamar aquilo de offline — mas persistir cache é sobre **leitura**, e o que este produto precisa persistir é **escrita** que ainda não subiu. São problemas diferentes, e confundi-los é como se perde preenchimento. Manter a fila num módulo próprio também é o que deixa a regra "o dado local nunca é descartado antes de confirmado no servidor" (RN#1 da US011) explícita num lugar só, em vez de emergente do comportamento de uma biblioteca.

**Como ficou**: as duas metades estão de pé. A de baixo — a escrita que ainda
não subiu — é a [camada local](camada-local.md); a de cima entrou com a [visão
do mês](visao-do-mes.md), que é a primeira tela que **lê** do servidor. Lá as
duas se encontram pela primeira vez, e a fronteira ganhou a regra que faltava:
quando o mesmo dia existe nas duas origens, vale o rascunho — **menos o
bloqueio**, que ele não tem como conhecer.

**Histórias**: US008, US009, US010, US011, US021.

## 5. Convergência: prevalece a última edição, e o caso é sinalizado

**Decisão**: quando o mesmo dia foi editado em dois lugares, prevalece a edição mais recente pela data de última alteração do mapa, e a usuária é avisada de que aquilo aconteceu — nunca em silêncio. A comparação é feita no servidor, dentro da mesma operação atômica que grava o dia.

**Por quê**: é literalmente o CA#3 da US011, e a decisão 9 da E4 já tinha escolhido resolver o conflito num ponto só justamente para que essa regra coubesse numa comparação de data. As duas merendeiras se revezam no mapa e ambas veem tudo — o cenário não é hipotético.

**Detalhe que a E4 já pagou caro para aprender**: o carimbo de quem editou por último não pode ser tocado por operação que não seja edição da merendeira. Se o desbloqueio feito pela direção reescrevesse esse carimbo, a direção viraria "última editora" e passaria a ganhar toda convergência — a regra da US011 se decidiria pelo evento errado.

**Como ficou**: o servidor compara e devolve `superseded`; o cliente obedece,
recarrega o dia e **avisa**. O aviso é texto novo — a E3 desenhou a faixa com
três estados e nenhum deles é o conflito —, e ele está registrado, com a origem
declarada, na [camada local](camada-local.md).

**Histórias**: US011, US023.

## 6. React Router, e a guarda de rota não é a segurança

**Decisão**: roteamento com React Router. As rotas de administração ficam atrás de uma guarda que checa o perfil da sessão, e as telas do fluxo diário atrás da sessão autenticada.

**Por quê**: são poucas rotas — as doze telas desenhadas na E3 —, e o que pesa na escolha é material de consulta abundante e um modelo mental simples, não tipagem de parâmetros de rota que aqui renderia pouco. O ponto importante é outro: **a guarda de rota é conveniência de interface, não controle de acesso**. Quem decide o que cada perfil pode ler e escrever são as políticas de RLS da E4, no banco, onde ninguém contorna abrindo o DevTools. Esconder o menu de administração de quem não é administrador é cortesia; impedir que ele leia os dados é a política.

**Histórias**: US016, US017, US023.

## 7. Tailwind e shadcn/ui, com os tokens da E3 mandando

**Decisão**: estilo com Tailwind e componentes do shadcn/ui, configurados a partir dos tokens definidos na [decisão 6 da E3](../03-ux/decisoes-de-design.md) — acento `#397ba1`, escala tipográfica, espaçamento, raios e alvo de toque mínimo de 44 px, com os tamanhos de controle elevados em relação ao padrão da biblioteca. O tema escuro (US024) é o mesmo conjunto de tokens com outra paleta, e a preferência mora no aparelho, não no banco.

**Por quê**: a decisão já estava tomada na E3 e é aqui que ela vira código. O shadcn/ui entrega o componente como arquivo no projeto, e não como dependência fechada — o que importa num produto cujo padrão de tamanho **diverge** do padrão da biblioteca: os controles precisam ser de dedo, não de mouse. A preferência de tema fora do banco é a decisão 12 da E4, e continua valendo: é escolha de aparelho, não atributo da pessoa.

**Histórias**: US003, US004, US024.

## 8. Os tipos do banco são gerados, não escritos

**Decisão**: os tipos TypeScript das tabelas saem de `supabase gen types typescript` a partir das migrations, ficam versionados em `web/` e são regerados quando o schema muda. A CI falha se o arquivo versionado estiver defasado em relação às migrations.

**Por quê**: é o que faz valer a decisão 13 da E4 — o schema em inglês existe para render autocompletar e checagem no código, e um tipo escrito à mão envelhece em silêncio até o dia em que mente. Checar isso na CI é barato e evita a classe inteira de erro em que a interface acredita numa coluna que o banco não tem mais. A fronteira de idioma continua a mesma no código: identificadores em inglês, textos de interface em português, sem exceção no meio.

## 9. Na web, compartilhar é baixar

**Decisão**: gerado o documento, a web oferece o download do arquivo e, quando o navegador expuser a API de compartilhamento nativa, também o botão de compartilhar. A folha de compartilhamento do Android descrita na US014 é entregue no aplicativo, na E6.

**Por quê**: o CA#1 da US014 fala explicitamente da folha de compartilhamento do Android, que é recurso de plataforma. Na web ela existe de forma parcial e desigual entre navegadores — tratá-la como garantia seria prometer o que o meio não sustenta. O que importa para a estratégia de aceitação institucional se preserva inteiro: o arquivo é o mesmo, o caminho continua sendo a merendeira enviando pelo aplicativo que ela escolher, e o sistema nunca envia sozinho (RN#1 da US014).

**Histórias**: US012, US014, US021.

## 10. Cloudflare para hospedar, GitHub Actions para verificar

**Decisão**: a web é publicada no Cloudflare Pages, com implantação contínua a partir da `main` e prévia por branch. As GitHub Actions rodam lint, checagem de tipos, build e testes em cada Pull Request. Nenhuma chave sensível entra no pacote publicado: vai apenas a URL do projeto e a chave anônima do Supabase, que é pública por construção e só tem o poder que as políticas de RLS lhe derem. A chave de serviço existe apenas no ambiente das Edge Functions.

**Como ficou**: dois fluxos no GitHub Actions — um para a web, outro para o banco — e o Cloudflare ligado direto ao repositório, sem token no GitHub. O caminho de cada verificação, a configuração do painel e o que a prévia compartilha com a produção estão na [integração contínua e publicação](integracao-continua-e-publicacao.md).

**A hospedagem mudou de produto dentro da Cloudflare, e não de fornecedor**: saiu o Pages, entrou o Workers com assets estáticos. Ao implementar, a própria documentação do Pages passou a dizer que Workers é a plataforma principal e que projetos novos devem começar por lá — o Pages segue mantido e recebendo correções, mas o investimento da Cloudflare está todo no outro lado. Para uma aplicação estática os dois entregam o mesmo (publicação a partir do repositório, prévia por branch, TLS, domínio, requisições a arquivos estáticos sem custo), então o que decidiu foi o horizonte: este sistema é para ficar em uso na escola depois da entrega, e trocar de produto depois custaria trocar o endereço com as merendeiras — que é o tipo de atrito que não se paga duas vezes. A única vantagem que o Pages mantinha — aceitar domínio cujos nameservers não estejam na Cloudflare — caiu quando ficou decidido que uma eventual demanda da prefeitura seria outro produto, não este.

**Por quê**: o [plano de projeto](../planodeprojeto.md) previa "Vercel ou similar" e a escolha caiu no Cloudflare Pages, que entrega o mesmo — publicação a partir do repositório, prévia por branch, TLS e domínio — sem custo para o porte deste projeto. A prévia por branch tem valor além do técnico: cada Pull Request passa a ter um endereço navegável, o que é evidência de gestão para a avaliação. Separar publicação de verificação mantém a CI como o lugar onde o erro aparece, e não a produção.

## 11. Vitest e Testing Library no dia a dia, um Playwright no caminho crítico

**Decisão**: testes de unidade e de componente com Vitest e Testing Library, cobrindo prioritariamente a fila de envio, a resolução de convergência e as regras de estado do mapa. Um único teste ponta a ponta em Playwright percorre o caminho crítico: registrar um dia, sincronizar, selecionar mapas e gerar o documento.

**Como ficou, por enquanto**: o entorno — Vitest, jsdom e Testing Library — entrou junto com a CI, com um teste de fumaça, porque um passo de testes que não pode reprovar não verifica nada. O peso previsto aqui chega com a fila e a convergência; o Playwright, com o caminho crítico que ele percorre.

**Por quê**: o que quebra em silêncio neste produto não é a tela, é a fila — e fila é exatamente o tipo de lógica que teste de unidade cobre bem e olho humano cobre mal. O E2E é um só de propósito: ele existe para provar que o caminho inteiro fecha, e vira evidência direta no laudo de qualidade da E7. Vale lembrar o que a E7 é e o que ela não é: teste com usuária real, que revela problema de uso, não regressão. As duas coisas não se substituem.

## 12. O que fica de fora desta decisão, e quando cada coisa se decide

- **Biblioteca de geração do documento** — a Edge Function que preenche o template oficial é o risco declarado no plano de projeto. Merecia um *spike* próprio, com issue própria, antes de virar decisão: primeiro se descobre o que preenche o template com fidelidade, depois se escolhe a ferramenta. **Resolvido** — o spike foi feito e a resposta virou a decisão 13, abaixo.
- **Biblioteca de gráficos** — **não nasceu**, e a previsão estava errada. O painel gerencial (US017) foi implementado na issue #70 e o desenho da E3 não pede gráfico nenhum que precise de uma: são uma barra empilhada de três valores e cinco barras de proporção, sem eixo, escala, tooltip nem série temporal. Cem quilobytes para desenhar retângulos seria peso sem contrapartida, e o projeto não adiciona dependência por antecipação. A paleta de dados da decisão 6 da E3 entrou do mesmo jeito, nos tokens `--chart-1/2/3`. Ver o [painel gerencial](painel-gerencial.md#os-gráficos-são-divs). Se um gráfico de verdade aparecer depois — uma linha de aceitação ao longo do ano, por exemplo —, a decisão se reabre com o caso concreto na mão.
- **Formulários, validação e datas** — nascem com a primeira tela que precisar delas, se precisarem.
- **Notificação de documento pronto** — depende de aparelho registrado, o que só existe na E6 (decisão 12 da E4).
- **Biblioteca de interface do aplicativo Android** — é decisão da E6, conforme a decisão 6 da E3, e será registrada em `docs/06-app/`. O que atravessa as duas plataformas são os tokens, não os componentes.

## 13. O documento sai do próprio modelo, sem biblioteca de template

**Decisão**: a geração do documento oficial não usa biblioteca de *templating*. O gerador abre o `.docx` do modelo vigente, **clona o bloco de quatro linhas que ele já traz** — as três refeições e a justificativa — uma vez por dia do período, e escreve o conteúdo dentro do XML que veio da prefeitura. As únicas dependências são uma de zip e uma de XML. O reconhecimento do modelo é pelos rótulos que ele próprio imprime, e um modelo que não os traga faz a geração falhar dizendo qual faltou.

**Como ficou**: o protótipo gerou o mês inteiro a partir do arquivo oficial de verdade em 336 ms, contra o teto de 30 segundos do RNF#2, e graduou para [`supabase/functions/`](../../supabase/functions/) — o preenchimento em `_shared/`, dentro da Edge Function `generate-document` que o implanta. O relato completo, do spike ao contrato da função, está na [geração do documento oficial](geracao-do-documento.md).

**Por quê**: o spike desfez a premissa de que existia um "template". O arquivo da escola é um mapa preenchido à mão, com altura de linha travada a olho e cabeçalho copiado no meio da tabela — não um gabarito. O docxtemplater, a escolha óbvia, precisa de `{tags}` escritas dentro do documento: testado contra o arquivo oficial, não achou marcação nenhuma e devolveu o arquivo intacto. Preparar o modelo seria trabalho de edição no Word, e quem sobe o modelo é a direção da escola (RN#1 da US015), com o arquivo que a prefeitura mandou — seria transferir o risco do spike para a pessoa menos equipada para absorvê-lo, e refazê-lo a cada arquivo novo. Montar o documento do zero em código daria controle total ao custo de virar dono de uma cópia do formulário que envelhece calada quando a prefeitura mudar o dela — e a US015 existe porque esse dia chega. Reaproveitar o XML do modelo é o que mantém o formato sendo **deles**, não nosso.

## 14. As telas da direção carregam sob demanda; as da merendeira, não

**Decisão**: as duas rotas da área da direção entram por `lazy()`, num pedaço próprio do pacote; o fluxo da merendeira continua inteiro na carga inicial. O relato está em [a administração da escola](administracao.md#o-peso-do-pacote-e-a-divisão-por-rota-que-ele-cobrou).

**Como ficou**: a tela de gestão (issue #68) levou a carga inicial de 203,1 kB para 207,8 kB em gzip e reprovou na CI, que vigia 205 kB. Com a divisão, 203,5 kB — e as telas da direção num arquivo de 6,25 kB que só quem entra como direção baixa.

**O que faltava, e a issue #70 achou**: o `lazy()` separava o **nosso** código e deixava as dependências passarem. O grupo `vendor` do rolldown varria todo o `node_modules` para um pedaço só, que é carga inicial — então a biblioteca que só a direção usa chegava no celular da merendeira mesmo que ela nunca abrisse `/admin`. Foi o que aconteceu com o menu suspenso do painel: 17 kB gzip a mais na carga inicial, 221,0 kB, teto estourado de novo, e o `lazy()` da rota impotente. A correção é uma etiqueta em `web/vite.config.ts` — `tags: ['$initial']` no grupo —, que manda capturar só o que está no grafo estático da entrada; o que é alcançável apenas por rota carregada sob demanda cai no pedaço dela. Carga inicial: **203,8 kB**, com o painel inteiro dentro, e o menu suspenso viajando nos 20,6 kB do arquivo do painel. A decisão passou a valer para as dependências, que é onde o peso mora de verdade.

**Por quê**: não é economia de bytes por esporte, é para quem o peso é cobrado. Quem abre o aplicativo todo dia é a merendeira, de celular e numa rede fraca, e ela nunca abre a administração — são dois fluxos separados (RN#1 da US020), não um com telas a mais. Dividir ali corta o que ela nunca usa sem lhe custar espera nenhuma. Dividir o fluxo **dela** seria o contrário: a espera de um pedaço que falta cairia no meio do registro, que é exatamente o momento em que a rede da escola não está lá. É também a metade da issue #84 que faltava, aplicada no primeiro dia em que ela pagou.

## Ordem de ataque

A primeira coisa da etapa é a operação atômica de gravação do dia no banco — a decisão 9 da E4, deixada de fora daquela etapa de propósito, porque a lógica que a usa só nasce aqui e ela teria nascido para ser modificada. Com ela de pé e a fundação do projeto montada, vêm autenticação e sessão, a camada de dados com fila, e só então as telas, na ordem do fluxo da merendeira.
