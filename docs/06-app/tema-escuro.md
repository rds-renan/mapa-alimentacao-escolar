# O tema escuro no aplicativo

O par, no aplicativo, do [tema escuro da web](../05-web/tema-escuro.md) (US024,
issue #111). O motivo é o mesmo e vale não repetir: o mapa é preenchido em casa,
muitas vezes à noite, e uma tela branca inteira no escuro é a lanterna que a
história veio apagar. O que segue registra só o que diverge da web.

A paleta escura já estava em `maeDarkTheme` desde a
[fundação](fundacao-do-app.md). Esta issue a **liga**: o controle, onde a
escolha mora e como o aplicativo abre já vestido. O código está em
[`theme_preference.dart`](../../app/lib/theme/theme_preference.dart), no menu
([`app_menu.dart`](../../app/lib/widgets/app_menu.dart)) e na abertura nativa
([`MainActivity.kt`](../../app/android/app/src/main/kotlin/br/dev/rds/mae/MainActivity.kt)).

## Três escolhas, no menu

Claro, Escuro e Sistema, os três à vista no menu da merendeira (tela 2a),
com o rótulo "Tema" e a dica "Em Sistema, acompanha o tema do aparelho." — as
mesmas palavras da web, e o desenho de `design/telas/` já as trazia desde a
#71. O controle é um `SegmentedButton` do Material 3, sem o "✓" da opção
escolhida (`showSelectedIcon: false`), que espremeria "Sistema" na largura do
menu. Quem nunca tocou nele está em "Sistema".

## A escolha mora no aparelho

Em `shared_preferences`, sob a chave `mae.theme` — a mesma porta do
[já visto dos documentos](aviso-de-documento-pronto.md#onde-o-já-visto-mora),
e pela mesma [decisão 12 da E4](../04-banco-de-dados/decisoes-de-modelagem.md):
não vai ao banco. Diferente do já visto, **a chave é uma só, sem perfil**: a
escolha é do aparelho, não da conta. Duas merendeiras no mesmo celular não
disputam a preferência, e sair não a apaga.

Valor ilegível ou armazenamento que falha valem "Sistema"; se a gravação
falhar, a escolha vale até fechar o aplicativo. Uma preferência de cor não
derruba o aplicativo.

## Sem lampejo na abertura

Há dois momentos em que a tela pode aparecer na cor errada, e cada um tem a
sua resposta.

**Antes do primeiro quadro do Flutter.** `main()` lê a escolha **antes** de
`runApp` e a entrega ao `ProviderScope` (`initialThemePreferenceProvider`).
Sem isso o aplicativo abriria no tema do aparelho e trocaria um instante depois.
A leitura é uma ida ao disco de poucos milissegundos, e acontece enquanto a
janela nativa ainda está na tela.

**A janela nativa, antes de o Flutter existir.** O Android veste essa janela
com o tema do *aparelho* (`values-night`), que pode ser o contrário do que ela
escolheu no aplicativo. Por isso o `MainActivity` lê `flutter.mae.theme` direto
do arquivo do `shared_preferences` e, se a escolha for Claro ou Escuro, troca
para `LaunchThemeLight` ou `LaunchThemeDark` **antes de `super.onCreate`**. Em
"Sistema" não faz nada: o tema do aparelho já é o certo. As cores de fundo são
as do `scaffoldBackgroundColor` de cada tema (`#FAFAFA` e `#09090B`), então a
janela nativa e o primeiro quadro do Flutter têm o mesmo fundo.

O acoplamento é explícito nos dois lados: `ThemePreference.stored` avisa que o
Kotlin lê `light` e `dark`, e o Kotlin cita o arquivo Dart.

### O que a abertura não alcança

No Android 12 ou mais novo, a tela de abertura do **sistema** aparece antes de
`onCreate` rodar e segue o tema do aparelho. Quem escolheu, no aplicativo, o
contrário do aparelho pode ver essa primeira tela na cor do aparelho por uma
fração de segundo. O Android não deixa um aplicativo mudar isso por
preferência própria. Quem usa "Sistema", que é o padrão, não é afetada.

## Verificação

[`theme_preference_test.dart`](../../app/test/theme/theme_preference_test.dart)
cobre a regra: as três escolhas, lixo e ausência voltando a "Sistema", a
escolha lida antes do primeiro quadro, e gravar e reler (CA#1). O teste do
menu em [`home_page_test.dart`](../../app/test/pages/home_page_test.dart)
percorre o controle de verdade: escolher Escuro escurece a tela na hora, e
Claro clareia, com a escolha guardada.

O que a suíte não prova é a abertura nativa — janela do Android e Kotlin não
rodam em teste. Essa parte se percorre à mão no aparelho, com o aparelho num
tema e o aplicativo no outro.
