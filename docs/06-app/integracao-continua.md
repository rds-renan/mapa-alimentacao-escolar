# Integração contínua do aplicativo

O que verifica cada Pull Request que toca `app/`: é a [decisão 13](decisoes-tecnicas.md)
implementada, em [`app.yml`](../../.github/workflows/app.yml), issue #100.

## O que roda

| Passo | O que faz |
|---|---|
| Formatação | `dart format --output=none --set-exit-if-changed .` |
| Análise estática | `flutter analyze` |
| Testes | `flutter test` — unidade e widget, com `flutter_test` |
| Compilação | `flutter build apk --debug` |

O mesmo, na máquina de quem for abrir o Pull Request:

```bash
cd app
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Roda de novo na `main` depois do merge, pelo mesmo motivo da web: o *squash
merge* produz um commit que ninguém verificou ainda.

## Por que debug, e por que não é anexado

O que esta CI prova é que o app **compila** — o equivalente, em Flutter, ao
build da web. Por isso o APK sai em modo debug, assinado com a chave de
depuração que já vem no `build.gradle.kts`: não exige segredo nenhum e é o
suficiente para provar a compilação. Ele não é anexado como artefato do fluxo:
a versão que chega às merendeiras sai só pela release por tag, na issue #112
(decisão 11), com a chave de assinatura de verdade.

## Por que não há ponta a ponta com emulador

A decisão 13 já registra o porquê: um emulador Android na CI é lento, instável
e caro de manter, para provar justamente o que ele imita mal — a rede do
aparelho caindo e voltando, o sistema matando o aplicativo, a folha de
compartilhamento abrindo o WhatsApp. O caminho crítico continua sendo
percorrido à mão, num aparelho de verdade, antes de cada release.

## As versões são fixas

O Flutter está preso a uma versão exata em `app.yml` (não há arquivo de
versão do FVM neste projeto), pelo mesmo motivo do Node na web e da CLI do
Supabase no banco: atualizar é mudar a linha e ver a CI passar, em vez de "a
CI começou a falhar sozinha" num Pull Request que não tem nada a ver com o
assunto. O Gradle do módulo Android exige o JDK 17, que o fluxo instala à
parte — é o que `compileOptions` e `jvmTarget` pedem em
[`android/app/build.gradle.kts`](../../app/android/app/build.gradle.kts).
