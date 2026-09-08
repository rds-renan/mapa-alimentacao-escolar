-- Políticas de acesso por perfil. Tudo é recortado pela escola de quem está
-- autenticado; dentro dela, a merendeira faz o fluxo do mapa e a direção
-- cuida do gerencial e nunca registra (RN#1 da US016).

alter table public.school enable row level security;
alter table public.profile enable row level security;
alter table public.food_item enable row level security;
alter table public.meal_map enable row level security;
alter table public.meal enable row level security;
alter table public.meal_food_item enable row level security;
alter table public.menu_change enable row level security;
alter table public.menu_change_food_item enable row level security;
alter table public.document_template enable row level security;
alter table public.generated_document enable row level security;
alter table public.document_meal_map enable row level security;
alter table public.meal_map_unlock enable row level security;

-- ---------------------------------------------------------------------------
-- Escola e perfis
-- ---------------------------------------------------------------------------

create policy school_select on public.school
  for select to authenticated
  using (id = public.current_school_id());

-- Dados da escola são gerenciais (US015).
create policy school_update on public.school
  for update to authenticated
  using (id = public.current_school_id() and public.current_role_is('admin'))
  with check (id = public.current_school_id());

-- Todos os perfis da escola se enxergam: as duas merendeiras se revezam e
-- precisam saber quem editou o quê (US011, RN#2 da US016).
create policy profile_select on public.profile
  for select to authenticated
  using (school_id = public.current_school_id());

create policy profile_update_self on public.profile
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Criar e desativar acessos é da direção (US016).
create policy profile_admin_insert on public.profile
  for insert to authenticated
  with check (school_id = public.current_school_id() and public.current_role_is('admin'));

create policy profile_admin_update on public.profile
  for update to authenticated
  using (school_id = public.current_school_id() and public.current_role_is('admin'))
  with check (school_id = public.current_school_id());

-- ---------------------------------------------------------------------------
-- Catálogo: da merendeira, sem depender de ninguém (US009)
-- ---------------------------------------------------------------------------

create policy food_item_select on public.food_item
  for select to authenticated
  using (school_id = public.current_school_id());

create policy food_item_cook_insert on public.food_item
  for insert to authenticated
  with check (school_id = public.current_school_id() and public.current_role_is('cook'));

create policy food_item_cook_update on public.food_item
  for update to authenticated
  using (school_id = public.current_school_id() and public.current_role_is('cook'))
  with check (school_id = public.current_school_id());

-- Não há política de delete: gênero usado não se apaga, se desativa
-- (CA#3 da US009).

-- ---------------------------------------------------------------------------
-- O mapa: da merendeira; a direção consulta
-- ---------------------------------------------------------------------------

create policy meal_map_select on public.meal_map
  for select to authenticated
  using (school_id = public.current_school_id());

create policy meal_map_cook_insert on public.meal_map
  for insert to authenticated
  with check (
    school_id = public.current_school_id()
    and public.current_role_is('cook')
    and not locked
  );

create policy meal_map_cook_update on public.meal_map
  for update to authenticated
  using (school_id = public.current_school_id() and public.current_role_is('cook'))
  with check (school_id = public.current_school_id());

create policy meal_map_cook_delete on public.meal_map
  for delete to authenticated
  using (school_id = public.current_school_id() and public.current_role_is('cook'));

-- As tabelas-filhas herdam o recorte pelo mapa. O gatilho da migration
-- anterior é quem recusa a escrita em mapa bloqueado.
create policy meal_select on public.meal
  for select to authenticated
  using (exists (
    select 1 from public.meal_map mm
    where mm.id = meal.meal_map_id and mm.school_id = public.current_school_id()
  ));

create policy meal_cook_write on public.meal
  for all to authenticated
  using (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal_map mm
      where mm.id = meal.meal_map_id and mm.school_id = public.current_school_id()
    )
  )
  with check (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal_map mm
      where mm.id = meal.meal_map_id and mm.school_id = public.current_school_id()
    )
  );

create policy meal_food_item_select on public.meal_food_item
  for select to authenticated
  using (exists (
    select 1 from public.meal m
    join public.meal_map mm on mm.id = m.meal_map_id
    where m.id = meal_food_item.meal_id and mm.school_id = public.current_school_id()
  ));

create policy meal_food_item_cook_write on public.meal_food_item
  for all to authenticated
  using (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal m
      join public.meal_map mm on mm.id = m.meal_map_id
      where m.id = meal_food_item.meal_id and mm.school_id = public.current_school_id()
    )
  )
  with check (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal m
      join public.meal_map mm on mm.id = m.meal_map_id
      where m.id = meal_food_item.meal_id and mm.school_id = public.current_school_id()
    )
  );

create policy menu_change_select on public.menu_change
  for select to authenticated
  using (exists (
    select 1 from public.meal m
    join public.meal_map mm on mm.id = m.meal_map_id
    where m.id = menu_change.meal_id and mm.school_id = public.current_school_id()
  ));

create policy menu_change_cook_write on public.menu_change
  for all to authenticated
  using (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal m
      join public.meal_map mm on mm.id = m.meal_map_id
      where m.id = menu_change.meal_id and mm.school_id = public.current_school_id()
    )
  )
  with check (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal m
      join public.meal_map mm on mm.id = m.meal_map_id
      where m.id = menu_change.meal_id and mm.school_id = public.current_school_id()
    )
  );

create policy menu_change_food_item_select on public.menu_change_food_item
  for select to authenticated
  using (exists (
    select 1 from public.menu_change mc
    join public.meal m on m.id = mc.meal_id
    join public.meal_map mm on mm.id = m.meal_map_id
    where mc.id = menu_change_food_item.menu_change_id
      and mm.school_id = public.current_school_id()
  ));

create policy menu_change_food_item_cook_write on public.menu_change_food_item
  for all to authenticated
  using (
    public.current_role_is('cook')
    and exists (
      select 1 from public.menu_change mc
      join public.meal m on m.id = mc.meal_id
      join public.meal_map mm on mm.id = m.meal_map_id
      where mc.id = menu_change_food_item.menu_change_id
        and mm.school_id = public.current_school_id()
    )
  )
  with check (
    public.current_role_is('cook')
    and exists (
      select 1 from public.menu_change mc
      join public.meal m on m.id = mc.meal_id
      join public.meal_map mm on mm.id = m.meal_map_id
      where mc.id = menu_change_food_item.menu_change_id
        and mm.school_id = public.current_school_id()
    )
  );

-- ---------------------------------------------------------------------------
-- Modelo oficial: só a direção mexe (US015)
-- ---------------------------------------------------------------------------

create policy document_template_select on public.document_template
  for select to authenticated
  using (school_id = public.current_school_id());

create policy document_template_admin_write on public.document_template
  for all to authenticated
  using (school_id = public.current_school_id() and public.current_role_is('admin'))
  with check (school_id = public.current_school_id() and public.current_role_is('admin'));

-- ---------------------------------------------------------------------------
-- Documentos gerados: leitura para os dois perfis, escrita só do servidor
-- ---------------------------------------------------------------------------

-- A merendeira vê os seus documentos (US021) e a direção vê os da escola
-- (US022). Quem escreve é a edge function da geração (decisão 10).
create policy generated_document_select on public.generated_document
  for select to authenticated
  using (school_id = public.current_school_id());

create policy document_meal_map_select on public.document_meal_map
  for select to authenticated
  using (exists (
    select 1 from public.generated_document gd
    where gd.id = document_meal_map.generated_document_id
      and gd.school_id = public.current_school_id()
  ));

-- ---------------------------------------------------------------------------
-- Desbloqueio: leitura para os dois, escrita só pela função (US023)
-- ---------------------------------------------------------------------------

create policy meal_map_unlock_select on public.meal_map_unlock
  for select to authenticated
  using (exists (
    select 1 from public.meal_map mm
    where mm.id = meal_map_unlock.meal_map_id
      and mm.school_id = public.current_school_id()
  ));

-- Não há política de insert, update ou delete: quem grava é
-- public.unlock_meal_map(), e o histórico é permanente (RNF#1 da US023).
