-- Cenários da gestão da direção: o modelo oficial e o último acesso.
--
--   supabase test db
--
-- Mesma convenção do teste dos perfis: as duas funções desta migration são
-- `security invoker`, então quem decide continua sendo o RLS — e RLS só existe
-- para quem não é dono da tabela. Cada bloco troca de papel de verdade
-- (`set local role authenticated`) além de dizer quem está autenticada.

begin;

create extension if not exists pgtap with schema extensions;

select plan(15);

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
create function direcao() returns uuid language sql immutable as
  $fn$ select '11111111-1111-4111-8111-111111111111'::uuid $fn$;
create function merendeira_1() returns uuid language sql immutable as
  $fn$ select '22222222-2222-4222-8222-222222222222'::uuid $fn$;

create function vigentes() returns bigint language sql as
  $fn$ select count(*) from public.document_template
       where school_id = school_a() and is_current $fn$;
create function vigente_nome() returns text language sql as
  $fn$ select file_name from public.document_template
       where school_id = school_a() and is_current $fn$;
create function versoes() returns bigint language sql as
  $fn$ select count(*) from public.document_template where school_id = school_a() $fn$;

create function caminho(arquivo text) returns text language sql immutable as
  $fn$ select school_a()::text || '/' || arquivo $fn$;

-- ---------------------------------------------------------------------------
-- A merendeira não troca o modelo oficial
-- ---------------------------------------------------------------------------

set local role authenticated;
select act_as(merendeira_1());

select throws_ok(
  $$ select public.replace_document_template('outro.docx',
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/outro.docx') $$,
  '42501',
  'Só a direção troca o modelo oficial.',
  'A merendeira não troca o modelo oficial (CA#3 da US015)'
);

select is(versoes(), 1::bigint, 'E nada foi criado na tentativa dela');

-- ---------------------------------------------------------------------------
-- A direção troca, e a troca é uma operação só
-- ---------------------------------------------------------------------------

select act_as(direcao());

select is(vigente_nome(), 'modelo-oficial.docx', 'O modelo do seed é o vigente');

select lives_ok(
  $$ select public.replace_document_template('  modelo-2026.docx  ',
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/d0000002.docx') $$,
  'A direção publica uma versão nova'
);

select is(vigentes(), 1::bigint, 'Continua exatamente um vigente (RN#1 da US015)');
select is(vigente_nome(), 'modelo-2026.docx', 'E o vigente é o que acabou de subir');
select is(versoes(), 2::bigint, 'A versão anterior continua na tabela (decisão 11 da E4)');

select is(
  (select uploaded_by from public.document_template
   where school_id = school_a() and is_current),
  direcao(),
  'A versão nova sai carimbada com quem a enviou'
);

-- ---------------------------------------------------------------------------
-- O que a função recusa
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select public.replace_document_template('   ',
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/vazio.docx') $$,
  '23514',
  'O arquivo do modelo não chegou. Escolha o arquivo e envie de novo.',
  'Nome em branco é recusado'
);

select throws_ok(
  $$ select public.replace_document_template('modelo.docx',
       'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/modelo.docx') $$,
  '23514',
  'O arquivo não foi guardado na pasta desta escola.',
  'Caminho fora da pasta da escola é recusado'
);

select is(vigente_nome(), 'modelo-2026.docx', 'E as recusas não mexeram no vigente');

-- ---------------------------------------------------------------------------
-- O último acesso é a hora do servidor, e é da própria pessoa
-- ---------------------------------------------------------------------------

select act_as(merendeira_1());

select is(
  (select last_access from public.profile where id = merendeira_1()),
  null,
  'Ninguém acessou ainda no seed'
);

select lives_ok(
  $$ select public.touch_last_access() $$,
  'A merendeira carimba o próprio último acesso'
);

select ok(
  (select last_access from public.profile where id = merendeira_1())
    between now() - interval '1 minute' and now(),
  'E o carimbo é a hora do servidor'
);

select is(
  (select last_access from public.profile where id = direcao()),
  null,
  'O carimbo de uma não toca o da outra'
);

select * from finish();

rollback;
