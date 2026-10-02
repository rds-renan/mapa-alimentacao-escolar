-- Cenários da trava de versão mínima do aplicativo (decisão 12 da E6).
--
--   supabase test db
--
-- Roda contra o banco local com o seed aplicado, numa transação que termina
-- em rollback.
--
-- O cabeçalho que o aplicativo manda chega à função como o PostgREST o
-- entrega, em request.headers; aqui ele é definido do mesmo jeito, por
-- set_config. O caminho de verdade — o cabeçalho atravessando a API e a
-- recusa saindo como HTTP 426 — está registrado em
-- docs/06-app/versao-minima.md.

begin;

create extension if not exists pgtap with schema extensions;

select plan(16);

-- ---------------------------------------------------------------------------
-- Apoio
-- ---------------------------------------------------------------------------

create function act_as(actor uuid) returns void language plpgsql as $fn$
begin
  perform set_config(
    'request.jwt.claims',
    case when actor is null then ''
         else json_build_object('sub', actor, 'role', 'authenticated')::text end,
    true
  );
end;
$fn$;

-- O aplicativo manda o versionCode; a web não manda nada (nulo).
create function app_build(build text) returns void language plpgsql as $fn$
begin
  perform set_config(
    'request.headers',
    case when build is null then '{}'
         else json_build_object('x-mae-app-build', build)::text end,
    true
  );
end;
$fn$;

-- Um dia não letivo é a carga válida mais curta que existe.
create function save_day(day date) returns text language sql as $fn$
  select public.save_meal_map(jsonb_build_object(
    'map_date', day, 'non_school_day', true, 'note', 'Feriado'
  )) ->> 'status'
$fn$;

create function day_exists(day date) returns boolean language sql as $fn$
  select exists (
    select 1 from public.meal_map
    where school_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and map_date = day
  )
$fn$;

create function direcao() returns uuid language sql immutable as
  $fn$ select '11111111-1111-4111-8111-111111111111'::uuid $fn$;
create function merendeira_1() returns uuid language sql immutable as
  $fn$ select '22222222-2222-4222-8222-222222222222'::uuid $fn$;

grant execute on all functions in schema public to authenticated;

-- ---------------------------------------------------------------------------
-- A versão mínima: uma linha, que quem está logado lê e ninguém escreve
-- ---------------------------------------------------------------------------

select results_eq(
  $$ select minimum_build from public.app_version $$,
  array[1],
  'A trava nasce no 1, sem recusar o primeiro APK');

select throws_ok(
  $$ insert into public.app_version (singleton, minimum_build) values (true, 2) $$,
  '23505', null,
  'Não existe segunda linha');

select throws_ok(
  $$ insert into public.app_version (singleton, minimum_build) values (false, 2) $$,
  '23514', null,
  'Nem uma segunda linha com outra chave');

set local role authenticated;
select act_as(merendeira_1());

select results_eq(
  $$ select minimum_build from public.app_version $$,
  array[1],
  'Quem está logado lê a versão mínima');

select throws_ok(
  $$ update public.app_version set minimum_build = 99 $$,
  '42501', null,
  'Quem está logado não sobe o mínimo pela API');

reset role;
set local role anon;

select throws_ok(
  $$ select minimum_build from public.app_version $$,
  '42501', null,
  'Sem sessão, nem a leitura');

reset role;

-- ---------------------------------------------------------------------------
-- A recusa pelo cabeçalho
-- ---------------------------------------------------------------------------

-- O mínimo sobe como subiria por migration — depois de o APK 5 estar
-- publicado.
update public.app_version set minimum_build = 5;

select act_as(merendeira_1());

select app_build('4');
select throws_ok(
  $$ select save_day('2026-03-02') $$,
  'PT426', 'Esta versão do aplicativo está desatualizada.',
  'O aplicativo abaixo do mínimo é recusado');

select ok(not day_exists('2026-03-02'),
  'E nada do que ele mandou foi gravado');

select app_build('5');
select is(save_day('2026-03-02'), 'saved',
  'O aplicativo no mínimo grava');

select app_build('6');
select is(save_day('2026-03-03'), 'saved',
  'O aplicativo acima do mínimo grava');

select app_build(null);
select is(save_day('2026-03-04'), 'saved',
  'A web não manda cabeçalho e segue como está');

select app_build('abc');
select throws_ok(
  $$ select save_day('2026-03-05') $$,
  'PT426', null,
  'Cabeçalho ilegível não vem de aplicativo nenhum que saiu daqui');

select app_build('99999999999999999999');
select throws_ok(
  $$ select save_day('2026-03-05') $$,
  'PT426', null,
  'Nem número grande demais para ser um versionCode');

select app_build(' ');
select is(save_day('2026-03-05'), 'saved',
  'Cabeçalho vazio vale como ausente');

-- A versão vem antes de qualquer outra recusa: um aplicativo velho que
-- recebesse "só a merendeira registra" acharia que o problema é a conta.
select act_as(direcao());
select app_build('4');
select throws_ok(
  $$ select save_day('2026-03-06') $$,
  'PT426', null,
  'A recusa da versão vem antes da recusa do perfil');

select act_as(null);
select throws_ok(
  $$ select save_day('2026-03-06') $$,
  'PT426', null,
  'E antes da falta de sessão');

select * from finish();

rollback;
