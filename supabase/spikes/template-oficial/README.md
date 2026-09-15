# Spike: preenchimento do template oficial

Protótipo que preenche o modelo oficial do mapa preservando o formato. O que ele
descobriu, por que a abordagem é esta e o que foi descartado no caminho estão na
[geração do documento oficial](../../../docs/05-web/geracao-do-documento.md) — **leia lá
primeiro**; aqui é só como rodar.

Roda em Deno, o mesmo ambiente da Edge Function que vai implementar a US012. Isto é um
spike: não tem autenticação, nem Storage, nem bloqueio de mapa.

```
docx.ts               leitura e escrita do pacote OOXML
preenchimento.ts      o preenchedor: clona o bloco do dia e escreve nele
dados.ts              o que entra (nomes do schema da E4)
dados-ficticios.ts    um mês inventado, com os casos que mexem no layout
modelo-de-teste.ts    um modelo com a mesma estrutura, sem nada da prefeitura
gerar-amostra.ts      a linha de comando
```

## Rodar

Os testes não precisam de arquivo nenhum — usam o modelo de teste:

```bash
deno test --allow-read
```

Para gerar um documento de amostra a partir do modelo de teste:

```bash
deno task modelo /tmp/modelo.docx
deno task amostra --modelo=/tmp/modelo.docx --saida=/tmp/amostra.docx
```

Para gerar a partir do **modelo oficial** — o que prova a fidelidade —, aponte para o
arquivo onde ele estiver na sua máquina:

```bash
deno task amostra --modelo="../../../_privado/<modelo oficial>.docx" \
  --saida=/tmp/amostra.docx
```

## Sigilo

Nem o modelo oficial nem o documento gerado entram no repositório: um tem brasão, nome
da prefeitura e um mapa real preenchido; o outro é derivado dele. Gere sempre **fora**
da árvore do projeto, como nos exemplos acima. O `.gitignore` barra `.docx` de propósito
— não contorne com `git add -f`.

O preenchimento também limpa as propriedades do pacote, que no arquivo oficial trazem o
nome de duas pessoas. Isso é comportamento do código, com teste próprio, não cuidado
manual.
