-- Os avisos do linter do Supabase que a issue #140 corrigiu, para não
-- voltarem com uma função nova ou um `create or replace` que esqueça o que a
-- migration 20261011120000 fez.
--
--   supabase test db
--
-- Roda contra o banco local, numa transação que termina em rollback.

begin;

create extension if not exists pgtap with schema extensions;

select plan(12);

-- ---------------------------------------------------------------------------
-- SECURITY DEFINER: só quem está logada executa
-- ---------------------------------------------------------------------------

select ok(not has_function_privilege('anon', 'public.current_role_is(public.user_role)', 'execute'),
  'anon não executa current_role_is');
select ok(not has_function_privilege('anon', 'public.current_school_id()', 'execute'),
  'anon não executa current_school_id');
select ok(not has_function_privilege('anon', 'public.meal_map_is_locked(uuid)', 'execute'),
  'anon não executa meal_map_is_locked');
select ok(not has_function_privilege('anon', 'public.save_meal_map(jsonb)', 'execute'),
  'anon não executa save_meal_map');
select ok(not has_function_privilege('anon', 'public.unlock_meal_map(uuid, text)', 'execute'),
  'anon não executa unlock_meal_map');

select ok(has_function_privilege('authenticated', 'public.current_role_is(public.user_role)', 'execute'),
  'authenticated executa current_role_is');
select ok(has_function_privilege('authenticated', 'public.current_school_id()', 'execute'),
  'authenticated executa current_school_id');
select ok(has_function_privilege('authenticated', 'public.meal_map_is_locked(uuid)', 'execute'),
  'authenticated executa meal_map_is_locked');
select ok(has_function_privilege('authenticated', 'public.save_meal_map(jsonb)', 'execute'),
  'authenticated executa save_meal_map');
select ok(has_function_privilege('authenticated', 'public.unlock_meal_map(uuid, text)', 'execute'),
  'authenticated executa unlock_meal_map');

-- ---------------------------------------------------------------------------
-- search_path fixo em toda função do schema public
-- ---------------------------------------------------------------------------

select is_empty(
  $$ select p.proname::text
       from pg_proc p
       join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and not exists (
          select 1 from unnest(coalesce(p.proconfig, '{}')) c
           where c like 'search_path=%') $$,
  'toda função de public tem search_path fixo');

-- E a política que o aviso de desempenho apontou continua avaliando
-- auth.uid() uma vez por consulta.
select matches(
  (select qual from pg_policies
    where schemaname = 'public' and tablename = 'profile'
      and policyname = 'profile_update_self'),
  'SELECT auth\.uid\(\)',
  'profile_update_self chama auth.uid() dentro de um select');

select * from finish();

rollback;
