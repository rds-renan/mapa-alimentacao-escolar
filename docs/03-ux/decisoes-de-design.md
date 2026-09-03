# Decisões de design — E3

> Etapa E3 do projeto (refs #25). Decisões de UX que os wireframes concretizam e que servem de insumo direto à modelagem de dados (E4) e ao desenvolvimento (E5/E6). Cada decisão referencia as histórias afetadas.

## 1. Mobile-first; web como o mesmo fluxo responsivo

**Decisão**: as telas da merendeira são desenhadas em largura de celular (390 px) e valem para web e app; só a área do admin tem layout desktop (1440 px).

**Por quê**: o uso real é no celular e o preenchimento acontece em casa; desenhar duas UXs dobraria o custo de implementação e de validação. A web (E5) entrega o mesmo fluxo com container central; o Flutter (E6) reaproveita as mesmas telas por construção.

**Histórias**: todas do fluxo da merendeira; US015–US017 (admin).

## 2. Quantidade de gêneros: stepper de inteiros com unidade fixa

**Decisão**: a quantidade de cada gênero é informada por um stepper (− / número / +), com o número tocável abrindo teclado numérico; a unidade aparece como rótulo fixo, vindo do catálogo, e não é editável no registro.

**Por quê**: as quantidades reais são inteiros pequenos e sempre na unidade padrão do item ("1 saco de leite em pó", "4 quilos de pão") — confirmado nas entrevistas da E1. O stepper resolve o caso comum em um toque e elimina texto livre e erro de formato. A unidade morar no catálogo (e não no registro) garante consistência e simplifica o modelo de dados da E4.

**Histórias**: US003, US009.

## 3. Linguagem de salvamento e offline: três estados, sem botão de salvar

**Decisão**: não existe botão "Salvar" — todo registro é salvo automaticamente a cada alteração. O estado de sincronização aparece numa faixa fixa com três mensagens:

| Estado | Mensagem |
|---|---|
| Salvo localmente | "Salvo no aparelho. Envia sozinho quando houver internet." |
| Sincronizado | "Enviado. Este mapa já está disponível para gerar o documento." |
| Falha de envio | "Ainda não deu para enviar. Nada foi perdido, vamos tentar de novo." |

**Por quê**: offline-first é o requisito não funcional central do produto (US010/US011) e a maior dor relatada foi perder preenchimento. Um botão de salvar seria promessa falsa num app com autosave; a mensagem de falha afirma explicitamente que nada foi perdido, porque é essa a ansiedade real. O vocabulário evita jargão ("sincronizar") em favor de "salvo no aparelho" / "enviado".

**Histórias**: US010, US011, US001.

**Consequência no vocabulário**: o verbo "registrar" nomeia o fluxo inteiro ("registro do dia") e por isso não pode nomear nenhuma ação isolada dentro dele — num app sem botão de salvar, um botão que começa com "Registrar" é lido como "salvar isto aqui". Os controles internos são nomeados pelo assunto, não pelo verbo: o botão que abre a troca de item chama-se **"Alteração do cardápio"**.

## 4. Estados do mapa do dia

**Decisão**: um dia está sempre em exatamente um destes estados, com indicação visual na visão do mês e na tela do dia:

- **Vazio** — sem registro.
- **Parcial (pendente)** — começado e incompleto; é um estado legítimo, não um erro: a merendeira pode adiantar dias e completar depois.
- **Completo** — as três refeições preenchidas (gêneros continuam opcionais).
- **Não letivo** — apenas observação (ex.: conselho de classe).
- **Bloqueado ("no documento")** — incluído em documento gerado; fica somente leitura para a merendeira. O aviso aparece antes da geração (na seleção) e depois dela (na confirmação).

**Por quê**: o registro é flexível por decisão da E2 (transcrever o cardápio adiantando dias é uso esperado), então "parcial" precisa ser um estado de primeira classe. O bloqueio pós-geração dá integridade ao documento oficial já emitido; correção excepcional é assunto da direção.

**Histórias**: US001, US006, US007, US008, US013.

## 5. Tela de registro: uma tela, três cartões expansíveis

**Decisão**: as três refeições ficam numa única tela, como cartões que expandem e recolhem; "dia não letivo" é uma alternância no topo que colapsa o restante e deixa só a observação. Aceitação é escolhida em três botões de um toque (Ótimo / Bom / Ruim), um conjunto por refeição.

**Por quê**: uma tela por refeição triplicaria a navegação de um fluxo que precisa caber na rotina; o cartão recolhido ainda mostra o resumo e o estado de cada refeição. Os três botões avaliam sem digitar nada — rapidez foi critério explícito das usuárias (US004).

**Histórias**: US001, US002, US004, US005, US006.

## 6. Tokens compartilhados entre web e Flutter

**Decisão**: o que atravessa as duas plataformas não é componente de interface, é token: paleta, escala tipográfica, espaçamento, raios de borda e alvo de toque mínimo de 44 px. A paleta parte da identidade visual do logo do MAE: acento azul `#397ba1` (o azul do logo, em tom com contraste AA sobre texto branco), verde de apoio alinhado ao verde do logo e neutros da escala zinc. Na web (E5) os tokens entram no tema do shadcn/ui — com os tamanhos de controle elevados em relação ao padrão da biblioteca (36–40 px), que é de desktop. No Flutter (E6) os mesmos tokens viram `ThemeData`; a biblioteca de UI do app é decidida na E6, conforme a convenção do projeto de não antecipar dependências.

**Por quê**: web e Flutter não compartilham código de componente; compartilhar os valores de design é o que mantém as duas frentes coerentes sem prender uma à outra.

**Cores dos gráficos do painel**: paleta de dados própria, separada do acento da marca — escala de aceitação em azul/cinza/vermelho (positivo → negativo) e ranking em azul de dados único, validada para daltonismo.

**Histórias**: transversal; US017 (gráficos).

## 7. Gênero se escolhe sem sair do registro

**Decisão**: "Adicionar gênero" abre um sheet sobre a tela do dia — busca no catálogo, lista com a unidade padrão de cada item e, no fim da lista, o cadastro de um gênero novo ali mesmo (nome + unidade padrão). Escolhido ou cadastrado o item, o sheet fecha e o gênero entra na refeição já com o stepper em 1. A tela do catálogo não participa desse caminho: ela fica para manutenção, alcançada pelo menu.

**Por quê**: a US009 pede o gênero novo "sem sair do fluxo" (CA#2) e a busca "durante o registro" (RNF#1). Mandar a merendeira para a tela de catálogo no meio de uma refeição é literalmente sair do fluxo: ela perderia o lugar, e o item cadastrado lá não se prenderia sozinho à refeição — teria de voltar e escolher de novo. Cadastrar dentro do sheet transforma o pior caso (o gênero não existe) em dois campos, e mantém a criação de gênero como ato banal, que é a premissa da história: o catálogo é delas, sem depender de ninguém.

**Consequência no modelo (E4)**: o gênero pode nascer junto com o registro da refeição, então a gravação do mapa precisa criar o item de catálogo que ainda não existir, na mesma operação.

**Histórias**: US009, US003.

## 8. Alteração do cardápio aparece no cartão da refeição

**Decisão**: depois de confirmada, a troca fica visível dentro do cartão da refeição — "item previsto → item servido" com o motivo abaixo, tocável para editar —, e o botão ao lado passa a ser "Outra alteração". Antes da primeira troca, o cartão mostra só o botão "Alteração do cardápio".

**Por quê**: a troca e a justificativa são o que sai impresso no documento oficial (US002); se elas não aparecem no cartão, a merendeira não tem como conferir nem corrigir o que vai ser entregue — teria de abrir a tela de alteração no escuro para lembrar o que registrou.

**Histórias**: US002, US007.

## 9. Menu: a porta do que não é fluxo diário

**Decisão**: a Visão do mês ganha um botão de menu no cabeçalho, abrindo uma barra lateral com o que não pertence ao caminho do mapa: **Documentos gerados**, **Gerenciar gêneros**, **Tema escuro** (a entrar na revisão) e **Sair**.

**Por quê**: o fluxo do mapa é curto de propósito e não tem lugar natural para tarefas ocasionais — pendurá-las no meio do registro roubaria espaço do que ela faz todo dia. Sem o menu, essas telas simplesmente não têm de onde ser abertas: o catálogo, tirado do caminho do registro pela decisão 7, ficaria inalcançável. O menu é também onde cabem, sem inchar o fluxo, os itens que ainda vão entrar (o tema escuro).

**Histórias**: requisito de design da E3 (sem história de origem — ver "Telas que não vieram do levantamento" no [fluxo de telas](fluxo-de-telas.md)).

## 10. O documento gerado não vive só na tela 6

**Decisão**: existe uma tela **Documentos gerados**, no menu, listando os documentos ainda dentro da janela de 7 dias, cada um com o período, quantos mapas contém, quando foi gerado, quando sai do ar e a ação de compartilhar de novo. Documentos fora da janela aparecem na lista como indisponíveis, com a nota de que os registros do período continuam guardados.

**Por quê**: hoje a tela 6 é um beco — saindo dela, o arquivo fica inalcançável até expirar. Três situações banais caem nisso: o app fechar durante a folha de compartilhamento do Android, o envio pelo WhatsApp falhar, ou a merendeira só voltar ao aplicativo depois. Como a geração acontece no servidor e depende dos mapas já sincronizados (US011), ela também não pode terminar com a merendeira presa numa tela de espera: o documento pronto precisa de um lugar onde ser encontrado depois.

**Decorrência sobre a geração offline**: gerar exige internet e é o próprio aviso da tela que diz isso. Não vale enfileirar a geração para "quando houver rede" no MVP — o passo seguinte, compartilhar pelo WhatsApp, também precisa de rede, então a fila não compraria nada e custaria estado a mais. Reemissão fora da janela dos 7 dias continua sendo a US018 (pós-MVP).

**Histórias**: US012, US014; requisito de design da E3.
