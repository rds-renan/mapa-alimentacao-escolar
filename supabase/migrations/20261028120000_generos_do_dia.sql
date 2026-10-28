-- Os gêneros e a alteração do cardápio passam a ser do dia (issue #172,
-- decisão 14 da E4).
--
-- No teste da E7, a Merendeira 1 lançou os gêneros do dia inteiro numa
-- refeição só, e o documento oficial nunca pediu outra coisa: a coluna GÊNEROS
-- UTILIZADOS é uma célula por dia, e a justificativa fica sob as três
-- refeições. A refeição fica com o cardápio previsto e a aceitação; o resto
-- sobe para o mapa.
--
--   * `meal_food_item` (refeição × gênero) dá lugar a `meal_map_food_item`
--     (dia × gênero), um gênero por dia;
--   * `menu_change` troca `meal_id` por `meal_map_id`, uma alteração por dia;
--   * `menu_change_food_item` não muda de forma, só de caminho até o mapa.
--
-- O que já existia vem junto: os gêneros das três refeições de um dia viram
-- uma lista só, somando a quantidade quando o mesmo gênero aparecia em mais de
-- uma refeição (a unidade é do catálogo, então é sempre a mesma). Duas
-- alterações no mesmo dia viram uma: as justificativas na ordem das
-- refeições, os gêneros somados.
--
-- A migration roda como `postgres`, que a trava de mapa bloqueado deixa
-- passar (`is_service`): os mapas que já saíram em documento migram como os
-- outros. Os documentos gerados são arquivos e não mudam — eles já imprimiam
-- a soma do dia.
--
-- Contrato novo da `save_meal_map`: `food_items` e `menu_change` vêm no dia,
-- não na refeição. O aplicativo 0.1.3 não fala esse formato; a migration
-- seguinte sobe o mínimo para 5, no mesmo `db push`, depois de o APK 0.1.4
-- estar publicado (issue #179).

-- ---------------------------------------------------------------------------
-- Os gêneros do dia
-- ---------------------------------------------------------------------------

create table public.meal_map_food_item (
  id uuid primary key default gen_random_uuid(),
  meal_map_id uuid not null references public.meal_map (id) on delete cascade,
  food_item_id uuid not null references public.food_item (id) on delete restrict,
  quantity smallint not null,
  constraint meal_map_food_item_quantity_positive check (quantity > 0)
);

comment on table public.meal_map_food_item is
  'Gêneros utilizados no dia, com a quantidade na unidade do catálogo. Alimenta a coluna GÊNEROS UTILIZADOS do documento (decisão 14 da E4).';

create unique index meal_map_food_item_key
  on public.meal_map_food_item (meal_map_id, food_item_id);
create index meal_map_food_item_food_idx on public.meal_map_food_item (food_item_id);

insert into public.meal_map_food_item (meal_map_id, food_item_id, quantity)
select m.meal_map_id, f.food_item_id, sum(f.quantity)::smallint
from public.meal_food_item f
join public.meal m on m.id = f.meal_id
group by m.meal_map_id, f.food_item_id;

drop table public.meal_food_item;

-- ---------------------------------------------------------------------------
-- A alteração do dia
-- ---------------------------------------------------------------------------

alter table public.menu_change
  add column meal_map_id uuid references public.meal_map (id) on delete cascade;

update public.menu_change mc
set meal_map_id = m.meal_map_id
from public.meal m
where m.id = mc.meal_id;

-- Dois dias com mais de uma alteração: fica a da primeira refeição, com as
-- justificativas de todas e os gêneros de todas.
create temporary table menu_change_merge on commit drop as
select
  mc.id,
  first_value(mc.id) over day_changes as keeper,
  string_agg(btrim(mc.reason), ' / ') over (
    day_changes rows between unbounded preceding and unbounded following
  ) as merged_reason
from public.menu_change mc
join public.meal m on m.id = mc.meal_id
window day_changes as (partition by mc.meal_map_id order by m.type);

insert into public.menu_change_food_item (menu_change_id, food_item_id, quantity)
select merge.keeper, cfi.food_item_id, cfi.quantity
from public.menu_change_food_item cfi
join menu_change_merge merge on merge.id = cfi.menu_change_id
where merge.id <> merge.keeper
on conflict (menu_change_id, food_item_id)
  do update set quantity = public.menu_change_food_item.quantity + excluded.quantity;

delete from public.menu_change mc
using menu_change_merge merge
where merge.id = mc.id and merge.id <> merge.keeper;

update public.menu_change mc
set reason = merge.merged_reason
from menu_change_merge merge
where merge.id = mc.id and merge.id = merge.keeper and mc.reason <> merge.merged_reason;

-- As políticas de RLS da alteração e dos gêneros da troca chegam ao mapa por
-- `meal_id`; saem antes da coluna e voltam, pelo caminho novo, mais abaixo.
drop policy menu_change_select on public.menu_change;
drop policy menu_change_cook_write on public.menu_change;
drop policy menu_change_food_item_select on public.menu_change_food_item;
drop policy menu_change_food_item_cook_write on public.menu_change_food_item;

alter table public.menu_change drop column meal_id;
alter table public.menu_change alter column meal_map_id set not null;
alter table public.menu_change
  add constraint menu_change_meal_map_id_key unique (meal_map_id);

-- ---------------------------------------------------------------------------
-- A trava de mapa bloqueado, pelo caminho novo
-- ---------------------------------------------------------------------------

-- Igual à de 20260907120100_regras_e_auditoria.sql, menos o caminho pela
-- refeição, que deixou de ter filhos: a alteração chega ao mapa direto.
create or replace function public.reject_write_on_locked_map()
returns trigger
language plpgsql
set search_path = public, pg_catalog
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
    when 'menu_change_id' then (
      select mc.meal_map_id from public.menu_change mc
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

create trigger meal_map_food_item_locked_guard
  before insert or update or delete on public.meal_map_food_item
  for each row execute function public.reject_write_on_locked_map('meal_map_id');

drop trigger menu_change_locked_guard on public.menu_change;
create trigger menu_change_locked_guard
  before insert or update or delete on public.menu_change
  for each row execute function public.reject_write_on_locked_map('meal_map_id');

-- ---------------------------------------------------------------------------
-- RLS: o recorte pelo mapa, sem passar pela refeição
-- ---------------------------------------------------------------------------

alter table public.meal_map_food_item enable row level security;

create policy meal_map_food_item_select on public.meal_map_food_item
  for select to authenticated
  using (exists (
    select 1 from public.meal_map mm
    where mm.id = meal_map_food_item.meal_map_id and mm.school_id = public.current_school_id()
  ));

create policy meal_map_food_item_cook_write on public.meal_map_food_item
  for all to authenticated
  using (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal_map mm
      where mm.id = meal_map_food_item.meal_map_id and mm.school_id = public.current_school_id()
    )
  )
  with check (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal_map mm
      where mm.id = meal_map_food_item.meal_map_id and mm.school_id = public.current_school_id()
    )
  );

create policy menu_change_select on public.menu_change
  for select to authenticated
  using (exists (
    select 1 from public.meal_map mm
    where mm.id = menu_change.meal_map_id and mm.school_id = public.current_school_id()
  ));

create policy menu_change_cook_write on public.menu_change
  for all to authenticated
  using (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal_map mm
      where mm.id = menu_change.meal_map_id and mm.school_id = public.current_school_id()
    )
  )
  with check (
    public.current_role_is('cook')
    and exists (
      select 1 from public.meal_map mm
      where mm.id = menu_change.meal_map_id and mm.school_id = public.current_school_id()
    )
  );

create policy menu_change_food_item_select on public.menu_change_food_item
  for select to authenticated
  using (exists (
    select 1 from public.menu_change mc
    join public.meal_map mm on mm.id = mc.meal_map_id
    where mc.id = menu_change_food_item.menu_change_id
      and mm.school_id = public.current_school_id()
  ));

create policy menu_change_food_item_cook_write on public.menu_change_food_item
  for all to authenticated
  using (
    public.current_role_is('cook')
    and exists (
      select 1 from public.menu_change mc
      join public.meal_map mm on mm.id = mc.meal_map_id
      where mc.id = menu_change_food_item.menu_change_id
        and mm.school_id = public.current_school_id()
    )
  )
  with check (
    public.current_role_is('cook')
    and exists (
      select 1 from public.menu_change mc
      join public.meal_map mm on mm.id = mc.meal_map_id
      where mc.id = menu_change_food_item.menu_change_id
        and mm.school_id = public.current_school_id()
    )
  );

-- ---------------------------------------------------------------------------
-- save_meal_map, com os gêneros e a alteração no dia
-- ---------------------------------------------------------------------------

-- Igual à de 20261001120000_versao_minima_do_app.sql, menos os gêneros e a
-- alteração dentro de cada refeição: os dois vêm no dia, em `food_items` e
-- `menu_change`, com a mesma forma de antes. A refeição traz só o tipo, o
-- cardápio previsto e a aceitação.
create or replace function public.save_meal_map(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  actor uuid := auth.uid();
  actor_school uuid;
  sent_id uuid;
  target_date date;
  edited_at timestamptz;
  is_non_school_day boolean;
  day_note text;
  served smallint;
  meals jsonb;
  meal_entry jsonb;
  day_items jsonb;
  change_entry jsonb;
  change_items jsonb;
  item_entry jsonb;
  map public.meal_map;
  current_change uuid;
  resolved_item public.food_item;
  item_quantity smallint;
  -- Indexado pelo identificador que o aparelho mandou, para que o mesmo gênero
  -- citado nos gêneros do dia e na alteração apareça uma vez só na resposta.
  catalog jsonb := '{}'::jsonb;
begin
  perform internal.reject_outdated_app();

  -- -------------------------------------------------------------------------
  -- Quem grava
  -- -------------------------------------------------------------------------
  if actor is null then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'Entre na sua conta para registrar o mapa.';
  end if;

  if not public.current_role_is('cook') then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'Só a merendeira registra o mapa.',
      hint = 'A direção consulta os mapas e reabre os que já saíram em documento.';
  end if;

  actor_school := public.current_school_id();
  if actor_school is null then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'Este acesso não está ligado a nenhuma escola.';
  end if;

  -- -------------------------------------------------------------------------
  -- O que chegou
  -- -------------------------------------------------------------------------
  sent_id := nullif(payload ->> 'id', '')::uuid;
  target_date := nullif(payload ->> 'map_date', '')::date;
  if target_date is null then
    raise exception using
      errcode = 'check_violation',
      message = 'O mapa precisa da data do dia.';
  end if;

  -- Relógio adiantado no aparelho ganharia toda convergência para sempre; a
  -- edição não pode ter acontecido depois de chegar.
  edited_at := least(
    coalesce(nullif(payload ->> 'updated_at', '')::timestamptz, now()),
    now()
  );

  is_non_school_day := coalesce((payload ->> 'non_school_day')::boolean, false);
  day_note := nullif(btrim(coalesce(payload ->> 'note', '')), '');
  served := nullif(payload ->> 'meals_served', '')::smallint;
  meals := coalesce(payload -> 'meals', '[]'::jsonb);
  day_items := coalesce(payload -> 'food_items', '[]'::jsonb);
  change_entry := payload -> 'menu_change';
  if change_entry is not null and jsonb_typeof(change_entry) <> 'object' then
    change_entry := null;
  end if;

  if jsonb_typeof(meals) <> 'array' then
    raise exception using
      errcode = 'check_violation',
      message = 'As refeições do dia precisam vir numa lista.';
  end if;

  if jsonb_typeof(day_items) <> 'array' then
    raise exception using
      errcode = 'check_violation',
      message = 'Os gêneros do dia precisam vir numa lista.';
  end if;

  -- A restrição da tabela já recusaria a linha incoerente, mas com a mensagem
  -- do banco; aqui a recusa sai na língua de quem lê (RN#1 da US006).
  if is_non_school_day then
    if day_note is null then
      raise exception using
        errcode = 'check_violation',
        message = 'Dia não letivo precisa de uma observação dizendo o motivo.';
    end if;
    if jsonb_array_length(meals) > 0
      or jsonb_array_length(day_items) > 0
      or change_entry is not null
    then
      raise exception using
        errcode = 'check_violation',
        message = 'Dia não letivo não tem refeições para registrar.';
    end if;
    served := null;
  else
    -- A observação é a do dia não letivo; no dia letivo ela não existe.
    day_note := null;
  end if;

  -- -------------------------------------------------------------------------
  -- O dia é a data, não o identificador
  -- -------------------------------------------------------------------------
  -- Dois aparelhos podem ter criado o mesmo dia offline, cada um com o seu
  -- UUID. Quem manda é (escola, data): o identificador que já está no servidor
  -- prevalece e volta na resposta para o aparelho adotá-lo.
  select * into map from public.meal_map
  where school_id = actor_school and map_date = target_date
  for update;

  if found then
    if map.locked then
      raise exception using
        errcode = 'check_violation',
        message = 'Este mapa já está em um documento gerado e não pode ser alterado.',
        hint = 'A direção pode reabrir o mapa para correção.';
    end if;

    -- Prevalece a edição mais recente (CA#3 da US011). Igual não é conflito: é
    -- o reenvio da fila, que reescreve o mesmo dia com o mesmo resultado.
    if map.updated_at > edited_at then
      return jsonb_build_object(
        'status', 'superseded',
        'meal_map_id', map.id,
        'sent_meal_map_id', sent_id,
        'map_date', map.map_date,
        'locked', map.locked,
        'updated_at', map.updated_at,
        'updated_by', map.updated_by,
        'food_items', '[]'::jsonb
      );
    end if;

    update public.meal_map set
      non_school_day = is_non_school_day,
      note = day_note,
      meals_served = served,
      updated_at = edited_at,
      updated_by = actor
    where id = map.id
    returning * into map;
  else
    begin
      insert into public.meal_map (
        id, school_id, map_date, non_school_day, note, meals_served,
        updated_at, updated_by
      )
      values (
        coalesce(sent_id, gen_random_uuid()), actor_school, target_date,
        is_non_school_day, day_note, served, edited_at, actor
      )
      returning * into map;
    exception when unique_violation then
      -- A janela entre o select e o insert: outro aparelho criou o mesmo dia
      -- agora. Devolver como falha temporária deixa a fila reenviar, e aí o
      -- caminho vira o de cima, com a comparação de datas.
      raise exception using
        errcode = 'serialization_failure',
        message = 'Outro aparelho gravou este dia neste instante.',
        hint = 'O envio será refeito.';
    end;
  end if;

  -- -------------------------------------------------------------------------
  -- Os filhos são substituídos, não reconciliados
  -- -------------------------------------------------------------------------
  -- Apagar e reinserir é o que dispensa marcar exclusões em quatro tabelas: o
  -- que veio no payload é o dia inteiro, e o que não veio deixou de existir.
  -- O cascade da alteração leva junto os gêneros da troca.
  delete from public.meal where meal_map_id = map.id;
  delete from public.meal_map_food_item where meal_map_id = map.id;
  delete from public.menu_change where meal_map_id = map.id;

  for meal_entry in select value from jsonb_array_elements(meals) loop
    if not (meal_entry ->> 'type' = any (enum_range(null::public.meal_type)::text[])) then
      raise exception using
        errcode = 'check_violation',
        message = format('Refeição desconhecida: "%s".', meal_entry ->> 'type');
    end if;

    -- O formato de antes da decisão 14. Ignorar os gêneros seria perdê-los
    -- calado; recusar deixa o dia guardado no aparelho que o mandou. O
    -- aplicativo velho nem chega aqui (a trava de versão vem antes); quem
    -- chega é uma aba da web aberta antes da mudança.
    if meal_entry ? 'food_items' or meal_entry ? 'menu_change' then
      raise exception using
        errcode = 'check_violation',
        message = 'Este dia veio no formato antigo, com os gêneros dentro da refeição.',
        hint = 'Recarregue a página ou atualize o aplicativo.';
    end if;

    insert into public.meal (id, meal_map_id, type, description, acceptance)
    values (
      coalesce(nullif(meal_entry ->> 'id', '')::uuid, gen_random_uuid()),
      map.id,
      (meal_entry ->> 'type')::public.meal_type,
      nullif(btrim(coalesce(meal_entry ->> 'description', '')), ''),
      nullif(meal_entry ->> 'acceptance', '')::public.acceptance_level
    );
  end loop;

  -- Gêneros utilizados no dia (decisão 14 da E4).
  for item_entry in select value from jsonb_array_elements(day_items) loop
    resolved_item := internal.resolve_food_item(actor_school, item_entry);
    item_quantity := internal.checked_quantity(item_entry, resolved_item.name);

    -- Dois nomes que normalizam para o mesmo gênero chegam como duas linhas
    -- e viram uma só; a última quantidade é a que vale.
    insert into public.meal_map_food_item (meal_map_id, food_item_id, quantity)
    values (map.id, resolved_item.id, item_quantity)
    on conflict (meal_map_id, food_item_id) do update set quantity = excluded.quantity;

    catalog := internal.remember_food_item(catalog, item_entry, resolved_item);
  end loop;

  -- A alteração do cardápio: no máximo uma por dia (decisão 14 da E4).
  if change_entry is not null then
    change_items := coalesce(change_entry -> 'food_items', '[]'::jsonb);

    if jsonb_typeof(change_items) <> 'array' or jsonb_array_length(change_items) = 0 then
      -- A troca sem os gêneros que entraram não descreve troca nenhuma, e é
      -- justamente essa a coluna que o formulário oficial pede preenchida.
      raise exception using
        errcode = 'check_violation',
        message = 'A alteração do cardápio precisa dos gêneros que entraram no lugar.';
    end if;

    current_change := coalesce(nullif(change_entry ->> 'id', '')::uuid, gen_random_uuid());

    insert into public.menu_change (id, meal_map_id, reason)
    values (current_change, map.id, btrim(coalesce(change_entry ->> 'reason', '')));

    for item_entry in select value from jsonb_array_elements(change_items) loop
      resolved_item := internal.resolve_food_item(actor_school, item_entry);
      item_quantity := internal.checked_quantity(item_entry, resolved_item.name);

      insert into public.menu_change_food_item (menu_change_id, food_item_id, quantity)
      values (current_change, resolved_item.id, item_quantity)
      on conflict (menu_change_id, food_item_id) do update set quantity = excluded.quantity;

      catalog := internal.remember_food_item(catalog, item_entry, resolved_item);
    end loop;
  end if;

  return jsonb_build_object(
    'status', 'saved',
    'meal_map_id', map.id,
    'sent_meal_map_id', sent_id,
    'map_date', map.map_date,
    'locked', map.locked,
    'updated_at', map.updated_at,
    'updated_by', map.updated_by,
    'food_items', coalesce(
      (select jsonb_agg(value) from jsonb_each(catalog)), '[]'::jsonb
    )
  );
end;
$$;

comment on function public.save_meal_map is
  'Grava o dia inteiro numa operação só: upsert do mapa pela data, substituição dos filhos e criação dos gêneros que faltarem (decisão 9 da E4). Os gêneros e a alteração são do dia (decisão 14 da E4). Recusa o aplicativo abaixo da versão mínima (decisão 12 da E6). Devolve o que aconteceu, inclusive quando o servidor tem edição mais recente.';
