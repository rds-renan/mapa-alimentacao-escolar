# A fundação do app

O projeto em [`app/`](../../app/): Flutter só Android, os tokens da E3 no
tema e o cliente do Supabase. É a montagem que a [decisão
1](decisoes-tecnicas.md) descreveu, e o chão de onde saem todas as telas da
etapa — a mesma função que a [fundação da web](../05-web/fundacao-da-web.md)
cumpriu na E5, refs #99.

A ordem importa, pelo mesmo motivo da web: os tokens entram **antes** da
primeira tela porque o alvo de toque de 44 px é o que separa este aplicativo
de uma interface pensada para mouse — se as telas nascessem sobre o padrão do
Material, cada uma delas teria de ser corrigida depois, uma a uma.

## Como rodar

Precisa do Flutter estável com o Android configurado (`flutter doctor`). O
banco local é o mesmo de [`supabase/`](../../supabase/README.md).

```bash
supabase start                              # na raiz do repositório: sobe o banco
cd app
cp env/local.example.json env/local.json    # e preencha com o que o supabase start imprimiu
flutter pub get
flutter run --dart-define-from-file=env/local.json
```

| Comando | O que faz |
|---|---|
| `flutter run --dart-define-from-file=env/local.json` | app em modo de desenvolvimento, num emulador ou aparelho ligado |
| `flutter build apk --dart-define-from-file=env/production.json` | pacote de produção, o mesmo que a release compila (issue #112) |
| `flutter analyze` | análise estática |
| `dart format .` | formatação, escrevendo |
| `dart format --output=none --set-exit-if-changed .` | formatação, só conferindo |
| `flutter test` | os testes, uma vez |

## O que tem dentro

```
app/
├── android/                    # gerado pelo `flutter create`; o pacote é br.dev.rds.mae
├── env/
│   ├── local.example.json      # modelo — o real (local.json) é local, fora do repositório
│   └── production.example.json
├── lib/
│   ├── theme/
│   │   └── theme.dart          # o tema: todos os tokens moram aqui
│   ├── env.dart                # o que o app lê do ambiente
│   ├── supabase.dart           # o cliente, por variáveis de ambiente
│   └── main.dart               # o ponto de entrada
├── test/
│   └── main_test.dart
├── .gitignore
├── analysis_options.yaml       # regras do flutter_lints
└── pubspec.yaml
```

Os arquivos em `lib/` são snake_case, convenção do Dart — diferente do
kebab-case que a web usa em `src/`, porque cada plataforma segue a convenção
da própria linguagem. A primeira coisa que entrou nesta estrutura foi a
mesma que entrou na web: uma tela provisória de conferência dos tokens, que
ocupa o `main.dart` da fundação e sai junto com ela, como está previsto no
fim desta página.

## Os tokens

Todos em [`lib/theme/theme.dart`](../../app/lib/theme/theme.dart), num lugar
só, vindos da [decisão 6 da E3](../03-ux/decisoes-de-design.md) — os mesmos
valores que [`web/src/index.css`](../../web/src/index.css) leva ao
shadcn/ui. Quem muda a aparência do produto mexe nos dois lugares — o valor
atravessa as plataformas, o arquivo não.

| Grupo | O que ficou |
|---|---|
| Acento | `#397ba1`, o azul do logo; `#2c5f7e` no toque e `#eaf2f8` como fundo suave |
| Neutros | escala zinc — fundo `#fafafa`, cartão branco, texto `#09090b`, apoio `#71717a`, borda `#e4e4e7` |
| Semânticos | confirmação `#15803d`, atenção `#a16207`, erro `#dc2626`, cada um com fundo e borda próprios |
| Tipografia | Roboto (padrão do Material); 11, 12, 13, **14 (corpo)**, 16, 17, 22 e 30 px |
| Espaçamento | grade de 4 px, como as telas foram desenhadas |
| Raios | 6, 8, **10** e 12 px — o cartão é 12, o botão e o campo são 8 |
| Alvo de toque | 44 px, na constante `kTouchTarget` |

A tipografia usa o Roboto do Material em vez do Geist da web — é a decisão 3
da E6: o token que atravessa é a escala de tamanhos, não a fonte, e a fonte
padrão do Android é o comportamento que a merendeira já reconhece no
aparelho, sem trazer um pacote de fonte a mais.

**O que o `ThemeData` não tem campo para guardar** — os tons "subtle" (fundo)
e "border" de cada estado semântico, e o toque (hover) do primário — entra em
`MaeColors`, uma `ThemeExtension` própria, lida com
`Theme.of(context).extension<MaeColors>()`. O resto dos tokens (paleta
principal, tipografia) usa os campos que o Material já tem: `ColorScheme` e
`TextTheme`. O espaçamento, os raios e o alvo de toque são constantes no
topo do arquivo (`kSpacingUnit`, `kRadiusMd` etc.) — não variam entre claro e
escuro, então não precisam de extensão.

A **variante escura** (US024) é o mesmo conjunto de tokens com outra paleta,
já em `maeDarkTheme`: o azul do logo clareia para `#7fb3d0`, pelo mesmo
motivo da web — `#397ba1` sobre fundo escuro não alcança o contraste AA — e
passa a levar texto escuro em cima. Por ora o app segue `ThemeMode.system`;
gravar a preferência da usuária é a issue #111, em
[o tema escuro](../05-web/tema-escuro.md) da web, cujo par no app ainda não
tem página própria.

## Os ambientes

Diferente da web, que lê variáveis do Vite em tempo de execução do
navegador, o Flutter compila as suas em tempo de build:
`--dart-define-from-file` injeta um JSON como constantes que `lib/env.dart`
lê com `String.fromEnvironment`. O app falha alto se elas faltarem — o
mesmo princípio do `src/lib/supabase.ts` da web, adaptado ao momento em que
cada plataforma tem a chance de checar.

Os dois ambientes (decisão 2 da E6) são arquivos em [`app/env/`](../../app/env/):

- **`local.json`**: contra o `supabase start`. O modelo já vem com
  `http://10.0.2.2:54321` na URL — **não** `127.0.0.1`: o emulador Android
  roda numa máquina virtual própria, e `10.0.2.2` é o endereço fixo que ela
  usa para alcançar o `localhost` de quem a hospeda. Num aparelho físico na
  mesma rede, o endereço é o IP da máquina de desenvolvimento na rede local,
  não `10.0.2.2`. A chave publicável sai do que `supabase start` imprime,
  como na web.
- **`production.json`**: contra o projeto na nuvem, os mesmos valores que a
  web usa em produção — URL e chave publicável do painel do projeto
  Supabase, em Project Settings > API Keys.

Os dois arquivos reais são locais e ficam fora do repositório — só os
`.example.json` são versionados. É a mesma regra de sigilo do `.env` da web,
adaptada ao formato que o Flutter lê.

**Qual par de chaves o app usa**: o mesmo da web, o formato novo
`sb_publishable_…` — não é JWT, não expira, e quem decide o que ele alcança
é a RLS.

## Testado num aparelho de verdade

Além de `flutter analyze`, `flutter test` e `flutter build apk --debug`, a
tela de conferência de tokens rodou por depuração USB num Samsung A52 —
tamanhos, fonte, cores e bordas corretos nos dois temas, claro e escuro. É a
mesma verificação à mão que a decisão 13 da E6 pede para o caminho crítico, e
que também vale para esta fundação: existe tema até a hora em que alguém
percorre ele, não só compila.

## O que fica de fora desta issue

- **Sessão e login** entram com a autenticação (issue #101); a tela de
  conferência dos tokens sai nesse momento, como a de mesmo papel saiu na
  web.
- **CI** — compilar e testar em todo Pull Request que toca `app/` é a issue
  #100, próxima na ordem de ataque.
