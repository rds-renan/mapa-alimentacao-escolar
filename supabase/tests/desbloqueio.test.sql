-- Cenários da reabertura de mapa (unlock_meal_map, US023).
--
--   supabase test db
--
-- A função é da E4 e nunca havia sido exercitada inteira: o teste da gravação
-- do dia cobre o que ela **não** faz — mover o carimbo de última edição —, e é
-- de propósito que aquelas asserções continuem lá, ao lado da convergência que
-- elas protegem. O que falta é o resto dela, e é o que este arquivo cobre.
--
-- Mesma convenção do teste dos perfis: cada bloco troca de papel de verdade
-- (`set local role authenticated`) além de dizer quem está autenticada. Aqui
-- isso não é zelo — metade do que se afirma é RLS (o histórico que não aceita
-- escrita, a merendeira que volta a escrever no mapa), e RLS só existe para
-- quem não é dono da tabela.

begin;

create extension if not exists pgtap with schema extensions;

select plan(28);

-- ---------------------------------------------------------------------------
-- Apoio
-- ---------------------------------------------------------------------------

create function act_as(actor uuid) returns void language plpgsql as $fn$
begin
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', actor, 'role', 'authenticated')::text,
    true
  );
end;
$fn$;

create function direcao() returns uuid language sql immutable as
  $fn$ select '11111111-1111-4111-8111-111111111111'::uuid $fn$;
create function merendeira_1() returns uuid language sql immutable as
  $fn$ select '22222222-2222-4222-8222-222222222222'::uuid $fn$;

-- O dia 4 de setembro do seed: completo, bloqueado e dentro de um documento
-- gerado. É o caso exato da US023, e é ele que este arquivo reabre.
create function bloqueado() returns uuid language sql immutable as
  $fn$ select 'c0000004-0000-4000-8000-000000000004'::uuid $fn$;
create function documento() returns uuid language sql immutable as
  $fn$ select '90000001-0000-4000-8000-000000000001'::uuid $fn$;
-- O dia 1 de setembro: completo e **não** bloqueado.
create function aberto() returns uuid language sql immutable as
  $fn$ select 'c0000001-0000-4000-8000-000000000001'::uuid $fn$;

create function travado(mapa uuid) returns boolean language sql as
  $fn$ select locked from public.meal_map where id = mapa $fn$;
create function reaberturas(mapa uuid) returns bigint language sql as
  $fn$ select count(*) from public.meal_map_unlock where meal_map_id = mapa $fn$;

-- ---------------------------------------------------------------------------
-- Só a direção reabre (CA#1 e RN#1 da US023)
-- ---------------------------------------------------------------------------

set local role authenticated;
select act_as(merendeira_1());

select throws_ok(
  $$ select public.unlock_meal_map('c0000004-0000-4000-8000-000000000004',
       'Errei o número de refeições.') $$,
  '42501',
  'Só a direção pode reabrir um mapa.',
  'A merendeira não reabre o próprio mapa'
);

select is(travado(bloqueado()), true, 'E o mapa continua bloqueado');
select is(reaberturas(bloqueado()), 0::bigint,
  'A tentativa dela não deixa linha no histórico');

-- A outra metade da RN#1: bloqueado, ela também não edita. É o beco que a
-- US023 existe para abrir, e é o que dá sentido ao resto do arquivo.
select throws_ok(
  $$ update public.meal_map set meals_served = 300
     where id = 'c0000004-0000-4000-8000-000000000004' $$,
  '23514',
  'Este mapa já está em um documento gerado e não pode ser alterado.',
  'Mapa bloqueado não aceita edição da merendeira'
);

-- ---------------------------------------------------------------------------
-- A justificativa é obrigatória (CA#1)
-- ---------------------------------------------------------------------------

select act_as(direcao());

select throws_ok(
  $$ select public.unlock_meal_map('c0000004-0000-4000-8000-000000000004', '') $$,
  '23514',
  'A reabertura precisa de uma justificativa.',
  'Justificativa vazia é recusada'
);

select throws_ok(
  $$ select public.unlock_meal_map('c0000004-0000-4000-8000-000000000004', '   ') $$,
  '23514',
  'A reabertura precisa de uma justificativa.',
  'Justificativa só com espaço também é recusada'
);

select throws_ok(
  $$ select public.unlock_meal_map('c0000004-0000-4000-8000-000000000004', null) $$,
  '23514',
  'A reabertura precisa de uma justificativa.',
  'Justificativa nula também é recusada'
);

select is(travado(bloqueado()), true,
  'Nenhuma das três recusas mexeu no bloqueio');
select is(reaberturas(bloqueado()), 0::bigint,
  'Nem deixou linha no histórico');

-- ---------------------------------------------------------------------------
-- Mapa que não está bloqueado, e mapa que não existe
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select public.unlock_meal_map('c0000001-0000-4000-8000-000000000001',
       'Reabrir o que já está aberto.') $$,
  '23514',
  'Este mapa não está bloqueado.',
  'Não se reabre o que nunca foi fechado'
);

select is(reaberturas(aberto()), 0::bigint,
  'E o histórico não ganha reabertura de mapa que não estava bloqueado');

select throws_ok(
  $$ select public.unlock_meal_map('c0000009-0000-4000-8000-000000000009',
       'Mapa de outra escola, ou nenhum.') $$,
  'P0002',
  'Mapa não encontrado.',
  'Mapa fora do alcance da escola não existe para a direção'
);

-- ---------------------------------------------------------------------------
-- A reabertura, e o que ela guarda (CA#1, CA#3)
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select public.unlock_meal_map('c0000004-0000-4000-8000-000000000004',
       'O número de refeições do dia saiu trocado.') $$,
  'A direção reabre o mapa com justificativa'
);

select is(travado(bloqueado()), false, 'O mapa volta a aceitar edição');
select is(reaberturas(bloqueado()), 1::bigint, 'E a reabertura fica registrada');

select is(
  (select unlocked_by from public.meal_map_unlock where meal_map_id = bloqueado()),
  direcao(),
  'O registro diz quem reabriu');
select is(
  (select reason from public.meal_map_unlock where meal_map_id = bloqueado()),
  'O número de refeições do dia saiu trocado.',
  'E guarda a justificativa como ela foi escrita');
select ok(
  (select unlocked_at from public.meal_map_unlock where meal_map_id = bloqueado())
    between now() - interval '1 minute' and now(),
  'Com a hora do servidor, e não a do aparelho de quem pediu');

-- ---------------------------------------------------------------------------
-- O documento já gerado continua como foi (RN#2 da US023)
-- ---------------------------------------------------------------------------

select is(
  (select status from public.generated_document where id = documento()),
  'available',
  'O documento gerado continua registrado');
select is(
  (select count(*) from public.document_meal_map
   where generated_document_id = documento() and meal_map_id = bloqueado()),
  1::bigint,
  'E continua dizendo que este mapa saiu nele');

-- ---------------------------------------------------------------------------
-- O histórico é permanente (RNF#1 da US023)
-- ---------------------------------------------------------------------------

-- Não há política de insert, update nem delete em meal_map_unlock: a escrita
-- não é recusada com mensagem, ela simplesmente não alcança linha nenhuma.
select throws_ok(
  $$ insert into public.meal_map_unlock (meal_map_id, unlocked_by, reason)
     values ('c0000004-0000-4000-8000-000000000004',
             '11111111-1111-4111-8111-111111111111', 'Reabertura inventada.') $$,
  '42501',
  null,
  'Ninguém insere reabertura pela API — quem grava é a função'
);

-- O delete não levanta erro: sem política que o autorize, ele simplesmente
-- não alcança linha nenhuma — e é essa a diferença que interessa afirmar.
select lives_ok(
  $$ delete from public.meal_map_unlock
     where meal_map_id = 'c0000004-0000-4000-8000-000000000004' $$,
  'Apagar o histórico não dá erro: não encontra linha nenhuma para apagar'
);

select is(reaberturas(bloqueado()), 1::bigint,
  'E a reabertura continua onde estava');

-- ---------------------------------------------------------------------------
-- Reaberto, a merendeira corrige (CA#2)
-- ---------------------------------------------------------------------------

select act_as(merendeira_1());

select lives_ok(
  $$ update public.meal_map set meals_served = 300
     where id = 'c0000004-0000-4000-8000-000000000004' $$,
  'A merendeira volta a editar o mapa reaberto'
);

select is(
  (select meals_served from public.meal_map where id = bloqueado()),
  300::smallint,
  'E a correção dela vale');

select is(
  (select count(*) from public.meal_map_unlock where meal_map_id = bloqueado()),
  1::bigint,
  'A reabertura continua consultável pelas duas (US023, RNF#1)');

-- ---------------------------------------------------------------------------
-- Reabrir de novo é possível, e some nada
-- ---------------------------------------------------------------------------

reset role;
-- O bloqueio é do servidor: nasce na geração do documento.
update public.meal_map set locked = true where id = bloqueado();

set local role authenticated;
select act_as(direcao());

select lives_ok(
  $$ select public.unlock_meal_map('c0000004-0000-4000-8000-000000000004',
       'Segunda correção no mesmo dia.') $$,
  'O mesmo mapa pode ser reaberto mais de uma vez'
);

select is(reaberturas(bloqueado()), 2::bigint,
  'E as duas reaberturas ficam no histórico, na ordem em que aconteceram');

select * from finish();

rollback;
