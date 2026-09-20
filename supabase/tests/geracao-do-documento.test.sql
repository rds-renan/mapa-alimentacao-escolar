-- Cenários da geração do documento: quem pode pedir, o que entra no registro e
-- quando os mapas ficam bloqueados.
--
--   supabase test db
--
-- Roda contra o banco local com o seed aplicado, numa transação que termina em
-- rollback.
--
-- O assunto aqui são as três funções que a Edge Function `generate-document`
-- chama. Elas não são `security definer`: rodam como quem chamou, e quem chama
-- é o servidor. Por isso os blocos alternam entre `service_role` — o papel que
-- a chave secreta assume na API — e `authenticated`, que é quem não pode.

begin;

create extension if not exists pgtap with schema extensions;

select plan(21);

-- ---------------------------------------------------------------------------
-- Apoio
-- ---------------------------------------------------------------------------

create function escola() returns uuid language sql immutable as
  $fn$ select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid $fn$;
create function direcao() returns uuid language sql immutable as
  $fn$ select '11111111-1111-4111-8111-111111111111'::uuid $fn$;
create function merendeira_1() returns uuid language sql immutable as
  $fn$ select '22222222-2222-4222-8222-222222222222'::uuid $fn$;

-- Os quatro dias do seed: completo, pendente, não letivo e já bloqueado.
create function dia_completo() returns uuid language sql immutable as
  $fn$ select 'c0000001-0000-4000-8000-000000000001'::uuid $fn$;
create function dia_pendente() returns uuid language sql immutable as
  $fn$ select 'c0000002-0000-4000-8000-000000000002'::uuid $fn$;
create function dia_bloqueado() returns uuid language sql immutable as
  $fn$ select 'c0000004-0000-4000-8000-000000000004'::uuid $fn$;

create function bloqueado(mapa uuid) returns boolean language sql as
  $fn$ select locked from public.meal_map where id = mapa $fn$;
create function mapas_do_documento(documento uuid) returns bigint language sql as
  $fn$ select count(*) from public.document_meal_map
      where generated_document_id = documento $fn$;

-- Uma segunda escola com um dia próprio, para provar que a seleção não
-- atravessa a fronteira da escola.
insert into public.school (id, name, city, school_year)
values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Escola B', 'Município Exemplo', 2026);
insert into public.meal_map (id, school_id, map_date)
values ('cb000001-0000-4000-8000-000000000001',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '2026-09-01');

-- ---------------------------------------------------------------------------
-- Quem não é o servidor não chama
-- ---------------------------------------------------------------------------

-- O `execute` revogado responde antes de a função rodar, e é de propósito: o
-- guarda de `is_service()` dentro dela é a segunda linha, não a primeira.
set local role authenticated;

select throws_ok(
  format(
    $$ select public.start_document_generation(%L, %L, array[%L]::uuid[]) $$,
    escola(), merendeira_1(), dia_completo()
  ),
  '42501',
  null,
  'A merendeira não abre uma geração por fora do servidor'
);

select throws_ok(
  $$ select public.complete_document_generation(
       '90000001-0000-4000-8000-000000000001', 'qualquer/caminho.docx') $$,
  '42501',
  null,
  'A merendeira não publica um documento por fora do servidor'
);

select throws_ok(
  $$ select public.fail_document_generation('90000001-0000-4000-8000-000000000001') $$,
  '42501',
  null,
  'A merendeira não encerra uma geração por fora do servidor'
);

reset role;

-- ---------------------------------------------------------------------------
-- O pedido: o que a função recusa
-- ---------------------------------------------------------------------------

set local role service_role;

select throws_ok(
  format(
    $$ select public.start_document_generation(%L, %L, array[]::uuid[]) $$,
    escola(), merendeira_1()
  ),
  '23514',
  'Selecione ao menos um dia para gerar o documento.',
  'Seleção vazia não gera documento'
);

select throws_ok(
  format(
    $$ select public.start_document_generation(%L, %L, array[%L]::uuid[]) $$,
    escola(), direcao(), dia_completo()
  ),
  '42501',
  'Só a merendeira gera o documento do mapa.',
  'A direção não gera documento (RN#1 da US022)'
);

select throws_ok(
  format(
    $$ select public.start_document_generation(%L, %L, array[%L]::uuid[]) $$,
    escola(), merendeira_1(), 'cb000001-0000-4000-8000-000000000001'
  ),
  '23514',
  'Algum dia selecionado não existe mais.',
  'Dia de outra escola não entra na seleção'
);

reset role;
update public.profile set active = false where id = merendeira_1();
set local role service_role;

select throws_ok(
  format(
    $$ select public.start_document_generation(%L, %L, array[%L]::uuid[]) $$,
    escola(), merendeira_1(), dia_completo()
  ),
  '42501',
  'Só a merendeira gera o documento do mapa.',
  'Perfil desativado não gera documento'
);

reset role;
update public.profile set active = true where id = merendeira_1();
update public.document_template set is_current = false where school_id = escola();
set local role service_role;

select throws_ok(
  format(
    $$ select public.start_document_generation(%L, %L, array[%L]::uuid[]) $$,
    escola(), merendeira_1(), dia_completo()
  ),
  '23514',
  'A escola ainda não tem um modelo oficial cadastrado.',
  'Sem modelo vigente não há o que preencher (RN#1 da US015)'
);

reset role;
update public.document_template set is_current = true where school_id = escola();
set local role service_role;

-- ---------------------------------------------------------------------------
-- O pedido: o que ele grava
-- ---------------------------------------------------------------------------

create temporary table pedido as
select * from public.start_document_generation(
  escola(), merendeira_1(),
  array[dia_completo(), dia_pendente(), dia_bloqueado(), dia_completo()]
);

select is(
  (select status::text from pedido),
  'processing',
  'A geração nasce em processamento (decisão 10 da E4)'
);

select is(
  (select document_template_id from pedido),
  'd0000001-0000-4000-8000-000000000001'::uuid,
  'A geração registra com qual modelo o documento saiu (decisão 11 da E4)'
);

select is(
  (select mapas_do_documento(id) from pedido),
  3::bigint,
  'A data pedida duas vezes é um dia só no documento'
);

select is(
  bloqueado(dia_completo()),
  false,
  'O pedido não bloqueia nada: o bloqueio é da publicação'
);

select is(
  bloqueado(dia_bloqueado()),
  true,
  'Um dia já bloqueado entra na seleção e continua bloqueado (CA#4 da US023)'
);

-- ---------------------------------------------------------------------------
-- A falha não bloqueia
-- ---------------------------------------------------------------------------

create temporary table falha as
select * from public.fail_document_generation((select id from pedido));

select is(
  (select status::text from falha),
  'failed',
  'A geração que não produziu arquivo fica registrada como falha'
);

select is(
  bloqueado(dia_completo()),
  false,
  'Falha não deixa mapa bloqueado para trás'
);

select throws_ok(
  format(
    $$ select public.fail_document_generation(%L) $$, (select id from pedido)
  ),
  '23514',
  'Esta geração já foi encerrada.',
  'Uma geração encerrada não se encerra de novo'
);

-- ---------------------------------------------------------------------------
-- A publicação bloqueia
-- ---------------------------------------------------------------------------

create temporary table antes as
select updated_at, updated_by from public.meal_map where id = dia_completo();

create temporary table publicado as
select * from public.complete_document_generation(
  (select id from public.start_document_generation(
     escola(), merendeira_1(), array[dia_completo(), dia_pendente()])),
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/documento.docx'
);

select is(
  (select status::text from publicado),
  'available',
  'Publicado o arquivo, a situação passa a disponível'
);

select ok(
  (select expires_at from publicado) between now() + interval '6 days'
                                    and now() + interval '7 days',
  'O arquivo vale sete dias a partir da publicação (RN#2 da US012)'
);

select is(
  bloqueado(dia_completo()) and bloqueado(dia_pendente()),
  true,
  'Os mapas incluídos ficam bloqueados no banco (RN#4 da US012)'
);

select is(
  (select count(*) from public.meal_map m, antes a
   where m.id = dia_completo()
     and m.updated_at = a.updated_at
     and m.updated_by is not distinct from a.updated_by),
  1::bigint,
  'Bloquear não é editar: o carimbo de última edição não se move (CA#3 da US011)'
);

select throws_ok(
  format(
    $$ select public.complete_document_generation(%L, 'outro/caminho.docx') $$,
    (select id from publicado)
  ),
  '23514',
  'Esta geração já foi encerrada.',
  'Um documento publicado não se publica de novo'
);

select * from finish();

rollback;
