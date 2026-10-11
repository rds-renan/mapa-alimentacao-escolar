-- Os avisos do linter do Supabase, relidos depois do ensaio (issue #140).
--
-- Eram 15 de segurança em 04/10 e continuavam os mesmos 15 em 11/10. Nenhum
-- era uma porta aberta — o que cada um diz, e o que se fez com ele:
--
--   function_search_path_mutable (10)
--     Funções sem `search_path` fixo. São todas SECURITY INVOKER — rodam com
--     os direitos de quem chama, então um `search_path` trocado não dá a
--     ninguém mais do que ele já tinha. Fixar custa uma linha por função e
--     tira o aviso da frente, e é o mesmo `public, pg_catalog` que as
--     SECURITY DEFINER já usam desde a E4.
--
--   anon_security_definer_function_executable (5)
--     As cinco SECURITY DEFINER podiam ser chamadas sem login, pelo
--     `/rest/v1/rpc/`. Também não vazavam nada: todas partem de `auth.uid()`,
--     que sem login é nulo — `current_school_id()` devolve nulo,
--     `save_meal_map` recusa quem não tem escola e `unlock_meal_map` quem não
--     é da direção. Mas ninguém sem login tem o que fazer com elas, e "não
--     vaza porque a função confere" é uma defesa só; tirar o EXECUTE do
--     `anon` é a segunda. As
--     políticas que chamam três delas (`current_role_is`, `current_school_id`,
--     `meal_map_is_locked`) são todas `to authenticated`, então o `anon` nunca
--     as avalia e não passa a receber erro onde antes recebia lista vazia.
--
--   authenticated_security_definer_function_executable (as mesmas 5)
--     Ficam. Quem está logada precisa delas: as três primeiras sustentam as
--     políticas de RLS, e as outras duas são a gravação do dia e a reabertura.
--
-- O EXECUTE vinha de PUBLIC, o padrão do Postgres para toda função nova, e o
-- `anon` o herdava. Revogar só do `anon` não bastaria.

-- ---------------------------------------------------------------------------
-- search_path fixo
-- ---------------------------------------------------------------------------

alter function public.is_service() set search_path = public, pg_catalog;
alter function public.reject_write_on_locked_map() set search_path = public, pg_catalog;
alter function public.protect_lock_column() set search_path = public, pg_catalog;
alter function public.stamp_meal_map_update() set search_path = public, pg_catalog;
alter function public.reject_privileged_profile_change() set search_path = public, pg_catalog;
alter function public.start_document_generation(uuid, uuid, uuid[]) set search_path = public, pg_catalog;
alter function public.fail_document_generation(uuid) set search_path = public, pg_catalog;
alter function public.complete_document_generation(uuid, text, text) set search_path = public, pg_catalog;
alter function public.replace_document_template(text, text) set search_path = public, pg_catalog;
alter function public.touch_last_access() set search_path = public, pg_catalog;

-- ---------------------------------------------------------------------------
-- SECURITY DEFINER só para quem está logada
-- ---------------------------------------------------------------------------

revoke execute on function public.current_role_is(public.user_role) from public, anon;
revoke execute on function public.current_school_id() from public, anon;
revoke execute on function public.meal_map_is_locked(uuid) from public, anon;
revoke execute on function public.save_meal_map(jsonb) from public, anon;
revoke execute on function public.unlock_meal_map(uuid, text) from public, anon;

grant execute on function public.current_role_is(public.user_role) to authenticated;
grant execute on function public.current_school_id() to authenticated;
grant execute on function public.meal_map_is_locked(uuid) to authenticated;
grant execute on function public.save_meal_map(jsonb) to authenticated;
grant execute on function public.unlock_meal_map(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- auth_rls_initplan: auth.uid() uma vez por consulta, e não uma por linha
-- ---------------------------------------------------------------------------

-- O único aviso de desempenho que é de graça: o `(select …)` deixa o
-- planejador avaliar `auth.uid()` uma vez só. Com uma escola, a diferença não
-- se mede; o resto dos avisos de desempenho fica justificado no registro da
-- varredura (docs/07-testes/).
alter policy profile_update_self on public.profile
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
