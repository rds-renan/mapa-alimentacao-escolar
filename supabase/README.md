# supabase/

Projeto físico do MAE: o banco, as políticas de acesso e os baldes de arquivo.
O que está aqui é a implementação do [modelo ER](../docs/04-banco-de-dados/modelo-er.md);
o porquê de cada escolha está nas [decisões de modelagem](../docs/04-banco-de-dados/decisoes-de-modelagem.md).

```
supabase/
├── config.toml     # configuração da CLI
├── functions/      # as Edge Functions, em Deno
├── migrations/     # o schema, em ordem
├── seed.sql        # dados fictícios de desenvolvimento
├── templates/      # os e-mails que o sistema manda, em português
└── tests/          # cenários em pgTAP
```

O código de servidor está em [`functions/`](functions/), com README próprio:
a geração do documento oficial e a limpeza do que venceu. O porquê de cada
escolha ali está na
[geração do documento oficial](../docs/05-web/geracao-do-documento.md).

## Subir o banco na sua máquina

Precisa de Docker e da [CLI do Supabase](https://supabase.com/docs/guides/cli).

```bash
supabase start      # sobe os contêineres
supabase db reset   # recria o banco: migrations em ordem + seed
```

`supabase start` imprime as URLs e chaves locais. O Studio fica em
<http://127.0.0.1:54323>. Para derrubar tudo, `supabase stop`.

## Rodar os testes

```bash
supabase test db
```

Os testes vivem em `tests/`, escritos em [pgTAP](https://pgtap.org/), e correm
contra o banco local com o seed aplicado — os mesmos que a CI roda em todo Pull
Request que toca este diretório
([integração contínua e publicação](../docs/05-web/integracao-continua-e-publicacao.md)). Cada arquivo é uma transação que
termina em `rollback`, então rodar os testes não suja o banco — mas eles contam
com o seed intacto, então o hábito é `supabase db reset` antes.

| Arquivo | O que exercita |
|---|---|
| `gravacao-do-dia.test.sql` | `save_meal_map()`: caminho feliz, reenvio, conflito entre aparelhos, catálogo, recorte por escola, cargas malformadas e o carimbo de última edição |
| `perfis-e-acessos.test.sql` | Quem altera o quê no perfil: a merendeira e o próprio cadastro, o acesso desativado, a direção gerindo acessos e o que nem ela pode |
| `geracao-do-documento.test.sql` | Os três passos da geração: quem pode pedir, o modelo vigente, o dia de outra escola, o bloqueio na publicação e a falha que não bloqueia |

## As migrations

| Arquivo | O que faz |
|---|---|
| `20260907120000_schema_inicial.sql` | Tipos enumerados, as doze tabelas, chaves e restrições |
| `20260907120100_regras_e_auditoria.sql` | Gatilhos do bloqueio, proteção da coluna `locked`, carimbo de última edição e a função de reabertura |
| `20260907120200_rls.sql` | Políticas de acesso por perfil, em todas as tabelas |
| `20260907120300_storage.sql` | Baldes privados do modelo oficial e dos documentos gerados |
| `20260911120000_gravacao_atomica_do_dia.sql` | A gravação do dia inteiro numa operação só, e o carimbo de última edição que ela exige |
| `20260916120000_protecao_do_perfil.sql` | Guarda as colunas do perfil que a política não alcança: papel, acesso, e-mail, escola e identidade |
| `20260919120000_geracao_do_documento.sql` | Os três passos da geração do documento: abrir, publicar bloqueando os mapas, e encerrar em falha |

Migration é imutável depois de aplicada em qualquer ambiente: corrigir é
escrever a próxima, nunca editar a anterior.

## Contas do seed

Todas com a senha `mae-desenvolvimento`, e todas fictícias:

| E-mail | Perfil |
|---|---|
| `direcao@dominio.com.br` | administrador |
| `merendeira1@dominio.com.br` | merendeira |
| `merendeira2@dominio.com.br` | merendeira |

As contas do seed entram com as quatro colunas de token de `auth.users` como
texto vazio, e não nulas: nulo ali derruba o login com um erro que parece de
banco e é do seed — o caso está contado na
[autenticação, sessão e rotas por perfil](../docs/05-web/autenticacao-e-sessao.md).
O e-mail de senha nova não sai para a internet em desenvolvimento: ele cai na
caixa local, em <http://127.0.0.1:54324>.

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
  quem escreve `generated_document` é o servidor, pelas três funções da
  geração — e o `execute` delas é revogado de quem está autenticado.
- **O mapa é bloqueado quando o documento fica disponível**, na mesma transação;
  geração que falha não deixa mapa bloqueado para trás. O contrato está na
  [geração do documento oficial](../docs/05-web/geracao-do-documento.md).
- **Cada escola só enxerga o que é seu**, em todas as tabelas.
- **O dia grava inteiro ou não grava**, por `save_meal_map()`: um mapa por data,
  filhos substituídos pelos enviados, gênero novo criado e gênero já existente
  adotado, e o conflito entre aparelhos decidido pela última edição. É por ela
  que a aplicação escreve o mapa — o contrato está em
  [a gravação do dia](../docs/05-web/gravacao-do-dia.md).

O que fica para a aplicação — dia completo, prevalência da edição mais recente,
consolidação dos gêneros por dia na geração — está listado no
[modelo ER](../docs/04-banco-de-dados/modelo-er.md#o-que-o-banco-garante-e-o-que-fica-para-a-aplicação).
