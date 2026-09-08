-- Dados de desenvolvimento. Tudo fictício: nome de escola, município, pessoas
-- e e-mails. Nenhum dado real entra no repositório (regra de sigilo do projeto).
--
-- As merendeiras aparecem como "Merendeira 1" e "Merendeira 2", a mesma
-- anonimização usada na documentação pública.

-- Senha de todas as contas de desenvolvimento: mae-desenvolvimento
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
)
values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-4111-8111-111111111111',
   'authenticated', 'authenticated', 'direcao@dominio.com.br',
   crypt('mae-desenvolvimento', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{}'),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-4222-8222-222222222222',
   'authenticated', 'authenticated', 'merendeira1@dominio.com.br',
   crypt('mae-desenvolvimento', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{}'),
  ('00000000-0000-0000-0000-000000000000', '33333333-3333-4333-8333-333333333333',
   'authenticated', 'authenticated', 'merendeira2@dominio.com.br',
   crypt('mae-desenvolvimento', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{}');

insert into auth.identities (
  provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
select id, id,
       jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true),
       'email', now(), now(), now()
from auth.users;

insert into public.school (id, name, city, school_year)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'Escola Municipal Exemplo', 'Município Exemplo', 2026);

insert into public.profile (id, school_id, name, email, role)
values
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
   'Direção', 'direcao@dominio.com.br', 'admin'),
  ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
   'Merendeira 1', 'merendeira1@dominio.com.br', 'cook'),
  ('33333333-3333-4333-8333-333333333333', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
   'Merendeira 2', 'merendeira2@dominio.com.br', 'cook');

insert into public.food_item (id, school_id, name, default_unit)
values
  ('f0000001-0000-4000-8000-000000000001', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Arroz', 'quilo'),
  ('f0000002-0000-4000-8000-000000000002', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Feijão', 'quilo'),
  ('f0000003-0000-4000-8000-000000000003', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Ovo', 'bandeja'),
  ('f0000004-0000-4000-8000-000000000004', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Óleo de soja', 'lata'),
  ('f0000005-0000-4000-8000-000000000005', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Leite em pó', 'saco'),
  ('f0000006-0000-4000-8000-000000000006', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Manteiga', 'pote'),
  ('f0000007-0000-4000-8000-000000000007', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Pão', 'quilo'),
  ('f0000008-0000-4000-8000-000000000008', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Banana', 'quilo');

insert into public.document_template (id, school_id, file_name, file_path, uploaded_by)
values ('d0000001-0000-4000-8000-000000000001', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'modelo-oficial.docx',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/modelo-oficial.docx',
        '11111111-1111-4111-8111-111111111111');

-- Quatro dias, um de cada estado que a visão do mês mostra.

-- 1 de setembro: completo, com alteração no almoço.
insert into public.meal_map (id, school_id, map_date, meals_served, updated_by)
values ('c0000001-0000-4000-8000-000000000001', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        '2026-09-01', 312, '22222222-2222-4222-8222-222222222222');

insert into public.meal (id, meal_map_id, type, description, acceptance)
values
  ('e0000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001',
   'morning_snack', 'Pão com manteiga e leite com achocolatado', 'great'),
  ('e0000001-0000-4000-8000-000000000002', 'c0000001-0000-4000-8000-000000000001',
   'lunch', 'Arroz, feijão, frango desfiado e salada de alface', 'good'),
  ('e0000001-0000-4000-8000-000000000003', 'c0000001-0000-4000-8000-000000000001',
   'afternoon_snack', 'Banana e leite', 'good');

insert into public.meal_food_item (meal_id, food_item_id, quantity)
values
  ('e0000001-0000-4000-8000-000000000002', 'f0000001-0000-4000-8000-000000000001', 3),
  ('e0000001-0000-4000-8000-000000000002', 'f0000002-0000-4000-8000-000000000002', 2),
  ('e0000001-0000-4000-8000-000000000001', 'f0000007-0000-4000-8000-000000000007', 4);

-- A refeição continua descrevendo o cardápio previsto; a alteração diz o que
-- entrou no lugar e por quê (decisão 7).
insert into public.menu_change (id, meal_id, reason)
values ('b0000001-0000-4000-8000-000000000001', 'e0000001-0000-4000-8000-000000000002',
        'Não veio o frango na entrega da semana.');

insert into public.menu_change_food_item (menu_change_id, food_item_id, quantity)
values
  ('b0000001-0000-4000-8000-000000000001', 'f0000003-0000-4000-8000-000000000003', 3),
  ('b0000001-0000-4000-8000-000000000001', 'f0000004-0000-4000-8000-000000000004', 1);

-- 2 de setembro: pendente, só o lanche da manhã preenchido.
insert into public.meal_map (id, school_id, map_date, updated_by)
values ('c0000002-0000-4000-8000-000000000002', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        '2026-09-02', '33333333-3333-4333-8333-333333333333');

insert into public.meal (meal_map_id, type, description, acceptance)
values ('c0000002-0000-4000-8000-000000000002', 'morning_snack',
        'Bolo de cenoura e suco de laranja', 'great');

-- 3 de setembro: não letivo.
insert into public.meal_map (id, school_id, map_date, non_school_day, note, updated_by)
values ('c0000003-0000-4000-8000-000000000003', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        '2026-09-03', true, 'Conselho de classe.', '22222222-2222-4222-8222-222222222222');

-- 4 de setembro: já saiu em documento, portanto bloqueado.
insert into public.meal_map (id, school_id, map_date, meals_served, locked, updated_by)
values ('c0000004-0000-4000-8000-000000000004', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        '2026-09-04', 298, true, '22222222-2222-4222-8222-222222222222');

insert into public.meal (meal_map_id, type, description, acceptance)
values
  ('c0000004-0000-4000-8000-000000000004', 'morning_snack', 'Leite com café e biscoito', 'good'),
  ('c0000004-0000-4000-8000-000000000004', 'lunch', 'Arroz, feijão, carne moída e cenoura', 'great'),
  ('c0000004-0000-4000-8000-000000000004', 'afternoon_snack', 'Iogurte e pão', 'poor');

insert into public.generated_document (
  id, school_id, document_template_id, requested_by,
  status, completed_at, file_path, expires_at
)
values ('90000001-0000-4000-8000-000000000001', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'd0000001-0000-4000-8000-000000000001', '22222222-2222-4222-8222-222222222222',
        'available', now(),
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/mapa-2026-09-04.docx',
        now() + interval '7 days');

insert into public.document_meal_map (generated_document_id, meal_map_id)
values ('90000001-0000-4000-8000-000000000001', 'c0000004-0000-4000-8000-000000000004');
