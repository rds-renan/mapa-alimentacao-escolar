# supabase/functions/

O código de servidor do MAE, em Deno. Duas funções:

| Pasta                | O que faz                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------ |
| `generate-document/` | Gera o documento oficial dos mapas selecionados e devolve o link temporário (US012, US013) |
| `expire-documents/`  | Apaga o arquivo que venceu e encerra a geração que ficou pelo caminho                      |

`_shared/` é o preenchimento do modelo oficial — o que nasceu como spike na issue #58 e
virou código de produção aqui — mais as peças que as duas funções dividem. O `_` no nome
é convenção do Supabase: pasta que começa com ele não vira função.

```
_shared/
  docx.ts               leitura e escrita do pacote OOXML
  preenchimento.ts      o preenchedor: clona o bloco do dia e escreve nele
  dados.ts              o que entra no preenchimento
  dados-ficticios.ts    um mês inventado, com os casos que mexem no layout
  modelo-de-teste.ts    um modelo com a mesma estrutura, sem nada da prefeitura
  gerar-amostra.ts      a linha de comando que gera um documento de amostra
  cliente.ts            o cliente do Supabase com a chave secreta
  resposta.ts           a borda HTTP: JSON, CORS e a tradução de erro do banco
```

**Leia primeiro** a
[geração do documento oficial](../../docs/05-web/geracao-do-documento.md): é lá que está
o porquê de cada escolha — o que o modelo oficial realmente é, por que o gerador o clona
em vez de redesenhá-lo, o contrato da função e como agendar a limpeza. Aqui é só como
rodar.

## Verificar

Os testes não precisam de arquivo nenhum — usam o modelo de teste, e é por isso que
rodam também na integração contínua, no fluxo
[`funcoes.yml`](../../.github/workflows/funcoes.yml):

```bash
deno task verificar     # fmt, lint, tipos e testes
```

## Rodar na sua máquina

Com o Supabase local de pé (`supabase start`):

```bash
supabase functions serve
```

O modelo oficial não está no repositório e o banco local não tem o arquivo — só o
registro, no seed. Para exercitar a geração de ponta a ponta, suba o **modelo de teste**
para o balde, no caminho que o seed declara:

```bash
deno task modelo /tmp/modelo.docx
# e envie /tmp/modelo.docx para document-templates/<id da escola>/modelo-oficial.docx
```

O link que a resposta devolve aponta para `http://kong:8000` em desenvolvimento: é o
endereço do Supabase **por dentro** dos contêineres. Para abrir do seu navegador, troque
por `http://127.0.0.1:54321`. Na nuvem o endereço já é o público.

## Gerar um documento de amostra

Sem servidor nenhum, a partir do modelo de teste:

```bash
deno task modelo /tmp/modelo.docx
deno task amostra --modelo=/tmp/modelo.docx --saida=/tmp/amostra.docx
```

A partir do **modelo oficial** — o que prova a fidelidade —, aponte para o arquivo onde
ele estiver na sua máquina:

```bash
deno task amostra --modelo="../../../_privado/<modelo oficial>.docx" \
  --saida=/tmp/amostra.docx
```

## Publicar

```bash
supabase functions deploy generate-document
supabase functions deploy expire-documents
```

Nenhum segredo a configurar: o runtime injeta o endereço do projeto e a chave secreta.
Publicar o banco, publicar as funções e agendar a limpeza estão, passo a passo, em
[integração contínua e publicação](../../docs/05-web/integracao-continua-e-publicacao.md#publicar-o-banco-e-as-edge-functions).

## Sigilo

Nem o modelo oficial nem o documento gerado entram no repositório: um tem brasão, nome
da prefeitura e um mapa real preenchido; o outro é derivado dele. Gere sempre **fora**
da árvore do projeto, como nos exemplos acima. O `.gitignore` barra `.docx` de propósito
— não contorne com `git add -f`.

O preenchimento também limpa as propriedades do pacote, que no arquivo oficial trazem o
nome de duas pessoas. Isso é comportamento do código, com teste próprio, não cuidado
manual.
