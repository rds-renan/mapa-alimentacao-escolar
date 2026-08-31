# Backlog priorizado — MAE (Mapa da Alimentação Escolar)

> Etapa E2 do projeto. Backlog de produto no modelo do PIT: cartões de história organizados por tema, com estimativa em pontos (Fibonacci) e prioridade A–E. O detalhamento de cada história (critérios de aceitação, regras de negócio e requisitos não funcionais) está em [historias-de-usuario.md](historias-de-usuario.md).
>
> Critério de prioridade: **A** — sem isso o app não substitui o improviso atual (MVP); **B** — dentro do MVP, mas não condiciona a substituição do improviso (conforto do fluxo, valor gerencial); **C/D** — pós-MVP, agrega valor mas o fluxo fecha sem eles.



## Tema: Registro diário


| ID    | História do usuário                                                                                                                                                          | Estimativa em pontos | Prioridade |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| US001 | Como merendeira, quero registrar o mapa de qualquer dia de forma rápida e no momento que me for conveniente, para que o preenchimento caiba na minha rotina.                 | 5                    | A          |
| US002 | Como merendeira, quero registrar as trocas em relação ao cardápio oficial — item previsto, item servido e motivo — para que o mapa documente a alteração no formato exigido. | 3                    | A          |
| US003 | Como merendeira, quero informar as quantidades dos gêneros em números inteiros na unidade padrão de cada item, para não digitar texto livre nem errar formato.               | 3                    | A          |
| US004 | Como merendeira, quero registrar o grau de aceitação de cada refeição tocando em um de três botões (ótimo, bom ou ruim), para avaliar sem digitar nada.                      | 2                    | A          |
| US005 | Como merendeira, quero informar o número de refeições servidas no dia em um único campo, para refletir o processo real da escola integral.                                   | 1                    | A          |
| US006 | Como merendeira, quero marcar um dia como não letivo registrando apenas uma observação, para documentar o dia sem preencher refeições.                                       | 2                    | A          |
| US007 | Como merendeira, quero editar o registro de qualquer dia enquanto o documento não foi gerado, para entregar o mapa sem erros.                                                | 3                    | A          |
| US008 | Como merendeira, quero ver os dias do mês com a indicação de quais já foram registrados, para saber o que falta antes de gerar o mapa.                                       | 3                    | B          |
| US009 | Como merendeira, quero manter o catálogo de gêneros alimentícios com a unidade padrão de cada um, para que as quantidades registradas sejam sempre consistentes.             | 3                    | A          |




## Tema: Confiabilidade offline


| ID    | História do usuário                                                                                                                                                                    | Estimativa em pontos | Prioridade |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| US010 | Como merendeira, quero preencher o mapa inteiro sem internet e ter cada alteração salva automaticamente, para nunca perder o que já digitei.                                           | 13                   | A          |
| US011 | Como merendeira, quero que os registros feitos offline subam sozinhos para o servidor quando houver conexão, para o mapa ficar disponível para a colega e para a geração do documento. | 8                    | A          |




## Tema: Documento oficial e envio


| ID    | História do usuário                                                                                                                                                                                               | Estimativa em pontos | Prioridade |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| US012 | Como merendeira, quero gerar o mapa pronto no padrão oficial a partir dos registros do período, para não formatar nada manualmente.                                                                               | 13                   | A          |
| US013 | Como merendeira, quero selecionar quais mapas entram no documento — dias avulsos, semana ou o mês inteiro — e gerar um único documento com todos eles, para resolver a prestação de contas mensal em uma ação só. | 5                    | A          |
| US014 | Como merendeira, quero compartilhar o documento gerado direto no WhatsApp pela folha de compartilhamento do Android, para seguir o caminho institucional que já existe.                                           | 2                    | A          |




## Tema: Administração


| ID    | História do usuário                                                                                                                                                                                | Estimativa em pontos | Prioridade |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| US015 | Como administrador, quero gerenciar o template oficial do mapa e os dados institucionais da escola, para que os documentos gerados sigam sempre o padrão vigente da prefeitura.                    | 5                    | A          |
| US016 | Como administrador, quero cadastrar as merendeiras e gerenciar seus acessos, para que apenas pessoas autorizadas registrem o mapa da escola.                                                       | 3                    | A          |
| US017 | Como administrador, quero um painel com o histórico mensal — aceitação das refeições, número de refeições servidas e as merendas mais bem aceitas — para acompanhar a escola sem entrar nos mapas. | 5                    | B          |




## Tema: Pós-MVP


| ID    | História do usuário                                                                                                                                          | Estimativa em pontos | Prioridade |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------- | ---------- |
| US018 | Como merendeira, quero consultar os mapas de períodos passados e reemitir o documento de qualquer um deles, para nunca mais refazer um mapa extraviado.      | 5                    | C          |
| US019 | Como merendeira, quero inserir o cardápio da semana no app e ter os mapas dos dias já preenchidos a partir dele, para apenas editar o que mudou em cada dia. | 8                    | D          |




## Totais


| Prioridade | Histórias | Pontos |
| ---------- | --------- | ------ |
| A          | 15        | 71     |
| B          | 2         | 8      |
| C          | 1         | 5      |
| D          | 1         | 8      |
| **Total**  | **19**    | **92** |




## Fora de escopo (registrado para não se perder)

Processos vizinhos identificados na E1:

- Controle de estoque.
- Envio de fotos ao setor de nutrição.
- Assinatura digital (o fluxo de assinaturas permanece em papel, por exigência institucional).

No MVP, o cardápio oficial permanece um documento externo de referência (recebido pelo WhatsApp), transcrito pela merendeira diretamente para o mapa — sua ingestão pelo app é a US019, pós-MVP.