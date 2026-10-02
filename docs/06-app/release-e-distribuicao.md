# Release e distribuição do APK

Como o aplicativo chega às merendeiras: a [decisão 11](decisoes-tecnicas.md)
implementada, issue #112. Uma tag `app-v*` dispara
[`app-release.yml`](../../.github/workflows/app-release.yml), que compila o
APK de produção, assina com a chave de release e cria a release do GitHub com
o arquivo anexado. A primeira instalação é pelo arquivo mandado no WhatsApp;
as seguintes, pelo próprio aplicativo, que busca a release nova — isso é a
trava de versão mínima, na issue #113.

| Critério da issue | Onde está |
|---|---|
| Chave fora do repositório, nos segredos e numa cópia privada | segredos `ANDROID_KEYSTORE_BASE64` e `ANDROID_KEYSTORE_PASSWORD`; a cópia fica com o autor — [A chave de assinatura](#a-chave-de-assinatura) |
| Action que, com a tag, compila, assina e publica | [`app-release.yml`](../../.github/workflows/app-release.yml) — [O que a Action faz](#o-que-a-action-faz) |
| Nome "MAE" e ícone a partir do logo | `android:label` no manifesto; ícone adaptável em `res/mipmap-*` — [O ícone](#o-ícone) |
| `INTERNET` no manifesto principal | [`AndroidManifest.xml`](../../app/android/app/src/main/AndroidManifest.xml) — [A permissão de internet](#a-permissão-de-internet) |
| Versão, tag, release e primeira instalação | [A primeira release](#a-primeira-release) e [A primeira instalação](#a-primeira-instalação) |

## O que é uma release, em uma frase

Uma **tag** é um nome fixo dado a um commit (`app-v0.1.0` aponta para um
commit da `main` e não se move mais). Uma **release** é uma página do GitHub
pendurada numa tag, com notas e arquivos anexados — aqui, o APK. O endereço
`/releases/latest` sempre leva à release mais recente que não é
pré-release, e é dele que o aplicativo vai buscar a atualização (#113).

## A versão

A versão mora num lugar só, a linha `version:` do
[`pubspec.yaml`](../../app/pubspec.yaml), no formato `nome+número`:

- **nome** (`0.1.0`): o que a merendeira vê e o que vai na tag (`app-v0.1.0`).
- **número** (`+1`): o `versionCode` do Android. Ele **tem que subir** a cada
  release: o Android recusa instalar por cima uma versão de número menor. É
  também o número que a trava da #113 tem para comparar.

**Os dois sobem à mão, no mesmo PR**, e a Action confere os dois antes de
compilar: recusa a tag que não bate com o nome (tag `app-v0.2.0` com
`version: 0.1.0+1`) e recusa o número que não cresceu desde a release
anterior (`0.2.0+1` depois de `0.1.0+1`). Esquecer qualquer um dos dois
falha na Action, nunca no aparelho da merendeira.

Qual parte do nome subir:

| Mudou | Exemplo | Sobe |
|---|---|---|
| Só correção, nada novo para ela | `0.1.0+1` → `0.1.1+2` | o último número do nome |
| Algo novo que ela vai ver | `0.1.1+2` → `0.2.0+3` | o do meio, zerando o último |

O número depois do `+` só cresce de um em um, nunca volta, e não tem relação
com o nome.

## Como fazer uma release

1. Num Pull Request, subir a `version:` do pubspec (nome e número) e fazer o
   merge na `main`.
2. Percorrer o caminho crítico à mão no aparelho (decisão 13): entrar,
   registrar um dia sem rede, voltar à rede, ver o dia subir, gerar e
   compartilhar o documento.
3. Criar a tag no commit da `main` e mandar para o GitHub:

   ```bash
   git switch main && git pull
   git tag app-v0.1.0
   git push origin app-v0.1.0
   ```

4. Acompanhar em Actions > "Release do app". Ao terminar, a release aparece
   em Releases com o `mae-0.1.0.apk` anexado.

### Se a Action recusar

A mensagem do erro diz o que faltou ("esperava app-v0.2.0" ou "o número da
versão não cresceu"). A tag errada já está no GitHub e não se move, então o
caminho é apagá-la, corrigir o pubspec por PR e criar a tag de novo:

```bash
git push --delete origin app-v0.2.0   # apaga a tag no GitHub
git tag -d app-v0.2.0                 # e a cópia local
# PR corrigindo a version: do pubspec, merge, e então o passo 3 de novo
```

Como a Action falhou antes de criar a release, não há release para apagar.

### Ensaio

Para ensaiar sem atrapalhar ninguém, uma tag com hífen
(`app-v0.1.0-teste`) vira **pré-release**: aparece na lista, mas fica fora de
`/releases/latest`, então nenhum aplicativo a oferece como atualização.
Depois do ensaio, apagar a release e a tag
(`gh release delete app-v0.1.0-teste --cleanup-tag`).

## O que a Action faz

| Passo | Por quê |
|---|---|
| Confere que a tag está na `main` | cada APK amarrado a um commit que passou por PR e pela CI |
| Confere a tag contra o pubspec | a release não mente sobre a versão que carrega |
| Confere que o número depois do `+` cresceu desde a última tag `app-v*` (sem contar as de ensaio) | o Android recusa atualizar para um número que não cresceu |
| Análise estática e testes | o mesmo Flutter (`3.47.5`) e o mesmo crivo da CI de PR |
| Escreve `env/production.json` | a partir das variáveis do repositório — ver abaixo |
| Escreve a chave e o `key.properties` | a partir dos segredos, fora da pasta do projeto |
| `flutter build apk --release` | o APK de produção |
| Confere o certificado do APK | compara o SHA-256 com o da chave de release e recusa qualquer outro |
| `gh release create --generate-notes` | cria a release, anexa `mae-<versão>.apk` e escreve as notas a partir dos PRs desde a release anterior |

**Variáveis e segredos** (Settings > Secrets and variables > Actions):

| Nome | Tipo | Conteúdo |
|---|---|---|
| `VITE_SUPABASE_URL` | variável | já existia, da web — o mesmo projeto Supabase |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | variável | já existia, da web — a mesma chave publicável |
| `APP_WEB_URL` | variável | `https://mae.rds.dev.br`, com o `https://` — vira o link do e-mail de senha nova |
| `ANDROID_KEYSTORE_BASE64` | segredo | o arquivo da chave em base64 |
| `ANDROID_KEYSTORE_PASSWORD` | segredo | a senha da chave (a mesma para o arquivo e para a chave dentro dele) |

As duas primeiras são reaproveitadas da web de propósito: o aplicativo e a
web falam com o mesmo projeto, e duas cópias do mesmo endereço envelhecem
separadas.

## A chave de assinatura

O Android só aceita instalar uma atualização assinada pela **mesma chave** da
versão instalada. Perder a chave é perder a atualização: a merendeira teria
que desinstalar, e desinstalar apaga o que está no aparelho — inclusive o
que ainda não subiu. Por isso ela existe em dois lugares, e nenhum é o
repositório:

- **Nos segredos do GitHub**, que a Action usa.
- **Numa cópia privada do autor**, fora do GitHub: o arquivo
  `mae-release.jks` e a senha, guardados juntos num gerenciador de senhas ou
  num armazenamento pessoal. Os segredos do GitHub não podem ser lidos de
  volta — se a cópia privada se perder, os segredos não a recuperam.

| Campo | Valor |
|---|---|
| Formato | PKCS12, RSA 4096 |
| Apelido (alias) | `mae` |
| Titular | `CN=Renan de Souza, OU=MAE, C=BR` |
| Validade | até 16/02/2054 |
| SHA-256 do certificado | `A7:71:2F:30:27:EB:2E:80:23:BA:1C:04:40:13:43:C5:E9:29:07:EE:25:15:19:8B:C7:D7:67:A3:3A:13:6A:2F` |

A impressão digital não é segredo — está dentro de todo APK publicado — e é
a que a Action confere.

**Na máquina do autor**, `app/android/key.properties` (ignorado pelo git)
aponta para a cópia privada, e então `flutter build apk --release` assina
com a chave de verdade também localmente:

```properties
storeFile=/caminho/absoluto/para/mae-release.jks
storePassword=…
keyPassword=…
keyAlias=mae
```

Sem esse arquivo, o Gradle assina a release com a chave de depuração, para
que `flutter run --release` funcione em qualquer máquina. Esse APK nunca vira
release: é exatamente o que o passo de conferir o certificado recusa.

## A permissão de internet

O `AndroidManifest.xml` de depuração já declarava `INTERNET` (o Flutter
precisa dela para o *hot reload*), e foi por isso que o app funcionou em
todos os testes até aqui. O APK de release é montado só com o manifesto
principal, que não a declarava, e nenhuma dependência a acrescenta sozinha —
o achado da #103. Sem a correção, o primeiro APK entregue abriria sem acesso
a rede nenhuma. Conferido no APK de release compilado nesta issue:

```text
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
application-label:'MAE'
```

## O ícone

O nome "MAE" já estava no manifesto desde a fundação; o ícone era o padrão do
Flutter. Agora sai do logo, em duas formas:

- **Ícone adaptável** (Android 8 em diante): `mipmap-anydpi-v26/ic_launcher.xml`,
  com o logo em `ic_launcher_foreground.png` e o fundo
  `ic_launcher_background` (`#EAF2F8`, o azul suave do acento). O aparelho
  recorta o ícone com a máscara dele — redonda, quadrada ou o *squircle* da
  Samsung. O logo ocupa 76 dp do quadro de 108 dp: maior que isso, a máscara
  redonda corta a maçã e o garfo; menor, a borda arredondada do próprio logo
  aparece dentro do *squircle*.
- **Ícone simples** (`mipmap-*/ic_launcher.png`): o logo inteiro, para
  aparelhos anteriores ao Android 8.

As imagens saem do arquivo de trabalho do logo, em 2048 px, que fica fora do
repositório — não dos 256 px de `design/telas/logo.png`, porque o quadro
maior do ícone adaptável tem 432 px. Para regerar, com o logo exportado como
`logo-2048.png`:

```bash
magick logo-2048.png -trim +repage -gravity center -background none -extent 2016x2016 logo-sq.png
res=app/android/app/src/main/res
for d in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  n=${d%%:*}; f=${d##*:}
  l=$(python3 -c "print(round(48*$f))")    # ícone simples, 48 dp
  q=$(python3 -c "print(round(108*$f))")   # quadro do adaptável, 108 dp
  z=$(python3 -c "print(round(76*$f))")    # logo dentro do quadro, 76 dp
  magick logo-sq.png -filter Lanczos -resize ${l}x${l} -strip PNG32:$res/mipmap-$n/ic_launcher.png
  magick logo-sq.png -filter Lanczos -resize ${z}x${z} -gravity center -background none \
    -extent ${q}x${q} -strip PNG32:$res/mipmap-$n/ic_launcher_foreground.png
done
```

## A primeira release

| | |
|---|---|
| Versão | `0.1.0+1` (nome `0.1.0`, `versionCode` 1) |
| Tag | `app-v0.1.0` — **ainda não criada** |
| Release | ainda não existe |

A primeira tag sai **depois da #113**, de propósito: a trava de versão mínima
precisa estar no primeiro APK entregue, porque um aplicativo instalado só
respeita a trava que já veio com ele (decisão 12). Esta issue deixa a
esteira pronta e conferida até onde dá sem publicar — o APK de release
compilado localmente, com a chave de release, o certificado batendo com o
que a Action espera e a permissão de internet presente. A tag, a release e o
link entram nesta tabela quando a #113 for feita.

O APK tem 64 MB porque leva o código para as três arquiteturas que o Flutter
compila (`arm64-v8a`, `armeabi-v7a`, `x86_64`). Um arquivo só, que instala em
qualquer aparelho, vale mais aqui do que um arquivo menor por arquitetura,
que obrigaria a escolher qual mandar pelo WhatsApp.

## A primeira instalação

Feita uma vez por aparelho, com o arquivo mandado pelo WhatsApp. Daí em
diante, a atualização vem pelo próprio aplicativo (#113).

1. Baixar o `mae-<versão>.apk` da release (Releases > a versão > Assets) e
   mandar pelo WhatsApp para a merendeira, como **documento**.
2. No celular dela, tocar no arquivo na conversa e em **Abrir**.
3. O Android avisa que, por segurança, o WhatsApp não pode instalar
   aplicativos. Tocar em **Configurações**, ligar **Permitir desta fonte** e
   voltar.
4. Tocar em **Instalar**. Se o Play Protect avisar que não conhece o
   aplicativo, tocar em **Mais detalhes** > **Instalar mesmo assim** — o aviso
   aparece porque o MAE não vem da Play Store, não por haver algo errado com
   ele.
5. Abrir o MAE pelo ícone e entrar com o e-mail e a senha dela.
6. Opcional: em Configurações, desligar de novo o **Permitir desta fonte** do
   WhatsApp.

Os nomes dos botões variam um pouco entre fabricantes e versões do Android;
os passos 3 e 4 são os que mais mudam. Este roteiro é conferido no aparelho
de teste junto da primeira release.

**Quem já tinha a versão de desenvolvimento** instalada pelo `flutter run`
precisa desinstalá-la antes: ela foi assinada pela chave de depuração, e o
Android recusa a atualização assinada por outra chave.
