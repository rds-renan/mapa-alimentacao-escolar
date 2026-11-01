# Relato dos testes

> Etapa E7 (refs #180). O que cada testador fez com o MAE, nos campos da
> tabela da faculdade, seguindo o [plano de testes](plano-de-testes.md). Os
> erros que apareceram aqui, e o que foi feito com cada um, estão no
> [laudo de qualidade](laudo-de-qualidade.md).

Os testes rodaram no sistema publicado, com o mapa real das semanas de
outubro de 2026, entre 12/10 e 30/10. As merendeiras começaram na 0.1.3 do
aplicativo e terminaram na 0.1.5, que trouxe as correções pedidas por elas e
foi conferida por elas mesmas.

| Testador | Plataforma | Período |
|---|---|---|
| Merendeira 1 | aplicativo Android | 13/10 a 30/10 |
| Merendeira 2 | aplicativo Android | 12/10 a 30/10 |
| Direção | web | 12/10 e 23/10 |
| Colega | web | 19/10 |

As tarefas (M1 a M11 da merendeira, D1 a D5 da direção) são as do
[roteiro](plano-de-testes.md#o-roteiro). "Não testado" quer dizer que a
tarefa não aconteceu durante o teste. Tudo o que o roteiro pede está
implementado.

## Merendeira 1

**Data do teste:** 13/10/2026 (instalação), 16/10 (primeiro registro),
23/10 (conversa de fechamento) e 30/10 (conferência da 0.1.5).

**O que testou e funcionou**
- M1: instalou o aplicativo pelo arquivo que a Merendeira 2 mandou no
  WhatsApp, sem dificuldade.
- M2: criou a senha e entrou.
- M3 e M4: registrou os dias da semana, com a aceitação, os gêneros usados e
  as quantidades.
- M6: registrou dia sem aula.
- M8: acompanhou pelo mês o que faltava registrar.
- M9 e M10: gerou o documento, mandou no WhatsApp e mandou de novo um
  documento já gerado.
- Na conversa de fechamento disse que não encontrou nada que impedisse o uso.

**O que testou e não funcionou: o que deve ser corrigido**
- Os botões de aceitação vinham na ordem Ótimo, Bom, Ruim; para ela, a ordem
  certa é Ruim, Bom, Ótimo (#177).
- As unidades vinham por extenso (quilo, unidade, pote). Ela prefere "kg" e
  "un", como na nota fiscal dos fornecedores, que é onde as merendeiras
  conferem o que recebem (#175).
- No documento gerado, os gêneros saíam como "Arroz — 3 quilo"; ela pediu a
  quantidade primeiro: "3 kg — Arroz" (#176).
- Ela lançava todos os gêneros do dia numa refeição só, e pediu para
  continuar assim. Lançar por refeição era uma inferência do projeto: o
  documento oficial reúne os gêneros do dia. Os gêneros e a alteração do
  cardápio passaram a ser do dia (#172).

Todos corrigidos na 0.1.4 e na 0.1.5, conferidos por ela em 30/10.

**Funcionalidade não testada**
- M5 (registrar uma troca do cardápio).
- M7 (corrigir um dia já registrado).
- M11 (corrigir um dia reaberto pela direção): o dia reaberto no teste era da
  Merendeira 2.
- Medição de tempo: feita só com a Merendeira 2.

**Observação de método.** O primeiro contato dela não foi acompanhado pelo
projeto, como o plano previa. Foi a Merendeira 2 quem mandou o aplicativo e
explicou o uso, a pedido do autor, para ver se o aplicativo era simples o
bastante para uma merendeira ensinar a outra. Foi: ela instalou e usou sem
intervenção do projeto.

## Merendeira 2

**Data do teste:** 12/10/2026 (instalação e primeiro acesso), uso diário até
23/10 (conversa de fechamento e primeira medição) e 30/10 (conferência da
0.1.5 e segunda medição).

**O que testou e funcionou**
- M1: instalou pelo arquivo recebido no WhatsApp, acompanhada. O Android não
  pediu a verificação do aplicativo que aparecia no ensaio (#147).
- M3 e M4: registrou os dias, com os gêneros e as quantidades.
- M5: registrou uma troca do cardápio, por falta de um item no estoque, com
  os gêneros da troca.
- M6: registrou dia sem aula.
- M7: corrigiu um dia já registrado.
- M8: acompanhou pelo mês o que faltava.
- M9 e M10: gerou o documento, mandou no WhatsApp e mandou de novo.
- M11: corrigiu o dia reaberto pela direção e gerou o documento outra vez.
- Ensinou a Merendeira 1 a instalar e usar o aplicativo, sem ajuda do
  projeto.
- Achou o aplicativo fácil de entender desde o primeiro dia.

**O que testou e não funcionou: o que deve ser corrigido**
- M2: o e-mail de primeiro acesso traz um código de 6 dígitos, mas o
  aplicativo não tinha onde digitá-lo. Ela entrou pelo "Esqueci minha
  senha", que manda outro código (#171, erro).
- O aviso de salvamento no alto do dia aparecia e sumia enquanto ela
  digitava, empurrando a tela para baixo e para cima (#178).
- Para tirar um gênero lançado errado com 120 unidades, teve de baixar a
  quantidade até 1 para o "−" removê-lo (#174).
- Os gêneros eram adicionados um por um; ela pediu para marcar vários na
  lista e adicionar todos de uma vez (#173).
- Perguntou se dava para entrar com a digital. É um pedido novo, que o
  produto não prometia, e ficou como próximo passo (#169).

Os quatro primeiros foram corrigidos na 0.1.4 e na 0.1.5, conferidos por ela
em 30/10.

**Funcionalidade não testada:** nenhuma tarefa do roteiro ficou sem teste.

## Direção

**Data do teste:** 12/10/2026 (abertura do teste das merendeiras) e 23/10
(painel).

**O que testou e funcionou**
- D1: conferiu os dados da escola e enviou o modelo oficial do mapa.
- D2: deu acesso às merendeiras, e achou fácil o acesso e a criação das
  contas.
- D3: acompanhou o mês no painel e achou os gráficos interessantes.

**O que testou e não funcionou: o que deve ser corrigido:** nada foi
apontado.

**Funcionalidade não testada**
- D4 (reabrir um dia já incluído em documento) e D5 (tirar e devolver um
  acesso): o período do teste coincidiu com o Dia das Crianças e com as
  eleições, e o teste não foi estendido. As duas tarefas foram testadas pelo
  Colega.

## Colega

**Data do teste:** 19/10/2026, acompanhado pelo autor.

**O que testou e funcionou**
- D3: acompanhou o mês no painel: aceitação, refeições servidas e merendas
  mais bem aceitas.
- D4: reabriu um dia já incluído em documento, com a justificativa. A
  Merendeira 2 corrigiu esse dia e gerou o documento outra vez (M11).
- D5: tirou o acesso de uma conta e o devolveu.

**O que testou e não funcionou: o que deve ser corrigido:** nenhum erro.
Ele perguntou se a direção poderia ter uma aba com os documentos gerados,
para baixá-los pela web. Hoje os documentos são das merendeiras; é um pedido
novo, e ficou como próximo passo (#170).

**Funcionalidade não testada**
- D1 e D2: a escola, o modelo e os acessos já tinham sido feitos pela
  Direção.
- O fluxo da merendeira não é testado por ele, de propósito: quem não vive a
  rotina da cozinha não sabe o que está registrando
  ([quem testa](plano-de-testes.md#quem-testa)).

## A medição de tempo

O registro de um dia inteiro (as três refeições, a aceitação, os gêneros e o
número de refeições), feito pela Merendeira 2 à mão e no aplicativo, como
descreve o [plano](plano-de-testes.md#a-medição-de-tempo):

| Como | Data | Tempo |
|---|---|---|
| À mão, no processo de antes | 23/10 | 8 min 42 s |
| No aplicativo, 0.1.3 | 23/10 | 3 min 26 s |
| No aplicativo, 0.1.5 | 30/10 | **2 min 50 s** |

Na primeira medição, o aplicativo já levava 61% menos tempo que o papel. A
segunda foi feita depois das correções pedidas por ela, entre elas a seleção
de vários gêneros de uma vez (#173), e caiu mais 36 segundos: 67% menos tempo
que à mão. A merendeira escreve com calma, de propósito, nas duas formas: o
número compara o mesmo ritmo, não uma corrida.

A medição é um dado a mais do projeto, e não um critério do sistema: nenhuma
correção foi feita para baixar o tempo. As correções vieram do que as
testadoras relataram no uso.
