# Varredura técnica a partir do ensaio

A segunda trava [antes dos testes](plano-de-testes.md#antes-dos-testes)
(#140). O [ensaio geral](plano-de-testes.md#antes-dos-testes) (#139) deixou a
produção com dados, e com dados a varredura enxerga o que só aparece rodando:
os registros do aparelho, do navegador e do Supabase, colhidos no mesmo dia.
A ela se somam os avisos do banco, as dependências, o contraste das cores e os
erros que o código trata sem deixar rastro.

Cada item terminou corrigido ou justificado. Este registro é o insumo da
seção de achados internos do laudo.

## O que o ensaio revelou

O que atrapalhava o uso virou issue no dia em que apareceu, e foi corrigido
antes desta varredura:

| Issue | Achado | Caminho |
|---|---|---|
| #148 | A web publicada não alcançava as Edge Functions (CORS) | corrigido |
| #150 | O mês do aplicativo ignorava os dias que esperavam na fila | corrigido |
| #151 | O registro do dia não tinha as setas de dia anterior e próximo | corrigido |
| #152 | O selo *Reaberto* não aparecia no aplicativo | corrigido |
| #153 | Os selos *Reaberto* e *Preenchido* se espremiam na web | corrigido |
| #154 | As assinaturas do documento se separavam do último dia | corrigido |
| #147 | O Play Protect barrava o APK de desenvolvedor não verificado | conta de desenvolvedor verificada; a atualização pelo app é conferida na 0.1.2 (#155) |

Três achados não atrapalharam o uso e ficaram para cá.

### O APK de 64 MB

As releases 0.1.0 e 0.1.1 levam o código das três arquiteturas que o Flutter
compila. Medido no APK da 0.1.1:

| Arquitetura | Tamanho | Quem usa |
|---|---|---|
| `arm64-v8a` | 21,2 MB | os aparelhos das merendeiras e o de teste |
| `armeabi-v7a` | 18,7 MB | aparelhos com Android de 32 bits |
| `x86_64` | 22,6 MB | emuladores |

É o arquivo que elas baixam pelo WhatsApp e pela atualização do próprio app,
no 4G da escola. **Corrigido:** a Action de release passa a compilar só
`arm64-v8a`, e o APK fica em torno de 23 MB a partir da 0.1.2.

Continua sendo **um** arquivo, e não um por arquitetura (`--split-per-abi`). A
[atualização pelo app](../06-app/versao-minima.md#a-atualização) pega o
`.apk` anexado à release, e a 0.1.1, já instalada nos aparelhos, pega o
primeiro que encontrar. Com três anexos, ela poderia baixar o de outra
arquitetura. O custo de arm64 só: um aparelho com Android de 32 bits não
instala o MAE. Hoje não há nenhum, e se aparecer, a Action volta a compilar
`android-arm,android-arm64` num arquivo só
([release e distribuição](../06-app/release-e-distribuicao.md)).

### A sessão cifrada que o backup devolvia

No primeiro arranque depois de reinstalar o app no aparelho de teste, o
logcat trouxe cerca de cem linhas de `Stored key cannot be decrypted`. O
manifesto não dizia nada sobre backup, e o Auto Backup do Android vem ligado:
ele devolveu as preferências cifradas da sessão, mas não a chave do Keystore
que as abre, porque essa chave nunca sai do aparelho. Não travou nada: a
sessão simplesmente não existia, e ela entrou de novo.

O mesmo backup devolveria o banco local, que é pior. Um banco de outro
momento traz a [fila](../06-app/fila-de-envio-e-convergencia.md) daquela
hora. A nuvem não deixaria a versão velha passar por cima da nova
(`save_meal_map` recusa a edição mais antiga que a gravada), mas a merendeira
veria avisos de conflito de dias que ela não mexeu.

**Corrigido:** `android:allowBackup="false"` no manifesto, mais
[regras de extração](../../app/android/app/src/main/res/xml/data_extraction_rules.xml)
que excluem tudo. Sem elas, o Android 12 em diante ainda copiaria os dados na
transferência para um aparelho novo, que o `allowBackup` não desliga. O que
importa está na nuvem: o aparelho novo, ou o mesmo reinstalado, reconstrói
tudo no primeiro acesso.

### A mensagem que culpou a internet

Cadastrar a merendeira de ensaio pela web falhou com *"Não deu para cadastrar
agora, quase sempre é a internet"*, e a internet estava lá: a causa era o
CORS (#148).

**Justificado, sem mudança.** Para o navegador, uma resposta barrada pelo
CORS é idêntica a uma rede que caiu: o JavaScript recebe o mesmo `TypeError:
Failed to fetch`, sem resposta nenhuma para ler. A web não tem como dizer a
diferença nesse caso. A frase já admite a dúvida ("quase sempre"), e o gesto
que ela pede é o certo nos dois casos: tentar de novo. A causa de verdade
apareceu no console do navegador, que registra o bloqueio de CORS por conta
própria, e foi por ali que o ensaio a achou em minutos. Quando a nuvem
responde com uma recusa explicada, a web já mostra a explicação dela, e não a
frase da internet.

## Os avisos do Supabase

Relidos em 11/10, depois do ensaio. Eram os mesmos 15 de segurança de 04/10,
mais 15 de desempenho. A
[migration](../../supabase/migrations/20261011120000_avisos_do_supabase.sql)
conta o raciocínio de cada um, e um
[teste do banco](../../supabase/tests/avisos-do-supabase.test.sql) impede que
voltem.

| Aviso | Quantos | Caminho |
|---|---|---|
| Função sem `search_path` fixo | 10 | **corrigido**: todas eram `SECURITY INVOKER`, sem ganho de privilégio possível; fixar custa uma linha por função |
| `SECURITY DEFINER` executável sem login | 5 | **corrigido**: o `EXECUTE` vinha de `PUBLIC`; nenhuma vazava dado, porque todas partem de `auth.uid()`, mas agora a recusa não depende só da função |
| `SECURITY DEFINER` executável por quem está logada | 5 | **justificado**: são as funções de que as políticas de acesso, a gravação do dia e a reabertura precisam |
| `auth.uid()` reavaliado linha a linha numa política | 1 | **corrigido**: virou `(select auth.uid())` |
| Chave estrangeira sem índice | 5 | **justificado**: são colunas de autoria (quem enviou, pediu, alterou, reabriu) e o modelo usado no documento. Nenhuma tela filtra por elas, e o índice só ajudaria a apagar a linha apontada, o que não acontece: perfil se desativa, modelo se substitui |
| Mais de uma política permissiva por ação | 6 | **justificado**: é como as regras foram escritas (uma para ler, outra para escrever), e o custo é medido em linhas de uma escola só |
| Índice sem uso | 2 | **justificado**: são os índices da chave estrangeira para o gênero, nos itens da refeição e da alteração do cardápio. Ficam pelo motivo inverso do aviso acima: tirá-los faria o linter avisar da chave sem índice |
| Conexões do Auth em número fixo | 1 | **justificado**: só pesa ao aumentar a instância, o que não está no horizonte |

## Dependências

**Web.** O `npm audit` apontou 16 pacotes vulneráveis (1 crítico, 12 altos, 3
moderados), **todos em ferramentas de desenvolvimento e build**: wrangler e
miniflare (publicação), jsdom e vitest (testes) e a CLI do shadcn/ui. Nenhum
deles vai para o código que o navegador baixa. O `npm audit fix`, sem
mudanças de versão maior, corrigiu 10, inclusive o crítico. Build, testes,
lint e o E2E passaram depois.

Os 7 que sobraram são da CLI do shadcn/ui (`braces`, via `micromatch` e
`fast-glob`, negação de serviço com padrão de busca malformado). **Justificado:**
a única correção que o npm oferece é trocar o shadcn 4 pelo 1.0.0, e o
projeto usa do pacote só a folha de estilos (`shadcn/tailwind.css`). A CLI
roda à mão, quando se acrescenta um componente, e com padrões escritos por
nós.

**Aplicativo.** O `flutter pub outdated` não aponta vulnerabilidade, só 32
pacotes com versão menor mais nova. **Justificado:** ficam travados no
`pubspec.lock` até depois da 0.1.2. Trocar dependência às vésperas da release
é trocar o que o caminho crítico vai conferir no aparelho.

## Contraste

O [tema escuro da web](../05-web/tema-escuro.md#contraste-o-escuro-passa-com-folga)
tinha encontrado três pares do tema claro abaixo do AA, todos vindos da
paleta da fundação. A varredura achou um quarto, o mesmo par num lugar que a
tabela não tinha.

| Par | Antes | Depois | Caminho |
|---|---|---|---|
| Erro sobre o fundo dele | 4,41 | 5,91 | **corrigido**: vermelho de erro de `#dc2626` para `#b91c1c`, na web, no aplicativo e nas telas do desenho |
| Aba ativa da direção | 4,10 | 6,09 | **corrigido**: o texto usa `#2c5f7e`, o que a paleta já previa sobre o fundo azul suave |
| Dia de hoje na visão do mês | 4,40 (web) · 4,10 (app) | 6,53 · 6,09 | **corrigido**: mesma troca, na tela principal da merendeira |
| "Bom" no gráfico do painel | 1,15 | 1,15 | **justificado**: é área de cor, não texto, e o número ao lado carrega a informação |

## Erros tratados sem rastro

A web não tem registro de erro, e o aplicativo tem 15 `catch (_)`. A
pergunta era se isso atrapalhou o diagnóstico no ensaio. **Justificado, sem
mudança: não atrapalhou.** Cada achado do ensaio foi diagnosticado pelo que
já existia: o console e a aba de rede do navegador (#148), o logcat (o
backup, acima), os registros do Supabase e a própria tela.

Os 15 do aplicativo são caminhos de recuo escolhidos, e cada um diz o motivo
ao lado: sem rede, a tela mostra o que está no aparelho; sem preferência
gravada, vale o padrão; o carimbo de último acesso não é passo do caminho. O
único que pode esconder uma causa que ainda vai importar é o da
[atualização pelo app](../../app/lib/version/app_updater.dart). Se ela falhar
na 0.1.2 (#155), a tela diz o que fazer, mas o logcat não diz por quê. Se
isso acontecer, a falha volta para cá.

## De passagem

O APK declara `REQUEST_INSTALL_PACKAGES`, que a atualização pelo app exige
(#113). É o provável motivo de o Play Protect pedir verificação a cada
arquivo novo, mesmo depois de a conta de desenvolvedor ter sido verificada
(#147). **Custo conhecido, e fica:** sem a permissão, não há atualização pelo
app, e a alternativa seria mandar cada versão pelo WhatsApp.
