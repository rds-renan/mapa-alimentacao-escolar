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

*(em andamento — funcionalidades candidatas e nome do aplicativo)*