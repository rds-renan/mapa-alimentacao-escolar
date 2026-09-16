-- Cenários do perfil e dos acessos: quem altera o quê na tabela `profile`.
--
--   supabase test db
--
-- Roda contra o banco local com o seed aplicado, numa transação que termina em
-- rollback.
--
-- A convenção aqui é diferente da do teste da gravação do dia, e por um motivo:
-- lá o assunto era uma função `security definer`, que decide por `auth.uid()` e
-- não pelo papel do banco. Aqui o assunto **é** o RLS, que só existe para quem
-- não é dono da tabela — então cada bloco troca de papel de verdade
-- (`set local role authenticated`) além de dizer quem está autenticado. Sem a
-- troca de papel, tudo passaria e o teste não provaria nada.

begin;

create extension if not exists pgtap with schema extensions;

select plan(17);

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

create function school_a() returns uuid language sql immutable as
  $fn$ select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid $fn$;
create function school_b() returns uuid language sql immutable as
  $fn$ select 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid $fn$;
create function direcao() returns uuid language sql immutable as
  $fn$ select '11111111-1111-4111-8111-111111111111'::uuid $fn$;
create function merendeira_1() returns uuid language sql immutable as
  $fn$ select '22222222-2222-4222-8222-222222222222'::uuid $fn$;
create function merendeira_2() returns uuid language sql immutable as
  $fn$ select '33333333-3333-4333-8333-333333333333'::uuid $fn$;

create function papel(quem uuid) returns text language sql as
  $fn$ select role::text from public.profile where id = quem $fn$;
create function ativo(quem uuid) returns boolean language sql as
  $fn$ select active from public.profile where id = quem $fn$;

-- Uma segunda escola, para provar que ninguém se muda de universo.
insert into public.school (id, name, city, school_year)
values (school_b(), 'Escola B', 'Município Exemplo', 2026);

-- ---------------------------------------------------------------------------
-- A merendeira e o próprio perfil
-- ---------------------------------------------------------------------------

set local role authenticated;
select act_as(merendeira_1());

select throws_ok(
  $$ update public.profile set role = 'admin' where id = '22222222-2222-4222-8222-222222222222' $$,
  '42501',
  'Só a direção altera perfil, acesso e e-mail.',
  'A merendeira não se promove a direção'
);

select throws_ok(
  $$ update public.profile set school_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' where id = '22222222-2222-4222-8222-222222222222' $$,
  '42501',
  'A identidade e a escola de um perfil não se alteram pelo aplicativo.',
  'A merendeira não se muda de escola'
);

select throws_ok(
  $$ update public.profile set email = 'outra@dominio.com.br' where id = '22222222-2222-4222-8222-222222222222' $$,
  '42501',
  'Só a direção altera perfil, acesso e e-mail.',
  'A merendeira não troca o próprio e-mail, que é a credencial de entrada'
);

-- O que ela PODE: o gatilho não pode ter fechado a porta junto com a janela.
select lives_ok(
  $$ update public.profile set name = 'Merendeira Um' where id = '22222222-2222-4222-8222-222222222222' $$,
  'A merendeira corrige o próprio nome'
);
select is((select name from public.profile where id = merendeira_1()), 'Merendeira Um',
  'E a correção do nome vale mesmo');

select lives_ok(
  $$ update public.profile set last_access = now() where id = '22222222-2222-4222-8222-222222222222' $$,
  'A merendeira carimba o próprio último acesso'
);

-- O perfil da colega não é dela: aqui não há exceção, há linha nenhuma.
update public.profile set name = 'Invadida' where id = merendeira_2();
select is((select name from public.profile where id = merendeira_2()), 'Merendeira 2',
  'A política não deixa a merendeira editar o perfil da colega');

select is(papel(merendeira_1()), 'cook', 'Depois de tudo, ela continua merendeira');

-- ---------------------------------------------------------------------------
-- O acesso desativado não se reativa sozinho
-- ---------------------------------------------------------------------------

reset role;
update public.profile set active = false where id = merendeira_2();

set local role authenticated;
select act_as(merendeira_2());

-- Aqui não é o gatilho que barra, é a própria política: `current_school_id()`
-- só responde para quem está ativo, então o perfil desativado não enxerga nem
-- a si mesmo. É esta invisibilidade que a web lê como "acesso desativado" para
-- encerrar a sessão (CA#2 da US016).
select is((select count(*) from public.profile where id = '33333333-3333-4333-8333-333333333333'),
  0::bigint,
  'O acesso desativado não enxerga nem o próprio perfil');

update public.profile set active = true where id = '33333333-3333-4333-8333-333333333333';

reset role;
select ok(not ativo(merendeira_2()),
  'E por isso não se reativa: a atualização não encontra linha nenhuma');

-- ---------------------------------------------------------------------------
-- A direção, que é quem gere acessos (US016)
-- ---------------------------------------------------------------------------

set local role authenticated;
select act_as(direcao());

select lives_ok(
  $$ update public.profile set active = true where id = '33333333-3333-4333-8333-333333333333' $$,
  'A direção reativa um acesso'
);
select ok(ativo(merendeira_2()), 'E o acesso volta a valer');

select throws_ok(
  $$ update public.profile set role = 'cook' where id = '11111111-1111-4111-8111-111111111111' $$,
  '42501',
  'O próprio perfil e o próprio acesso não se alteram.',
  'A direção não se rebaixa sozinha — seria trancar a gestão para fora'
);

select throws_ok(
  $$ update public.profile set active = false where id = '11111111-1111-4111-8111-111111111111' $$,
  '42501',
  'O próprio perfil e o próprio acesso não se alteram.',
  'Nem se desativa'
);

select throws_ok(
  $$ update public.profile set school_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' where id = '22222222-2222-4222-8222-222222222222' $$,
  '42501',
  'A identidade e a escola de um perfil não se alteram pelo aplicativo.',
  'Nem a direção muda alguém de escola'
);

-- ---------------------------------------------------------------------------
-- O servidor continua podendo o que precisa
-- ---------------------------------------------------------------------------

reset role;

select lives_ok(
  $$ update public.profile set role = 'admin' where id = '22222222-2222-4222-8222-222222222222' $$,
  'O servidor altera o que o aplicativo não altera: é ele quem aplica seed e migrations'
);
select is(papel(merendeira_1()), 'admin', 'E a alteração do servidor vale');

select * from finish();

rollback;
