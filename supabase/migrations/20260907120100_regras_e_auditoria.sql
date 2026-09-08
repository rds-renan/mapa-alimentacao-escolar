-- Regras que nenhuma restrição de coluna alcança: o bloqueio do mapa, a
-- proteção da coluna locked e a reabertura com justificativa (decisão 5).

-- ---------------------------------------------------------------------------
-- Funções de apoio
-- ---------------------------------------------------------------------------

-- A escola de quem está autenticado. security definer porque é chamada de
-- dentro das políticas da própria tabela profile.
create or replace function public.current_school_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_catalog
as $$
  select school_id from public.profile where id = auth.uid() and active;
$$;

create or replace function public.current_role_is(wanted public.user_role)
returns boolean
language sql
stable
security definer
set search_path = public, pg_catalog
as $$
  select exists (
    select 1 from public.profile
    where id = auth.uid() and active and role = wanted
  );
$$;

-- Quem pode escrever o que a merendeira não escreve: o servidor (edge function
-- com service_role), a manutenção local e as funções security definer deste
-- schema, que rodam como o dono.
--
-- Repara em current_user, e não no papel do token: os gatilhos abaixo são
-- security invoker de propósito, para que current_user seja quem de fato
-- chamou. Um gatilho security definer enxergaria sempre o dono e nunca
-- dispararia — erro cometido na primeira versão desta migration.
create or replace function public.is_service()
returns boolean
language sql
stable
as $$
  select current_user in ('service_role', 'postgres', 'supabase_admin');
$$;

-- Lê o bloqueio por fora do RLS: o gatilho precisa enxergar o mapa mesmo
-- quando a política da tabela não deixaria.
create or replace function public.meal_map_is_locked(map_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_catalog
as $$
  select locked from public.meal_map where id = map_id;
$$;

-- ---------------------------------------------------------------------------
-- Mapa bloqueado não aceita edição
-- ---------------------------------------------------------------------------

-- Vale para o mapa e para tudo que pende dele. O argumento do gatilho diz como
-- a tabela chega até o mapa. Lê a linha como jsonb porque NEW não existe em
-- DELETE e OLD não existe em INSERT.
create or replace function public.reject_write_on_locked_map()
returns trigger
language plpgsql
as $$
declare
  row_data jsonb;
  target uuid;
begin
  if public.is_service() then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_argv[0] = 'self' then
    if old.locked then
      raise exception using
        errcode = 'check_violation',
        message = 'Este mapa já está em um documento gerado e não pode ser alterado.',
        hint = 'A direção pode reabrir o mapa para correção.';
    end if;
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  row_data := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;

  target := case tg_argv[0]
    when 'meal_map_id' then (row_data ->> 'meal_map_id')::uuid
    when 'meal_id' then (
      select m.meal_map_id from public.meal m
      where m.id = (row_data ->> 'meal_id')::uuid
    )
    when 'menu_change_id' then (
      select m.meal_map_id
      from public.menu_change mc
      join public.meal m on m.id = mc.meal_id
      where mc.id = (row_data ->> 'menu_change_id')::uuid
    )
  end;

  if target is not null and public.meal_map_is_locked(target) then
    raise exception using
      errcode = 'check_violation',
      message = 'Este mapa já está em um documento gerado e não pode ser alterado.',
      hint = 'A direção pode reabrir o mapa para correção.';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger meal_map_locked_guard
  before update or delete on public.meal_map
  for each row execute function public.reject_write_on_locked_map('self');

create trigger meal_locked_guard
  before insert or update or delete on public.meal
  for each row execute function public.reject_write_on_locked_map('meal_map_id');

create trigger meal_food_item_locked_guard
  before insert or update or delete on public.meal_food_item
  for each row execute function public.reject_write_on_locked_map('meal_id');

create trigger menu_change_locked_guard
  before insert or update or delete on public.menu_change
  for each row execute function public.reject_write_on_locked_map('meal_id');

create trigger menu_change_food_item_locked_guard
  before insert or update or delete on public.menu_change_food_item
  for each row execute function public.reject_write_on_locked_map('menu_change_id');

-- ---------------------------------------------------------------------------
-- A merendeira não escreve em locked
-- ---------------------------------------------------------------------------

create or replace function public.protect_lock_column()
returns trigger
language plpgsql
as $$
begin
  if public.is_service() then
    return new;
  end if;
  if new.locked is distinct from old.locked then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'O bloqueio do mapa é do sistema: nasce na geração do documento e sai na reabertura pela direção.';
  end if;
  return new;
end;
$$;

create trigger meal_map_lock_column_guard
  before update on public.meal_map
  for each row execute function public.protect_lock_column();

-- ---------------------------------------------------------------------------
-- Carimbo de última edição
-- ---------------------------------------------------------------------------

create or replace function public.stamp_meal_map_update()
returns trigger
language plpgsql
as $$
begin
  -- Reabertura não é edição: se a única diferença é o bloqueio, o carimbo de
  -- última edição continua apontando para quem de fato mexeu no mapa. Sem
  -- isso, desbloquear faria a direção aparecer como última editora, e é esse
  -- carimbo que decide a convergência entre aparelhos (CA#3 da US011).
  if new.locked is distinct from old.locked
     and (to_jsonb(new) - 'locked' - 'updated_at' - 'updated_by')
       = (to_jsonb(old) - 'locked' - 'updated_at' - 'updated_by')
  then
    return new;
  end if;

  new.updated_at := now();
  if auth.uid() is not null then
    new.updated_by := auth.uid();
  end if;
  return new;
end;
$$;

create trigger meal_map_stamp_update
  before update on public.meal_map
  for each row execute function public.stamp_meal_map_update();

-- ---------------------------------------------------------------------------
-- O desbloqueio é a única porta de saída do bloqueio
-- ---------------------------------------------------------------------------

-- Registra a reabertura e desbloqueia numa operação só, para que não exista
-- mapa reaberto sem justificativa guardada (CA#3 da US023). É security definer
-- e por isso passa pelos gatilhos acima — é a exceção prevista, não um furo.
create or replace function public.unlock_meal_map(map_id uuid, unlock_reason text)
returns public.meal_map
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  target public.meal_map;
begin
  if not public.current_role_is('admin') then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'Só a direção pode reabrir um mapa.';
  end if;

  if btrim(coalesce(unlock_reason, '')) = '' then
    raise exception using
      errcode = 'check_violation',
      message = 'A reabertura precisa de uma justificativa.';
  end if;

  select * into target from public.meal_map
  where id = map_id and school_id = public.current_school_id();

  if not found then
    raise exception using errcode = 'no_data_found', message = 'Mapa não encontrado.';
  end if;

  if not target.locked then
    raise exception using
      errcode = 'check_violation',
      message = 'Este mapa não está bloqueado.';
  end if;

  insert into public.meal_map_unlock (meal_map_id, unlocked_by, reason)
  values (map_id, auth.uid(), unlock_reason);

  update public.meal_map set locked = false where id = map_id
  returning * into target;

  return target;
end;
$$;

comment on function public.unlock_meal_map is
  'Reabre um mapa bloqueado registrando quem, quando e por quê (US023). A direção reabre; quem corrige é a merendeira.';
