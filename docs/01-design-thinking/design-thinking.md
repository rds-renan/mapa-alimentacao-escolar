# Design Thinking — Mapa da Alimentação Escolar

> Etapa E1 do projeto. Metodologia escolhida em substituição ao Canvas (opção permitida pelo PIT), por ser centrada no usuário e adequada a um problema já existente e bem delimitado: o preenchimento manual do mapa de alimentação escolar.
>
> Fases cobertas nesta etapa: **Empatia**, **Definição** e **Ideação**. Prototipação é tratada na etapa E3 (UX) e Teste na etapa E7 (testes e laudo de qualidade).

---

## Fase 1 — Empatia

A fase de empatia foi conduzida por entrevista semiestruturada com as duas merendeiras da escola, realizada em 24/08/2026 a partir de roteiro elaborado previamente ([roteiro-de-empatia.md](roteiro-de-empatia.md)). O roteiro foi desenhado para apresentar a ideia do aplicativo apenas no bloco final, evitando que a solução contaminasse os relatos sobre o problema.

Para preservar a identidade das entrevistadas, elas são referidas como Merendeira 1 e Merendeira 2 em toda a documentação.

### Contexto levantado

A escola é de turno integral, com três refeições diárias (lanche da manhã, almoço e lanche da tarde) e número único de refeições por dia, informado pelas professoras via direção. O cardápio oficial é enviado pelo setor de nutrição toda quinta-feira, pelo WhatsApp, para a semana seguinte. As merendeiras anotam o que foi executado em um caderno ao final do dia e, posteriormente, transferem as informações para o documento oficial — hoje preenchido pelo celular, por meio de um improviso: blocos de texto posicionados manualmente sobre o PDF no Adobe Reader. O documento pronto segue por WhatsApp para a secretaria da escola, que imprime e coleta assinaturas (merendeiras e diretora); a diretora entrega mensalmente os mapas em papel na secretaria de educação.

A escola fica no interior do município, sem sinal de operadora, e o Wi-Fi disponível é instável. Por isso, e pela rotina corrida da cozinha, o preenchimento do documento é feito em casa, fora do horário de trabalho.

### Mapa de empatia consolidado


| Quadrante | Síntese                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Diz**   | "Quando ia salvar, excluía uma parte do preenchimento" · "A gente prefere preencher em casa" · "O Wi-Fi da escola é muito ruim, falha toda hora" · "Queria uma forma mais fácil de preencher o mapa" · "E se eles proibirem o uso do app?"                                                                                                                                                                                                                         |
| **Faz**   | Anota no caderno ao final do dia; registra a quantidade do pão direto no cardápio impresso; preenche o mapa em casa, fora do expediente; adaptou o Adobe Reader (PDF comentado) para preencher pelo celular; a mais experiente ensinou o método à colega; revezam mensalmente a responsabilidade do mapa; fotografam alimentos para o setor de nutrição; usam medidas sempre em unidades inteiras e padronizadas por item (ex.: 1 kg de arroz, 1 pote de manteiga) |
| **Pensa** | O mapa é uma obrigação que não pode conter erro; a responsabilidade pelo documento correto é delas — só entregam quando está certo; a ferramenta atual é um improviso frágil; as regras vêm da prefeitura, e uma mudança de cima (como a troca do PDF por DOCX) pode desmontar o jeito delas de trabalhar                                                                                                                                                          |
| **Sente** | Frustração com o aplicativo que fecha sozinho e perde o trabalho; incômodo por levar trabalho para casa — mas o anseio de entregar correto fala mais alto; orgulho da solução própria que padronizou o documento; valorização da apresentação legível e padronizada do documento digitado; receio de uma proibição institucional; segurança na parceria entre as duas                                                                                              |




### Dores e ganhos

**Dores** — perda de preenchimento por instabilidade do app improvisado; posicionamento manual de texto sobre o PDF; processo demorado que invade o tempo em casa; a troca do PDF por DOCX pelo setor de nutrição, que piora o fluxo pelo celular; ausência de sinal de operadora e Wi-Fi precário na escola; cozinha com ambiente impróprio para papel (umidade, sujeira); documentos já extraviados pelo setor de nutrição, exigindo reimpressão.

**Ganhos desejados** — preencher rápido e sem medo de perder o que foi digitado; funcionar sem internet; gerar o documento pronto no padrão oficial; não depender de improviso; enviar vários mapas de uma vez (dias, semana ou mês inteiro), pedido espontâneo das entrevistadas.

---



## Fase 2 — Definição



### Mapa de afinidade

Os achados da entrevista foram agrupados por afinidade em seis temas:

**1. Ferramenta frágil e improvisada**

- App de PDF fecha sozinho e apaga parte do preenchimento
- Posicionar blocos de texto manualmente sobre o PDF é incômodo e lento
- A troca do PDF por DOCX torna o improviso ainda mais custoso
- O método é um "jeitinho" descoberto por uma e replicado pela outra — não há ferramenta oficial

**2. Trabalho invisível e fora de hora**

- A rotina da cozinha é corrida; não há momento tranquilo para preencher
- O mapa é preenchido em casa, fora do expediente
- Preencher às pressas gera erro; por isso preferem o tempo de casa
- O anseio de entregar correto supera o incômodo de levar trabalho para casa

**3. Conectividade e ambiente hostis**

- Sem sinal de operadora (escola no interior do município)
- Wi-Fi da escola instável, falha constantemente
- Ambiente da cozinha impróprio para papel: umidade e sujeira

**4. Fluxo institucional em papel**

- Cadeia longa: caderno → celular → WhatsApp → impressão → assinaturas → entrega física mensal
- O setor de nutrição já extraviou documentos, forçando reimpressão
- Não há histórico digital consultável; o registro final vive no papel

**5. Dependência das decisões da prefeitura**

- O formato do documento muda por decisão externa (PDF → DOCX), sem considerar o fluxo delas
- Receio espontâneo: "e se proibirem o uso do app?"
- A aceitação institucional é condição de sobrevivência de qualquer solução

**6. Dados simples e padronizados**

- Medidas sempre em unidades inteiras e padronizadas por item (nunca frações)
- Número de refeições é único por dia, informado pela direção
- Cardápio oficial semanal como referência; alterações registradas com item e justificativa
- Dias não letivos registrados apenas com observação
- Grau de aceitação avaliado por sobras, reação das crianças e repetições



### Problem statement (ponto de vista)

> **As merendeiras** de uma escola de turno integral **precisam de** uma forma rápida e confiável de registrar diariamente o mapa de alimentação e gerar o documento oficial, **que funcione sem internet e não perca o que foi preenchido**, **porque** o processo atual depende de um improviso instável que consome o tempo delas em casa, e o resultado ainda circula em papel — sujeito a extravio — dentro de um fluxo cujas regras podem mudar a qualquer momento por decisão da prefeitura.



### Perguntas "Como poderíamos..." (insumo para a ideação)

1. Como poderíamos tornar o registro diário tão rápido que caiba na rotina da cozinha, sem invadir o tempo em casa?
2. Como poderíamos garantir que nada do que foi preenchido se perca, mesmo sem internet?
3. Como poderíamos gerar o documento oficial pronto, no padrão exigido, sem trabalho manual de formatação?
4. Como poderíamos permitir o envio de vários mapas de uma vez (semana, mês)?
5. Como poderíamos aproveitar o cardápio oficial da semana como ponto de partida do preenchimento, registrando apenas as alterações?
6. Como poderíamos reduzir o risco de rejeição institucional da solução?

---



## Fase 3 — Ideação

A ideação partiu das seis perguntas "Como poderíamos..." da fase de Definição. Cada funcionalidade candidata responde a pelo menos uma delas (indicada entre colchetes). Em seguida, as ideias foram priorizadas em três faixas — MVP, pós-MVP e fora de escopo — como insumo para o backlog de histórias de usuário (etapa E2).

### Funcionalidades candidatas

**Registro diário guiado** [HMW 1, 5] — o preenchimento do dia parte do cardápio oficial da semana já carregado no app: a merendeira confirma o que foi servido em cada refeição (lanche da manhã, almoço, lanche da tarde) e só edita o que mudou. O caminho feliz vira poucos toques.

**Alteração de cardápio com justificativa** [HMW 5] — ao trocar um item, o app registra o item original, o substituto e o motivo, no mesmo formato que hoje elas escrevem à mão no mapa.

**Quantidades por seleção, não por digitação** [HMW 1] — cada gênero alimentício tem unidade padrão cadastrada (kg de arroz, pote de manteiga, saco de leite em pó) e as quantidades são sempre inteiras, escolhidas por stepper (+/−). Elimina digitação livre e erro de formato — decisão derivada diretamente do achado de que elas nunca usam frações.

**Grau de aceitação em um toque** [HMW 1] — três botões (ótimo/bom/ruim) por refeição.

**Número de refeições único por dia** [HMW 1] — um campo por dia, como no processo real (escola integral, presença informada pela direção).

**Dia não letivo** [HMW 1] — registro simplificado: marca o dia como não letivo e escreve apenas a observação (ex.: conselho de classe).

**Funcionamento 100% offline com salvamento automático** [HMW 2] — todo o preenchimento acontece e persiste no aparelho, salvo automaticamente a cada alteração; nada depende de rede. A sincronização com o servidor ocorre quando houver conexão. Responde à dor mais visceral da entrevista (o app que fecha e perde o trabalho) e à realidade da escola (sem sinal de operadora, Wi-Fi instável).

**Geração do documento oficial** [HMW 3] — o servidor gera o mapa pronto a partir do template oficial da prefeitura, com os dados do período, idêntico ao padrão exigido. A merendeira não formata nada.

**Envio em lote** [HMW 4] — seleção de período (dias avulsos, semana ou mês inteiro) e geração/envio de todos os mapas de uma vez. Pedido espontâneo das entrevistadas.

**Compartilhamento pelo WhatsApp** [HMW 6] — o documento gerado é compartilhado pela folha de compartilhamento do Android direto no WhatsApp, encaixando-se no fluxo institucional existente (secretaria → impressão → assinaturas) em vez de tentar substituí-lo.

**Histórico digital consultável** [HMW 6] — todos os mapas ficam registrados e podem ser reemitidos a qualquer momento, eliminando o risco de retrabalho quando um documento em papel é extraviado (situação já ocorrida).

**Perfil administrador** [HMW 6] — gerencia o template oficial, o cadastro de merendeiras e o cardápio semanal, mantendo o documento final sempre aderente ao padrão vigente da prefeitura.

### Priorização


| Faixa              | Funcionalidades                                                                                                                                                                                                                                                                                               | Critério                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **MVP**            | Registro diário guiado · alteração com justificativa · quantidades por seleção · aceitação em um toque · nº de refeições · dia não letivo · offline com salvamento automático · geração do documento oficial · envio em lote · compartilhamento via WhatsApp · perfil admin (template, merendeiras, cardápio) | Sem isso o app não substitui o improviso atual                                   |
| **Pós-MVP**        | Histórico consultável com reemissão · notificação de cardápio novo da semana · relatórios simples (ex.: aceitação ao longo do mês)                                                                                                                                                                            | Agrega valor, mas o fluxo fecha sem eles                                         |
| **Fora de escopo** | Controle de estoque · envio de fotos ao setor de nutrição · assinatura digital (o fluxo de assinaturas permanece em papel, por exigência institucional)                                                                                                                                                       | Processos vizinhos identificados na entrevista, registrados para não se perderem |


A estratégia de aceitação institucional (HMW 6) atravessa o escopo inteiro: o app **não altera nenhuma etapa do processo da prefeitura** — o documento final é o mesmo, no mesmo padrão, entregue pelo mesmo caminho. Muda apenas *como* ele é produzido. Essa premissa reduz o risco de rejeição apontado pelas próprias merendeiras ("e se proibirem o uso do app?") e entra na análise de riscos do projeto.

### Nome do aplicativo

Candidatos considerados: **Merendas**, **Merenda em Dia**, **Mapa da Merenda**, **MerenDia e MAE**.

**Escolhido: MAE** — sigla de *Mapa da Alimentação Escolar*, o próprio documento que o aplicativo produz. O nome alinha o app ao artefato institucional (profissionalmente direto: o sistema chama-se como o mapa que gera) e carrega uma segunda leitura, "mãe", que remete ao cuidado com a alimentação das crianças — essência do trabalho das merendeiras. Verificação em 26/08/2026 não encontrou sistema com esse nome no domínio de alimentação escolar. 

---

