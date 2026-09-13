-- Cenários da gravação atômica do dia (save_meal_map).
--
--   supabase test db
--
-- Roda contra o banco local com o seed aplicado. Tudo acontece numa transação
-- que termina em rollback: o banco fica como estava.
--
-- Duas convenções deste arquivo:
--
-- 1. Quem chama é definido só por request.jwt.claims, sem `set role`. É o
--    suficiente e é fiel: save_meal_map é security definer e decide quem pode
--    o quê por auth.uid() e pelo perfil, não pelo papel do banco. O caminho do
--    papel de verdade — o token indo pelo PostgREST — está coberto pelas
--    chamadas à API REST registradas em docs/05-web/gravacao-do-dia.md.
--
-- 2. As cargas ficam numa tabela e são chamadas pelo nome. É o que permite
--    escrever throws_ok() sem aninhar aspas de dólar dentro de aspas de dólar,
--    e de quebra deixa cada teste legível numa linha.

begin;

create extension if not exists pgtap with schema extensions;

select plan(66);

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

create table payload (name text primary key, body jsonb);

create function save(payload_name text) returns jsonb language plpgsql as $fn$
declare
  body jsonb;
begin
  select p.body into strict body from payload p where p.name = payload_name;
  return public.save_meal_map(body);
end;
$fn$;

-- Atalhos para o seed, que é quem dá nome a tudo aqui.
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
create function merendeira_b() returns uuid language sql immutable as
  $fn$ select '44444444-4444-4444-8444-444444444444'::uuid $fn$;

-- Contagens do dia, para não repetir o mesmo join em dez asserções.
create function meals_of(d date, school uuid default null) returns bigint language sql as $fn$
  select count(*) from public.meal m join public.meal_map mm on mm.id = m.meal_map_id
  where mm.map_date = d and (school is null or mm.school_id = school);
$fn$;

create function changes_of(d date) returns bigint language sql as $fn$
  select count(*) from public.menu_change mc
  join public.meal m on m.id = mc.meal_id
  join public.meal_map mm on mm.id = m.meal_map_id
  where mm.map_date = d;
$fn$;

create function food_items_of(d date) returns bigint language sql as $fn$
  select count(*) from public.meal_food_item mfi
  join public.meal m on m.id = mfi.meal_id
  join public.meal_map mm on mm.id = m.meal_map_id
  where mm.map_date = d;
$fn$;

create function catalog_size(school uuid) returns bigint language sql as $fn$
  select count(*) from public.food_item where school_id = school;
$fn$;

-- Uma segunda escola, para provar que nada atravessa.
insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
                        email_confirmed_at, created_at, updated_at,
                        raw_app_meta_data, raw_user_meta_data)
values ('00000000-0000-0000-0000-000000000000', merendeira_b(),
        'authenticated', 'authenticated', 'merendeira-b@dominio.com.br',
        crypt('mae-desenvolvimento', gen_salt('bf')), now(), now(), now(),
        '{"provider":"email","providers":["email"]}', '{}');

insert into public.school (id, name, city, school_year)
values (school_b(), 'Escola B', 'Município Exemplo', 2026);

insert into public.profile (id, school_id, name, email, role)
values (merendeira_b(), school_b(), 'Merendeira B', 'merendeira-b@dominio.com.br', 'cook');

-- ---------------------------------------------------------------------------
-- As cargas
-- ---------------------------------------------------------------------------
-- As datas de EDIÇÃO ficam no passado de propósito: o dia do mapa pode ser
-- futuro, porque a merendeira adianta dias, mas uma edição datada no futuro é
-- reduzida ao instante da chegada e o teste deixaria de provar o que quer.

insert into payload (name, body) values

('dia-completo', $json$
{
  "id": "c0000010-0000-4000-8000-000000000010",
  "map_date": "2026-09-10",
  "updated_at": "2026-09-10T18:30:00-03:00",
  "meals_served": 305,
  "meals": [
    { "id": "e0000010-0000-4000-8000-000000000001",
      "type": "morning_snack", "description": "Pão com manteiga", "acceptance": "great",
      "food_items": [
        { "food_item_id": "f0000007-0000-4000-8000-000000000007", "quantity": 4 },
        { "name": "Achocolatado", "unit": "pote", "quantity": 2 }
      ] },
    { "id": "e0000010-0000-4000-8000-000000000002",
      "type": "lunch", "description": "Arroz, feijão e frango", "acceptance": "good",
      "food_items": [ { "food_item_id": "f0000001-0000-4000-8000-000000000001", "quantity": 3 } ],
      "menu_change": {
        "reason": "Não veio o frango.",
        "food_items": [ { "food_item_id": "f0000003-0000-4000-8000-000000000003", "quantity": 3 } ]
      } },
    { "id": "e0000010-0000-4000-8000-000000000003",
      "type": "afternoon_snack", "description": "Banana", "acceptance": "poor",
      "food_items": [ { "name": "banana", "quantity": 5 } ] }
  ]
}
$json$::jsonb),

-- O mesmo dia, com UUID de outro aparelho e edição mais ANTIGA.
('dia-edicao-antiga', $json$
{ "id": "c0000099-0000-4000-8000-000000000099", "map_date": "2026-09-10",
  "updated_at": "2026-09-10T09:00:00-03:00", "meals_served": 1, "meals": [] }
$json$::jsonb),

-- O mesmo dia, edição mais RECENTE e com uma refeição só.
('dia-edicao-recente', $json$
{ "id": "c0000010-0000-4000-8000-000000000010", "map_date": "2026-09-10",
  "updated_at": "2026-09-10T21:00:00-03:00", "meals_served": 310,
  "meals": [ { "type": "lunch", "description": "Arroz, feijão e frango", "acceptance": "good" } ] }
$json$::jsonb),

-- O mesmo dia ainda, com UUID que o servidor nunca viu.
('dia-outro-uuid', $json$
{ "id": "c0000088-0000-4000-8000-000000000088", "map_date": "2026-09-10",
  "updated_at": "2026-09-10T22:00:00-03:00", "meals_served": 311, "meals": [] }
$json$::jsonb),

('alteracao-sem-generos', $json$
{ "map_date": "2026-09-11", "updated_at": "2026-09-11T10:00:00-03:00", "meals_served": 300,
  "meals": [
    { "type": "morning_snack", "description": "Bolo", "acceptance": "great" },
    { "type": "lunch", "description": "Arroz", "acceptance": "good",
      "menu_change": { "reason": "Faltou arroz." } } ] }
$json$::jsonb),

-- O dia 4 do seed já saiu em documento e está bloqueado.
('dia-bloqueado', $json$
{ "map_date": "2026-09-04", "updated_at": "2026-09-12T10:00:00-03:00",
  "meals_served": 999, "meals": [] }
$json$::jsonb),

('dia-qualquer', $json$
{ "map_date": "2026-09-12", "updated_at": "2026-09-12T07:00:00-03:00", "meals": [] }
$json$::jsonb),

('dia-da-escola-b', $json$
{ "map_date": "2026-09-10", "updated_at": "2026-09-10T12:00:00-03:00", "meals_served": 40,
  "meals": [ { "type": "lunch", "description": "Macarrão", "acceptance": "good",
               "food_items": [ { "name": "Macarrão", "unit": "pacote", "quantity": 2 } ] } ] }
$json$::jsonb),

-- A escola B apontando um gênero que é da escola A.
('genero-de-outra-escola', $json$
{ "map_date": "2026-09-13", "updated_at": "2026-09-12T08:00:00-03:00", "meals_served": 40,
  "meals": [ { "type": "lunch", "description": "Arroz", "acceptance": "good",
               "food_items": [ { "food_item_id": "f0000001-0000-4000-8000-000000000001",
                                 "name": "Arroz", "unit": "quilo", "quantity": 2 } ] } ] }
$json$::jsonb),

('genero-com-caixa-e-espacos', $json$
{ "map_date": "2026-09-14", "updated_at": "2026-09-12T08:10:00-03:00", "meals_served": 300,
  "meals": [ { "type": "lunch", "description": "Arroz", "acceptance": "good",
               "food_items": [ { "name": "  ARROZ  ", "unit": "saco", "quantity": 2 },
                               { "name": "arroz", "unit": "saco", "quantity": 5 } ] } ] }
$json$::jsonb),

('genero-novo-sem-unidade', $json$
{ "map_date": "2026-09-15", "updated_at": "2026-09-12T08:20:00-03:00", "meals_served": 300,
  "meals": [ { "type": "lunch", "description": "Quiabo", "acceptance": "good",
               "food_items": [ { "name": "Quiabo", "quantity": 2 } ] } ] }
$json$::jsonb),

('quantidade-zero', $json$
{ "map_date": "2026-09-15", "updated_at": "2026-09-12T08:20:00-03:00", "meals_served": 300,
  "meals": [ { "type": "lunch", "description": "Arroz", "acceptance": "good",
               "food_items": [ { "food_item_id": "f0000001-0000-4000-8000-000000000001",
                                 "quantity": 0 } ] } ] }
$json$::jsonb),

('quantidade-fracionada', $json$
{ "map_date": "2026-09-15", "updated_at": "2026-09-12T08:20:00-03:00", "meals_served": 300,
  "meals": [ { "type": "lunch", "description": "Feijão", "acceptance": "good",
               "food_items": [ { "food_item_id": "f0000002-0000-4000-8000-000000000002",
                                 "quantity": 1.5 } ] } ] }
$json$::jsonb),

('quantidade-ausente', $json$
{ "map_date": "2026-09-15", "updated_at": "2026-09-12T08:20:00-03:00", "meals_served": 300,
  "meals": [ { "type": "lunch", "description": "Ovo", "acceptance": "good",
               "food_items": [ { "food_item_id": "f0000003-0000-4000-8000-000000000003" } ] } ] }
$json$::jsonb),

-- Manda meals_served junto de propósito: dia não letivo não conta refeições.
('nao-letivo', $json$
{ "map_date": "2026-09-16", "updated_at": "2026-09-12T08:30:00-03:00",
  "non_school_day": true, "note": "Feriado municipal.", "meals_served": 300, "meals": [] }
$json$::jsonb),

('nao-letivo-com-refeicao', $json$
{ "map_date": "2026-09-17", "updated_at": "2026-09-12T08:40:00-03:00",
  "non_school_day": true, "note": "Feriado.",
  "meals": [ { "type": "lunch", "description": "Arroz" } ] }
$json$::jsonb),

('nao-letivo-sem-observacao', $json$
{ "map_date": "2026-09-17", "updated_at": "2026-09-12T08:40:00-03:00",
  "non_school_day": true, "meals": [] }
$json$::jsonb),

-- O mesmo dia 16, agora letivo: a observação tem que sair.
('nao-letivo-virando-letivo', $json$
{ "map_date": "2026-09-16", "updated_at": "2026-09-12T09:00:00-03:00", "meals_served": 290,
  "meals": [ { "type": "lunch", "description": "Arroz", "acceptance": "good" } ] }
$json$::jsonb),

('letivo-com-observacao', $json$
{ "map_date": "2026-09-18", "updated_at": "2026-09-12T08:50:00-03:00",
  "note": "isto não é dia não letivo", "meals_served": 300, "meals": [] }
$json$::jsonb),

('refeicao-desconhecida', $json$
{ "map_date": "2026-09-19", "updated_at": "2026-09-12T09:10:00-03:00", "meals_served": 300,
  "meals": [ { "type": "jantar", "description": "Sopa" } ] }
$json$::jsonb),

('sem-data', '{"meals": []}'::jsonb),

('dia-para-reabrir', $json$
{ "map_date": "2026-09-21", "updated_at": "2026-09-12T09:20:00-03:00",
  "meals_served": 300, "meals": [] }
$json$::jsonb);

-- O relógio adiantado é relativo a agora, senão o teste expira sozinho um dia.
insert into payload (name, body) values ('relogio-adiantado', jsonb_build_object(
  'map_date', '2026-09-20',
  'updated_at', to_char(now() + interval '3 days', 'YYYY-MM-DD"T"HH24:MI:SSOF'),
  'meals_served', 300,
  'meals', '[]'::jsonb
));

-- ---------------------------------------------------------------------------
-- O caminho feliz
-- ---------------------------------------------------------------------------

select act_as(merendeira_1());

select is(save('dia-completo') ->> 'status', 'saved',
  'A merendeira grava o dia inteiro numa chamada só');

select is((select meals_served from public.meal_map where map_date = '2026-09-10'), 305::smallint,
  'O número de refeições do dia foi gravado');
select is(meals_of('2026-09-10'), 3::bigint, 'As três refeições entraram');
select is(food_items_of('2026-09-10'), 4::bigint, 'Os gêneros utilizados entraram');
select is(changes_of('2026-09-10'), 1::bigint, 'A alteração do cardápio entrou');

select is((select updated_at from public.meal_map where map_date = '2026-09-10'),
  '2026-09-10T18:30:00-03:00'::timestamptz,
  'O carimbo é a edição no aparelho, não a chegada no servidor');
select is((select updated_by from public.meal_map where map_date = '2026-09-10'), merendeira_1(),
  'O carimbo aponta para quem editou');

-- ---------------------------------------------------------------------------
-- O catálogo dentro da gravação
-- ---------------------------------------------------------------------------

select is(catalog_size(school_a()), 9::bigint,
  'O gênero novo nasceu junto com a refeição (8 do seed + 1)');
select is((select default_unit from public.food_item
           where school_id = school_a() and name = 'Achocolatado'), 'pote',
  'O gênero novo nasceu com a unidade enviada');
select is((select count(*) from public.food_item
           where school_id = school_a() and name ilike 'banana'), 1::bigint,
  '"banana" adotou o "Banana" do catálogo em vez de duplicar');

-- ---------------------------------------------------------------------------
-- Reenvio e conflito
-- ---------------------------------------------------------------------------

select is(save('dia-completo') ->> 'status', 'saved',
  'O reenvio da fila reescreve o dia');
select is((select count(*) from public.meal_map where map_date = '2026-09-10'), 1::bigint,
  'O reenvio não duplica o mapa');
select is(catalog_size(school_a()), 9::bigint,
  'O reenvio não duplica o gênero criado na primeira vez');

select act_as(merendeira_2());

select is(save('dia-edicao-antiga') ->> 'status', 'superseded',
  'A edição mais antiga não prevalece, e o caso é devolvido ao cliente');
select is((select meals_served from public.meal_map where map_date = '2026-09-10'), 305::smallint,
  'A edição recusada não alterou nada');
select is(meals_of('2026-09-10'), 3::bigint,
  'A edição recusada não mexeu nas refeições');

select is(save('dia-edicao-recente') ->> 'status', 'saved',
  'A edição mais recente prevalece');
select is(meals_of('2026-09-10'), 1::bigint,
  'Os filhos são substituídos pelos enviados, não somados');
select is(changes_of('2026-09-10'), 0::bigint,
  'A alteração que não veio na carga deixou de existir');
select is((select updated_by from public.meal_map where map_date = '2026-09-10'), merendeira_2(),
  'O carimbo passou para quem editou por último');

select act_as(merendeira_1());

select is(save('dia-outro-uuid') ->> 'meal_map_id',
  'c0000010-0000-4000-8000-000000000010',
  'O dia é a data: o identificador do servidor prevalece sobre o do aparelho');
select is(save('dia-outro-uuid') ->> 'sent_meal_map_id',
  'c0000088-0000-4000-8000-000000000088',
  'A resposta devolve o identificador enviado, para o aparelho saber o que trocar');
select is((select count(*) from public.meal_map
           where map_date = '2026-09-10' and school_id = school_a()), 1::bigint,
  'O UUID desconhecido não criou um segundo mapa no mesmo dia');

-- ---------------------------------------------------------------------------
-- Atomicidade
-- ---------------------------------------------------------------------------

select throws_ok(
  $sql$ select save('alteracao-sem-generos') $sql$,
  '23514', 'A alteração do cardápio precisa dos gêneros que entraram no lugar.',
  'Alteração sem os gêneros que entraram é recusada');

select is((select count(*) from public.meal_map where map_date = '2026-09-11'), 0::bigint,
  'A recusa derrubou o envio inteiro: nem a refeição que já tinha entrado ficou');

-- ---------------------------------------------------------------------------
-- Quem pode gravar
-- ---------------------------------------------------------------------------

select throws_ok(
  $sql$ select save('dia-bloqueado') $sql$,
  '23514', 'Este mapa já está em um documento gerado e não pode ser alterado.',
  'Mapa que já saiu em documento não aceita edição (RN#1 da US007)');

select is((select meals_served from public.meal_map where map_date = '2026-09-04'), 298::smallint,
  'O mapa bloqueado ficou intacto');

select act_as(direcao());
select throws_ok(
  $sql$ select save('dia-qualquer') $sql$,
  '42501', 'Só a merendeira registra o mapa.',
  'A direção não registra mapa nenhum');

select act_as(null);
select throws_ok(
  $sql$ select save('dia-qualquer') $sql$,
  '42501', 'Entre na sua conta para registrar o mapa.',
  'Sem sessão ninguém grava');

-- ---------------------------------------------------------------------------
-- O recorte por escola
-- ---------------------------------------------------------------------------

select act_as(merendeira_b());

select is(save('dia-da-escola-b') ->> 'status', 'saved',
  'A merendeira da outra escola grava o mesmo dia');
select is((select count(*) from public.meal_map where map_date = '2026-09-10'), 2::bigint,
  'Cada escola tem o seu mapa na mesma data');
select is((select meals_served from public.meal_map
           where map_date = '2026-09-10' and school_id = school_b()), 40::smallint,
  'A escola vem do perfil de quem chamou, não da carga');
select is(catalog_size(school_b()), 1::bigint,
  'O gênero novo nasceu no catálogo da escola de quem gravou');
select is(catalog_size(school_a()), 9::bigint,
  'E não encostou no catálogo da outra escola');

select is(save('genero-de-outra-escola') ->> 'status', 'saved',
  'Gênero apontado por identificador de outra escola não quebra a gravação');
select is((select count(*) from public.food_item where name ilike 'arroz'), 2::bigint,
  'A escola B ganhou o próprio "Arroz" em vez de adotar o alheio');

-- ---------------------------------------------------------------------------
-- O catálogo e a normalização do nome
-- ---------------------------------------------------------------------------

select act_as(merendeira_1());

select is(save('genero-com-caixa-e-espacos') ->> 'status', 'saved',
  'Dois nomes que normalizam igual não quebram o índice único');
select is(food_items_of('2026-09-14'), 1::bigint,
  'Eles viraram uma linha só na refeição');
select is((select mfi.quantity from public.meal_food_item mfi
           join public.meal m on m.id = mfi.meal_id
           join public.meal_map mm on mm.id = m.meal_map_id
           where mm.map_date = '2026-09-14'), 5::smallint,
  'Vale a última quantidade enviada');
select is((select default_unit from public.food_item
           where school_id = school_a() and name = 'Arroz'), 'quilo',
  'Quem manda na unidade é o catálogo, não a carga');

select throws_ok(
  $sql$ select save('genero-novo-sem-unidade') $sql$,
  '23514', 'O gênero "Quiabo" ainda não está no catálogo e precisa de uma unidade.',
  'Gênero que vai nascer precisa de unidade');

select throws_ok(
  $sql$ select save('quantidade-zero') $sql$,
  '23514', 'A quantidade de "Arroz" precisa ser maior que zero.',
  'Quantidade zero é recusada dizendo qual gênero');
select throws_ok(
  $sql$ select save('quantidade-fracionada') $sql$,
  '23514', 'A quantidade de "Feijão" precisa ser um número inteiro.',
  'Quantidade fracionada é recusada (RN#1 da US003)');
select throws_ok(
  $sql$ select save('quantidade-ausente') $sql$,
  '23514', 'A quantidade de "Ovo" precisa ser um número inteiro.',
  'Gênero citado sem quantidade é recusado');

-- ---------------------------------------------------------------------------
-- Dia letivo e dia não letivo
-- ---------------------------------------------------------------------------

select is(save('nao-letivo') ->> 'status', 'saved',
  'Dia não letivo com observação é gravado');
select is((select note from public.meal_map where map_date = '2026-09-16'), 'Feriado municipal.',
  'A observação do dia não letivo ficou');
select is((select meals_served from public.meal_map where map_date = '2026-09-16'), null::smallint,
  'Dia não letivo não conta refeições, mesmo se a carga mandar');

select throws_ok(
  $sql$ select save('nao-letivo-com-refeicao') $sql$,
  '23514', 'Dia não letivo não tem refeições para registrar.',
  'Dia não letivo com refeição é recusado');
select throws_ok(
  $sql$ select save('nao-letivo-sem-observacao') $sql$,
  '23514', 'Dia não letivo precisa de uma observação dizendo o motivo.',
  'Dia não letivo sem observação é recusado (RN#1 da US006)');

select is(save('nao-letivo-virando-letivo') ->> 'status', 'saved',
  'O dia não letivo volta a ser letivo na mesma operação');
select is((select note from public.meal_map where map_date = '2026-09-16'), null::text,
  'E a observação sai junto');

select is(save('letivo-com-observacao') ->> 'status', 'saved',
  'Dia letivo com observação enviada por engano é gravado');
select is((select note from public.meal_map where map_date = '2026-09-18'), null::text,
  'E a observação é descartada, porque ela é do dia não letivo');

-- ---------------------------------------------------------------------------
-- Cargas malformadas
-- ---------------------------------------------------------------------------

select throws_ok(
  $sql$ select save('refeicao-desconhecida') $sql$,
  '23514', 'Refeição desconhecida: "jantar".',
  'Refeição fora das três do dia é recusada');
select throws_ok(
  $sql$ select save('sem-data') $sql$,
  '23514', 'O mapa precisa da data do dia.',
  'Sem a data não há dia a gravar');

select is(save('relogio-adiantado') ->> 'status', 'saved',
  'Carga com relógio adiantado é aceita');
select ok((select updated_at from public.meal_map where map_date = '2026-09-20') <= now(),
  'Mas a edição não pode ter acontecido depois de chegar');

-- ---------------------------------------------------------------------------
-- O carimbo e a reabertura (CA#3 da US011, US023)
-- ---------------------------------------------------------------------------

select is(save('dia-para-reabrir') ->> 'status', 'saved',
  'Dia gravado para o teste da reabertura');

-- O bloqueio é do servidor: nasce na geração do documento.
update public.meal_map set locked = true where map_date = '2026-09-21';

select act_as(direcao());
select lives_ok(
  $sql$ select public.unlock_meal_map(
          (select id from public.meal_map where map_date = '2026-09-21'),
          'Erro no número de refeições.') $sql$,
  'A direção reabre o mapa com justificativa');

select is((select updated_by from public.meal_map where map_date = '2026-09-21'), merendeira_1(),
  'A reabertura não faz a direção virar a última editora');
select is((select updated_at from public.meal_map where map_date = '2026-09-21'),
  '2026-09-12T09:20:00-03:00'::timestamptz,
  'A reabertura não move a data da última edição, que decide a convergência');
select is((select locked from public.meal_map where map_date = '2026-09-21'), false,
  'E o mapa ficou reaberto');

-- ---------------------------------------------------------------------------
-- A superfície da API
-- ---------------------------------------------------------------------------

select is(
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'internal'
     and p.proname in ('resolve_food_item', 'checked_quantity',
                       'remember_food_item', 'normalized_food_item_name')),
  4::bigint,
  'As peças internas ficam fora do schema que o PostgREST expõe');

select ok(not has_schema_privilege('anon', 'internal', 'usage'),
  'anon não entra no schema internal');
select ok(not has_schema_privilege('authenticated', 'internal', 'usage'),
  'authenticated não entra no schema internal');
select ok(has_function_privilege('authenticated', 'public.save_meal_map(jsonb)', 'execute'),
  'A operação do produto, essa sim, está na API');

select * from finish();

rollback;
