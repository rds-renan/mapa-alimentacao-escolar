# Backlog priorizado — MAE (Mapa da Alimentação Escolar)

> Etapa E2 do projeto. Backlog de produto no modelo do PIT: cartões de história organizados por tema, com estimativa em pontos (Fibonacci) e prioridade A–E. O detalhamento de cada história (critérios de aceitação, regras de negócio e requisitos não funcionais) está em [historias-de-usuario.md](historias-de-usuario.md).
>
> Critério de prioridade: **A** — sem isso o app não substitui o improviso atual (MVP); **B** — dentro do MVP, mas não condiciona a substituição do improviso (conforto do fluxo, valor gerencial); **C/D** — pós-MVP, agrega valor mas o fluxo fecha sem eles.
>
> **Revisado ao fim da E3**: o desenho das telas revelou cinco requisitos que o levantamento não tinha visto (US020–US024). Eles entraram aqui antes da modelagem de dados, porque dois deles — os documentos gerados e o desbloqueio de mapa — mudam o que o banco precisa guardar. As histórias que não vieram de uma pessoa entrevistada trazem *Equipe de projeto* no campo Requerente.



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
| US020 | Como merendeira, quero um menu com o que não faz parte do registro do dia — documentos gerados, catálogo de gêneros e preferências — para alcançar essas telas sem que atrapalhem o registro. | 2                    | A          |
| US024 | Como merendeira, quero usar o aplicativo em tema escuro, para preencher o mapa à noite em casa sem a tela clara incomodando.                                   | 3                    | A          |




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
| US021 | Como merendeira, quero voltar aos documentos que já gerei enquanto eles ainda existem, para compartilhar de novo sem depender de ter acertado o envio na primeira tentativa.                          | 5                    | A          |




## Tema: Administração


| ID    | História do usuário                                                                                                                                                                                | Estimativa em pontos | Prioridade |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------- |
| US015 | Como administrador, quero gerenciar o template oficial do mapa e os dados institucionais da escola, para que os documentos gerados sigam sempre o padrão vigente da prefeitura.                    | 5                    | A          |
| US016 | Como administrador, quero cadastrar as merendeiras e gerenciar seus acessos, para que apenas pessoas autorizadas registrem o mapa da escola.                                                       | 3                    | A          |
| US017 | Como administrador, quero um painel com o histórico mensal — aceitação das refeições, número de refeições servidas e as merendas mais bem aceitas — para acompanhar a escola sem entrar nos mapas. | 5                    | B          |
| US023 | Como administrador, quero desbloquear um mapa já incluído em documento gerado, registrando a justificativa, para que a merendeira corrija um erro descoberto depois. | 5                    | A          |




## Tema: Pós-MVP


| ID    | História do usuário                                                                                                                                          | Estimativa em pontos | Prioridade |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------- | ---------- |
| US018 | Como merendeira, quero consultar os mapas de períodos passados e reemitir o documento de qualquer um deles, para nunca mais refazer um mapa extraviado.      | 5                    | C          |
| US019 | Como merendeira, quero inserir o cardápio da semana no app e ter os mapas dos dias já preenchidos a partir dele, para apenas editar o que mudou em cada dia. | 8                    | D          |
| US022 | Como administrador, quero ver e baixar os documentos que já foram gerados, para acompanhar as entregas e recuperar um arquivo quando o envio não chegar ao destino. | 3                    | C          |




## Totais


| Prioridade | Histórias | Pontos |
| ---------- | --------- | ------ |
| A          | 19        | 86      |
| B          | 2         | 8       |
| C          | 2         | 8       |
| D          | 1         | 8       |
| **Total**  | **24**    | **110** |




## Fora de escopo (registrado para não se perder)

Processos vizinhos identificados na E1:

- Controle de estoque.
- Envio de fotos ao setor de nutrição.
- Assinatura digital (o fluxo de assinaturas permanece em papel, por exigência institucional).

No MVP, o cardápio oficial permanece um documento externo de referência (recebido pelo WhatsApp), transcrito pela merendeira diretamente para o mapa — sua ingestão pelo app é a US019, pós-MVP.