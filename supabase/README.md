# supabase/

Projeto físico do MAE: o banco, as políticas de acesso e os baldes de arquivo.
O que está aqui é a implementação do [modelo ER](../docs/04-banco-de-dados/modelo-er.md);
o porquê de cada escolha está nas [decisões de modelagem](../docs/04-banco-de-dados/decisoes-de-modelagem.md).

```
supabase/
├── config.toml     # configuração da CLI
├── migrations/     # o schema, em ordem
└── seed.sql        # dados fictícios de desenvolvimento
```

## Subir o banco na sua máquina

Precisa de Docker e da [CLI do Supabase](https://supabase.com/docs/guides/cli).

```bash
supabase start      # sobe os contêineres
supabase db reset   # recria o banco: migrations em ordem + seed
```

`supabase start` imprime as URLs e chaves locais. O Studio fica em
<http://127.0.0.1:54323>. Para derrubar tudo, `supabase stop`.

## As migrations

| Arquivo | O que faz |
|---|---|
| `20260907120000_schema_inicial.sql` | Tipos enumerados, as doze tabelas, chaves e restrições |
| `20260907120100_regras_e_auditoria.sql` | Gatilhos do bloqueio, proteção da coluna `locked`, carimbo de última edição e a função de reabertura |
| `20260907120200_rls.sql` | Políticas de acesso por perfil, em todas as tabelas |
| `20260907120300_storage.sql` | Baldes privados do modelo oficial e dos documentos gerados |

Migration é imutável depois de aplicada em qualquer ambiente: corrigir é
escrever a próxima, nunca editar a anterior.

## Contas do seed

Todas com a senha `mae-desenvolvimento`, e todas fictícias:

| E-mail | Perfil |
|---|---|
| `direcao@dominio.com.br` | administrador |
| `merendeira1@dominio.com.br` | merendeira |
| `merendeira2@dominio.com.br` | merendeira |

O seed traz uma escola, oito gêneros e quatro dias — um completo com alteração
de cardápio, um pendente, um não letivo e um já incluído em documento gerado,
portanto bloqueado. É um de cada estado que a visão do mês mostra.

## Credenciais

Nada de chave no repositório. As chaves locais são impressas pelo
`supabase start` e são as mesmas em qualquer máquina; as do projeto na nuvem
ficam no `.env`, que o `.gitignore` já bloqueia. O modelo está em
[`.env.example`](../.env.example).

## O que o banco garante sozinho

Vale a pena saber antes de escrever a aplicação, para não reimplementar:

- **Um mapa por dia, por escola**, e uma refeição de cada tipo por mapa.
- **Mapa em documento gerado não aceita edição** — nem do mapa, nem das
  refeições, alterações ou gêneros que pendem dele. A mensagem devolvida já é
  a que a pessoa pode ler.
- **A merendeira não escreve na coluna `locked`.** O bloqueio nasce na geração
  e sai por `unlock_meal_map()`, que exige perfil de direção e justificativa, e
  grava o histórico na mesma operação.
- **Nome de gênero é único por escola**, ignorando maiúsculas e espaços
  repetidos; gênero em uso não se apaga, se desativa.
- **Uma única versão vigente do modelo oficial**, por índice parcial.
- **A direção não registra mapa**, e a merendeira não cria documento gerado:
  quem escreve `generated_document` é o servidor.
- **Cada escola só enxerga o que é seu**, em todas as tabelas.

O que fica para a aplicação — dia completo, prevalência da edição mais recente,
consolidação dos gêneros por dia na geração — está listado no
[modelo ER](../docs/04-banco-de-dados/modelo-er.md#o-que-o-banco-garante-e-o-que-fica-para-a-aplicação).
