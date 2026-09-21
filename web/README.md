# web/

A aplicação web do MAE: Vite com React e TypeScript, Tailwind e shadcn/ui sobre
os tokens da E3, falando direto com o Supabase.

```bash
supabase start          # na raiz do repositório
cp .env.example .env    # e preencha com o que o supabase start imprimiu
npm install
npm run dev
```

O que cada comando faz, o que há dentro de `src/`, quais são os tokens e por que
os controles são maiores que o padrão da biblioteca está em
[`docs/05-web/fundacao-da-web.md`](../docs/05-web/fundacao-da-web.md). O porquê
da stack está nas [decisões técnicas](../docs/05-web/decisoes-tecnicas.md), e o
que cada Pull Request verifica — além de como isto aqui chega ao ar — está na
[integração contínua e publicação](../docs/05-web/integracao-continua-e-publicacao.md).

Antes de abrir o Pull Request, o que a CI vai rodar:

```bash
npm run lint && npm run format:check && npm run typecheck && npm test && npm run build && npm run check:secrets && npm run check:size
```

E o caminho crítico inteiro, num navegador, contra o Supabase local — entrar,
registrar um dia, gerar o documento e conferir o arquivo:

```bash
supabase db reset     # na raiz: migrations em ordem + seed fictício
npm run test:e2e      # na primeira vez, npx playwright install chromium
```

O que ele percorre, o que ele não prova e o defeito que ele achou estão no
[teste de ponta a ponta](../docs/05-web/teste-ponta-a-ponta.md).
