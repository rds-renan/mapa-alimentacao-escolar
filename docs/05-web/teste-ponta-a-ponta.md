# O teste de ponta a ponta do caminho crítico

É um teste só, e ele atravessa o sistema inteiro. A merendeira entra, abre um
dia vazio, registra as três refeições, escolhe um gênero, informa o número de
refeições, espera o dia subir, seleciona o mapa, gera o documento oficial e
baixa o arquivo — que o teste **abre e confere por dentro**. Ao fim, o dia que
ela registrou está bloqueado, como a regra manda.

É a [decisão 11](decisoes-tecnicas.md) cumprida, e a última issue da E5 a
fechar. Ele existe para provar que o caminho fecha, e vira evidência direta no
laudo de qualidade da E7.

O código está em [`web/e2e/`](../../web/e2e/) e roda com `npm run test:e2e`.

## Por que um só, e por que este

Os testes que o projeto já tinha são baratos e específicos: cada um fica de um
lado só de uma fronteira. Os de unidade e de componente cobrem a fila, a
convergência e as regras de estado do mapa contra um Supabase de mentira; os
cenários em pgTAP cobrem as políticas de acesso e a gravação atômica do dia
contra o banco, sem tela; os testes das Edge Functions cobrem o preenchimento
do modelo, sem rede. Nenhum deles vê as peças juntas.

E as fronteiras entre elas são sete: o navegador, a sessão, a fila de envio, a
`save_meal_map`, as políticas de RLS, a Edge Function que preenche o modelo e o
balde privado de onde o arquivo sai assinado. **O que este teste prova é que
elas se encaixam** — e é só isso que ele prova. Multiplicar casos aqui custaria
minutos de integração contínua para cobrir de novo o que já está coberto mais
perto do defeito, e cada caso a mais seria uma chance a mais de o teste falhar
por motivo que não é o produto.

**Ele também não é teste de uso.** Isso é a E7, com merendeira de verdade na
frente do produto, e revela problema que nenhuma asserção alcança. As duas
coisas não se substituem, e nenhuma delas cobre o que a outra cobre: a E7 não
pega regressão, e este teste não pega desconforto.

## O caminho, passo a passo

Cada passo é um `test.step` com nome em português, e é assim de propósito:
quando ele falhar, a primeira coisa que o relatório diz é **em que passo o
caminho quebrou**, antes de dizer qual asserção caiu.

| Passo | O que exercita |
|---|---|
| entra com a conta da merendeira | login, sessão, perfil e a rota por papel |
| abre o dia, que está vazio | a visão do mês lida do servidor, e o estado derivado de cada dia |
| registra as três refeições e o número do dia | o autosave a cada tecla, sem botão de salvar |
| anota um gênero nos gêneros do almoço | a folha de escolha e o catálogo lido do servidor |
| o dia sobe sozinho | a fila, a `save_meal_map` e a faixa que diz que chegou |
| o mês passa a mostrar o dia como preenchido | o cache do servidor sabendo que a fila confirmou |
| escolhe o mapa do dia | a régua da seleção: só entra dia completo e já enviado |
| confirma e gera o documento | a confirmação, a Edge Function, o Storage e o link assinado |
| baixa o arquivo e confere o que está dentro | o download e o conteúdo do `.docx` |
| o dia ficou bloqueado | a consequência irreversível da geração |

### O arquivo é aberto, e não só recebido

O último passo é o que separa "o documento saiu" de "o documento é o que ela
registrou". Um `.docx` é um zip, e o corpo dele é uma entrada só — então
[`e2e/docx.ts`](../../web/e2e/docx.ts) percorre os cabeçalhos do pacote,
descomprime `word/document.xml` e devolve o texto. O teste confere ali a data
do dia, as três descrições que digitou, o número de refeições, o gênero com a
unidade do catálogo e o `(X)` marcado na aceitação certa.

São vinte linhas e nenhuma dependência nova. Sem elas, o teste aceitaria um
arquivo vazio de aparência correta — que é exatamente o modo de falhar que a
[geração do documento](geracao-do-documento.md) mais teme, porque é o que chega
à prefeitura sem ninguém perceber.

## Contra o que ele roda

Contra o **Supabase local**, o mesmo que `supabase start` sobe e que a
integração contínua levanta no runner, recriado das migrations com o seed
fictício. Nunca contra o projeto na nuvem: apontá-lo para um ambiente com dado
real seria gravar mapa de mentira num lugar de verdade, e o endereço e as
chaves saem de `supabase status`, não de um arquivo.

E contra a aplicação **construída**, servida do `dist/` pelo `vite preview` —
não contra o servidor de desenvolvimento. O que interessa provar é o que vai ao
ar. Num celular, e não num desktop: o perfil do Playwright é um Pixel 7, que é
a largura em que botão se esconde atrás de rolagem.

### As duas coisas que a preparação faz

O `globalSetup` em [`e2e/preparacao.ts`](../../web/e2e/preparacao.ts) cuida do
que não é papel da merendeira — e por isso não passa pela tela.

**O modelo oficial no balde.** O seed registra a linha do modelo, mas um
arquivo não cabe num `.sql`; e o modelo de verdade não entra no repositório,
porque tem brasão, nome da prefeitura e um mapa real preenchido. O que sobe é o
mesmo [modelo de teste](../../supabase/functions/_shared/modelo-de-teste.ts)
que as Edge Functions já usam — construído do zero, com a estrutura do oficial
e nada do que é dele. Reaproveitá-lo é o que impede dois modelos sintéticos
envelhecerem em direções diferentes.

**O dia do teste em branco.** A geração bloqueia o mapa, então a segunda rodada
encontraria o dia da primeira travado e o teste falharia dizendo algo que não é
sobre o caminho. A limpeza é cirúrgica — só o dia que este teste usa e os
documentos que o incluíram — e acontece **antes** da rodada, não depois: assim
o rastro de uma falha continua no banco, para ser aberto no Studio.

É a única parte que usa a chave secreta, e é por isso que ela existe aqui:
apagar mapa bloqueado e escrever no balde do modelo é coisa que as políticas de
acesso negam de propósito a quem está logada. Ela é a chave do Supabase local,
impressa pela CLI e igual em qualquer máquina.

### O dia é o último dia útil do mês em que o teste roda

Não é uma data fixa. O mês que a aplicação abre é o mês de hoje, e um teste
preso a setembro de 2026 passaria a navegar meses atrás de si mesmo em outubro.
E é o **último** dia útil porque o seed ocupa os quatro primeiros dias do mês —
um deles bloqueado —, e o teste precisa de um dia em branco para registrar do
zero.

O mês vai na barra de endereço (`/?mes=2026-09`) para que nem a virada de mês
no meio da rodada mude o que a tela mostra.

## O que ele achou antes de fechar

O teste encontrou um defeito na primeira vez que percorreu o caminho inteiro, e
o defeito é bom o bastante para justificar sozinho o custo dele.

**A merendeira registrava o dia, a faixa dizia "Enviado", ela voltava para o
mês — e o dia aparecia como Vazio.** O dia estava no servidor; o que a tela
mostrava era o cache da consulta do mês, lido antes do registro.

A invalidação existia, mas morava **dentro da tela**: um efeito em `useMonth`
que disparava quando a fila encolhia. Só que a fila confirma o dia com a
merendeira na tela **do dia**, onde `useMonth` não está montado para ouvir.
Voltando ao mês dentro dos trinta segundos de `staleTime`, a consulta era
servida do cache. Passados os trinta segundos ela se corrigia sozinha — então
isto pegava a correção rápida, não o registro demorado, e é o tipo de coisa que
passa despercebida no uso à mão e some do relato como "acho que demorou a
atualizar".

**A correção é de lugar, não de lógica**: o aviso subiu para o `SyncProvider`,
onde a fila vive, e de lá invalida o mês, o dia e o catálogo esteja aberta a
tela que estiver. É a mesma regra que a [decisão 4](decisoes-tecnicas.md) já
enunciava — quem sabe que o servidor mudou é a fila —, aplicada no lugar em que
ela vale. O caso ficou guardado num teste de componente em
[`sync-provider.test.tsx`](../../web/src/local/sync-provider.test.tsx), com o
cliente de consulta **de verdade**, porque é o `staleTime` dele que faz o
defeito existir.

## Na integração contínua

O fluxo é o [`ponta-a-ponta.yml`](../../.github/workflows/ponta-a-ponta.yml), e
ele é separado dos outros três pelo mesmo motivo que eles são separados entre
si: aqui sobe um Supabase de verdade no runner, com Docker, e o filtro de
caminho é quem decide quem paga por isso. Só que este é mais largo — `web/` e
`supabase/` inteiro, funções incluídas —, porque o caminho atravessa os dois.

Os contêineres que sobem são os de que o caminho precisa, e o Edge Runtime é um
deles: é ele que serve a geração do documento. Ficam de fora o Studio, o
e-mail, a telemetria e o resto.

Quando falha, o relatório do Playwright é guardado como artefato por sete dias
— com o passo que quebrou, o rastro da rede, o vídeo e a captura da tela
naquele instante — e o registro do Edge Runtime é impresso no próprio emprego,
porque a falha da geração chega à tela como uma frase só, de propósito, e o
motivo fica lá dentro. Tudo o que vai no artefato é do ambiente local e
fictício: as contas do seed e a chave publicável que a própria CLI imprime.

**Sem retentativa.** Repetir serve para amansar teste instável, e aqui
esconderia justamente o que este teste existe para mostrar. Instabilidade aqui
é defeito a investigar.

## Rodar na sua máquina

```bash
supabase start            # na raiz do repositório
supabase db reset         # migrations em ordem + seed fictício
cd web && npm run test:e2e
```

O `npm run test:e2e` constrói a aplicação e serve o `dist/` sozinho; na primeira
vez, `npx playwright install chromium` baixa o navegador. Um servidor já aberto
em `localhost:5173` é reaproveitado, o que encurta a volta enquanto se mexe no
teste.

Falhou? `npm run test:e2e:report` abre o relatório, e o rastro traz cada passo
com a tela e a rede daquele instante.

Se o Supabase não estiver de pé, o teste diz isso antes de abrir o navegador —
e diz o comando. Se o seed não estiver aplicado, também: sem ele tudo o que vem
depois falharia por um motivo diferente do verdadeiro.
