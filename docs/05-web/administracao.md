# A administração da escola

A direção não participa do mapa. O papel dela é o gerencial que não faz
sentido ficar na carga das merendeiras — quem entra no sistema, com qual
modelo o documento sai e o que aparece no cabeçalho dele — e é isso, e só
isso, que a tela de gestão faz (**US015, US016**).

São as telas 11 e 12 da E3 — Painel e Gestão. O painel gerencial é a issue
#70; esta issue entrega a Gestão e a navegação que leva a elas.

> A direção ganhou um terceiro destino depois desta issue: **Mapas**, a
> reabertura de um dia bloqueado para correção
> ([a reabertura de um mapa](desbloqueio-de-mapa.md), issue #69). Ele não muda
> o que está escrito abaixo — reabrir não é editar o mapa, e o fluxo do
> registro continua sem caminho de ida nem de volta para cá.

O código está em [`web/src/admin/`](../../web/src/admin/) (as consultas, as
mensagens e os três cartões), em
[`web/src/components/admin-shell.tsx`](../../web/src/components/admin-shell.tsx)
(a casca com a barra lateral), em
[`web/src/pages/AdminManagement.tsx`](../../web/src/pages/AdminManagement.tsx)
(a tela) e em
[`supabase/functions/create-access/`](../../supabase/functions/create-access/)
(a Edge Function que cria a conta). No banco, a
[migration da administração](../../supabase/migrations/20260920130000_administracao.sql).

## Dois fluxos, e nenhuma ponte entre eles

A direção tem barra lateral e a merendeira tem menu, e não é diferença de
estilo: são **dois fluxos separados**, não um fluxo com telas a mais. O menu
do aplicativo não tem caminho para a administração (RN#1 da US020), e a
administração não tem caminho para o mapa.

Isso vale como desenho e não como segurança. Quem impede de verdade são as
políticas de RLS da E4: `meal_map_cook_insert` exige o papel de merendeira, e
um endereço digitado à mão não contorna isso —
[a guarda de rota não é a segurança](autenticacao-e-sessao.md#a-guarda-de-rota-não-é-a-segurança).

A barra lateral vira uma faixa de abas no alto quando a tela é estreita.
O desenho da E3 é de computador porque é assim que a direção trabalha, mas a
web abre em qualquer aparelho, e uma coluna de 240 px espremida num celular
não serve a ninguém.

## O acesso nasce na direção, e a senha nasce na merendeira

Não existe autocadastro (CA#3 da US016): o cadastro aberto está desligado no
projeto do Supabase, e o aplicativo só oferece login. A porta de entrada é uma
só, e é esta tela.

Isso tem uma consequência técnica direta: **criar uma conta não é mais um
insert da tela**. A conta começa em `auth.users`, que não é do nosso schema e
que só a chave secreta escreve. Daí a Edge Function `create-access`, a
terceira do projeto, com o mesmo formato das outras duas — valida quem chamou
antes de qualquer escrita, e devolve a mensagem já escrita para quem vai
lê-la.

O caminho, na ordem:

1. a tela manda nome e e-mail; a escola e o papel vêm de quem chamou, no
   servidor;
2. a função confere que quem chamou é uma **direção ativa** desta escola;
3. cria a conta no serviço de autenticação, já com o e-mail confirmado;
4. cria a linha de `profile`, que é o que o aplicativo enxerga;
5. **a tela** dispara o e-mail de criar senha, pela mesma chamada do "Esqueci
   minha senha".

Se o passo 4 falhar, o 3 é desfeito. Uma conta em `auth.users` sem perfil é um
acesso invisível para a direção — ela não aparece em lista nenhuma — e sem
tela nenhuma para quem entrar com ele; e o e-mail ficaria ocupado para sempre.

**A senha não nasce aqui, e a direção nunca sabe a senha de ninguém.** A conta
é criada com uma senha aleatória que não sai da função: não é devolvida, não é
registrada e não chega a e-mail nenhum. Quem define a senha de verdade é a
merendeira, no link que recebe. O CA#1 da US016 fala em "credenciais
iniciais", e esta é a leitura que se escolheu dele: entregar uma senha por
WhatsApp funcionaria, e deixaria a direção sabendo a senha de quem assina os
registros do mapa. Numa escola com duas merendeiras, isso é fácil de evitar e
caro de desfazer.

O e-mail é o mesmo do fluxo de senha esquecida, e de propósito
([a senha esquecida](autenticacao-e-sessao.md#a-senha-esquecida-um-requisito-descoberto-na-codificação)):
uma regra só, num lugar só —
[`web/src/auth/password-email.ts`](../../web/src/auth/password-email.ts).
Mudar o endereço de volta não pode deixar um dos dois para trás.

### Cadastrar e convidar são duas chamadas, e a tela sabe disso

A conta é criada pela função; o e-mail sai da tela, logo em seguida. Duas
chamadas, então é possível a conta existir e o e-mail não sair — o limite de
envio do Supabase é de dois por hora por endereço, por exemplo.

Isso **não é falha do cadastro**, e a tela não trata como se fosse: o acesso
está de pé, e o que falta é o convite. A mensagem diz exatamente isso e aponta
o botão que reenvia, que é o "Redefinir senha" da linha dela.

O mesmo botão serve a merendeira que esqueceu a senha e pede ajuda à direção,
que é o desenho que a E3 já tinha. Ele só aparece para quem tem acesso: mandar
o e-mail a quem está desativada a levaria a criar uma senha que não abre nada.

## Desativar não é apagar

Desativar é `active = false`. A linha de `profile` nunca sai, e não é
economia: a autoria dos mapas, dos documentos gerados e dos desbloqueios que
ela deixou é parte da auditoria
([decisão 2 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)). Não há
política de `delete` em `profile` — nem por engano isso acontece pelo
navegador.

O efeito do desligamento não é da tela, é do banco:
`public.current_school_id()` e `public.current_role_is()` exigem `active`, e
sem escola nenhuma política devolve linha nenhuma. A sessão que ela tiver
aberta cai no primeiro carregamento seguinte — o perfil deixa de aparecer, e
o aplicativo encerra a sessão explicando na tela de login
([o perfil, e o que fazer quando ele não vem](autenticacao-e-sessao.md#o-perfil-e-o-que-fazer-quando-ele-não-vem)).

Reativar é o mesmo caminho de volta, e é por isso que nem desativar nem
reativar pedem confirmação — a única confirmação do produto é a de gerar o
documento, porque o bloqueio dos mapas é que não tem volta
([decisão 11 da E3](../03-ux/decisoes-de-design.md)).

**A direção não aparece na própria lista.** O gatilho
`profile_privileged_change_guard` recusa que ela mexa no próprio papel e no
próprio acesso, porque a escola tem uma direção só e uma direção que se
desativa tranca a gestão para fora do aplicativo, sem caminho de volta por
dentro dele. Mostrar a linha seria oferecer botões que o banco recusa.

## O último acesso

A coluna `profile.last_access` existe desde a E4 e ninguém a escrevia; a
[autenticação](autenticacao-e-sessao.md#o-que-ficou-de-fora-e-onde-continua)
deixou o assunto marcado para cá, que é quem a exibe.

Quem carimba é `public.touch_last_access()`, chamada **a cada abertura do
aplicativo**, logo depois de o perfil chegar. Não no login: a sessão sobrevive
ao navegador (RNF#2 da US016), então a merendeira pode passar meses usando o
aplicativo todo dia sem digitar senha nenhuma — e "último acesso: há três
meses" faria a direção desativar quem está trabalhando.

É uma função do banco, e não um `update` do navegador, porque o valor é a hora
do **servidor**. Enviado pelo cliente, "último acesso" passaria a ser o que o
relógio do aparelho disser — e a camada local já ensinou, na #60, que o
relógio do aparelho anda adiantado com frequência.

## O modelo oficial

O arquivo mora num balde privado e nunca é público (CA#3 da US015, RNF#1 da
US012). Não é zelo genérico: o que está guardado ali é o documento com o
símbolo da prefeitura, e a regra de sigilo do projeto vale para ele
literalmente. Conferido dos dois lados — a direção assina um link e baixa; a
merendeira recebe "objeto não encontrado", porque a política do balde exige o
papel de direção.

Quem lê o modelo para preencher é a Edge Function da geração, no servidor: ele
não passa pelo navegador de ninguém a não ser da direção, e mesmo aí só quando
ela pede para baixar.

**O arquivo é aceito como veio.** Ele é o mesmo documento reeditado semana a
semana por quem não cuida do layout, e a cada volta uma linha se desloca — não
há versão limpa a manter, e não é este sistema que vai normalizá-lo. A
conferência é de extensão e de tamanho, nada além disso; quem sabe se o modelo
serve é a geração, que falha dizendo qual rótulo faltou
([a geração do documento](geracao-do-documento.md)).

### Trocar é uma operação só

"Existe sempre exatamente um modelo vigente" (RN#1 da US015) é um índice único
parcial desde a E4, e é ele que torna a troca indivisível:

- inserir a versão nova antes de baixar a antiga é recusado pelo índice;
- baixar a antiga antes de inserir a nova deixaria a escola **sem modelo** se
  a segunda chamada não chegasse — e sem modelo vigente a geração para de
  funcionar para as duas merendeiras.

Duas chamadas do navegador não têm como ser uma transação só.
`public.replace_document_template()` tem, e é essa a razão de ela existir. Ela
é `security invoker`: quem decide continua sendo a política da tabela, e a
conferência explícita dentro dela é só para a recusa chegar como uma frase que
a direção possa ler.

A ordem na tela é a mesma: sobe o arquivo primeiro, registra depois. Enquanto
o registro não muda, o modelo vigente continua sendo o antigo — uma falha no
meio não deixa a escola sem documento. E o arquivo que sobrou de uma falha é
apagado ali mesmo, porque o que ficaria guardado é documento oficial com
brasão de prefeitura.

**Cada versão é um arquivo próprio**, em `<escola>/<identificador>.docx`, e
não um `modelo.docx` sobrescrito a cada troca. A tabela guarda as versões
anteriores para saber com qual modelo cada documento saiu
([decisão 11 da E4](../04-banco-de-dados/decisoes-de-modelagem.md)), e isso só
vale enquanto o arquivo daquela versão existir.

## Os dados da escola

Três campos — nome, município e ano letivo — e nenhum deles é decoração: eles
entram no cabeçalho de todo documento gerado (CA#2 da US015). São editáveis
porque o formato do documento muda por decisão externa, e absorver essa
mudança aqui é o que mantém o fluxo das merendeiras intocado.

O formulário guarda **o que a direção mudou**, e não uma cópia da linha
inteira. É o que faz uma releitura em segundo plano — o `refetchOnReconnect`,
quando a internet volta — atualizar o que ela não tocou sem apagar o que ela
está digitando.

## O peso do pacote, e a divisão por rota que ele cobrou

Esta tela estourou o teto de 205 kB em gzip que a CI vigia: a `main` já estava
a 1,9 kB dele, e a gestão custa 4,7 kB. Foi o alarme fazendo o que ele existe
para fazer — e a saída foi a que o próprio alarme sugere, dividir.

**As duas rotas da direção carregam sob demanda**, com `lazy()`, e a carga
inicial voltou a 203,5 kB. É parte do que a issue #84 tinha guardado, aplicada
onde ela paga: o fluxo do mapa é diário, feito de celular e numa rede ruim, e
quem o usa nunca abre a administração. Carregar a gestão junto com o login
cobraria de todo dia da merendeira um peso que só a direção usa, de vez em
quando e de computador. A biblioteca de gráficos da #70 já nasce dentro desse
pedaço.

O fluxo da merendeira continua inteiro na carga inicial, de propósito: ali a
espera de um pedaço que falta cairia no meio do trabalho dela.

## O desenho mudou num ponto

O artboard da Gestão mostrava as duas merendeiras ativas, e a reativação —
CA da issue e CA#2 da US016 — não aparecia em lugar nenhum. A segunda linha
passou a mostrar o estado **Sem acesso**, com "Reativar" no lugar do par
"Redefinir senha / Desativar". É o mesmo precedente da #64: quando a
implementação e o desenho divergem, `design/telas/` e os PNGs são atualizados
no mesmo PR.

## Verificação

No banco, com `supabase test db`:

[`administracao.test.sql`](../../supabase/tests/administracao.test.sql) — as
duas funções desta migration, com troca de papel de verdade (`set local role
authenticated`), porque o assunto é RLS e RLS só existe para quem não é dono
da tabela:

| Cenário                                | O que se afirma                                     |
| -------------------------------------- | --------------------------------------------------- |
| A merendeira troca o modelo            | recusado, e nada é criado na tentativa              |
| A direção publica uma versão nova      | um vigente só, e é o que acabou de subir            |
| Depois da troca                        | a versão anterior continua na tabela                |
| O carimbo de quem enviou               | é quem estava autenticada                           |
| Nome em branco, caminho de outra escola| recusados, e o vigente não se mexe                  |
| `touch_last_access`                    | carimba a hora do servidor, e só a própria linha    |

Na web, com `npm test`:

[`administration.test.tsx`](../../web/src/admin/administration.test.tsx) — os
critérios de aceite da issue, um a um:

| Cenário                          | O que se afirma                                        |
| -------------------------------- | ------------------------------------------------------ |
| A lista                          | nome, e-mail, situação e último acesso                 |
| Cadastro                         | cria o acesso e manda o e-mail de criar senha          |
| O e-mail não sai                 | o acesso fica de pé e a tela manda reenviar            |
| E-mail já cadastrado             | a recusa da função chega com a frase que ela escreveu  |
| Desativar                        | a pessoa continua na lista, sem acesso                 |
| Reativar                         | o acesso volta                                         |
| Redefinir senha                  | manda o e-mail; some para quem está desativada         |
| Escrita recusada                 | diz o que houve, sem fingir que passou                 |
| A lista não veio                 | oferece tentar de novo                                 |
| Modelo vigente                   | mostra o arquivo e diz que ele é privado               |
| Envio de versão nova             | sobe na pasta da escola, em arquivo próprio, e vigora  |
| Arquivo que não é `.docx`        | recusado sem chegar ao balde                           |
| Registro recusado após o envio   | o arquivo é apagado e o modelo antigo continua valendo |
| Escola sem modelo                | avisa, porque sem ele não há documento                 |
| Dados da escola                  | salvam; nome em branco não deixa salvar                |
| A navegação da direção           | três destinos, e nenhum deles registra mapa            |
| A merendeira em `/admin/gestao`  | volta para a casa dela                                 |

Ponta a ponta, contra o Supabase local: a criação de acesso foi exercitada com
a direção, com a merendeira (recusada), sem token (recusada), com e-mail
repetido e com e-mail de acesso desativado; o modelo foi trocado pela tela e a
geração do documento seguiu funcionando com a versão nova.
