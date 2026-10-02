-- A trava de versão mínima do aplicativo (decisão 12 da E6, issue #113).
--
-- Um aplicativo instalado não aprende comportamento novo: ele só respeita a
-- trava que já veio com ele. Por isso ela entra antes do primeiro APK — é a
-- única que o aplicativo mais antigo em uso vai conhecer. Sem ela, a primeira
-- migration que mudar o contrato da gravação encontra um aplicativo velho
-- mandando o que o banco não aceita mais, e a fila dele tenta para sempre.
--
-- Duas peças:
--   * a versão mínima, numa tabela de uma linha que quem está logado lê — o
--     aplicativo confere ao abrir e antes de mandar a fila;
--   * a recusa na save_meal_map, pelo cabeçalho que o aplicativo manda em toda
--     chamada. A web não manda cabeçalho e segue como está.
--
-- A regra de operação é uma só: o APK novo sai ANTES da migration que sobe o
-- mínimo. O contrário tranca todo mundo para fora, sem versão para onde
-- atualizar. Ver docs/06-app/versao-minima.md.

-- ---------------------------------------------------------------------------
-- A versão mínima
-- ---------------------------------------------------------------------------

-- A versão comparada é o número depois do "+" no pubspec (o versionCode do
-- Android): só cresce, de um em um, e a Action de release recusa a tag em que
-- ele não cresceu. O nome (0.1.0) é para gente ler e não se compara.
--
-- Uma linha só, garantida pela chave: a trava vale para o aplicativo, não para
-- uma escola — o APK é o mesmo para todas.
create table public.app_version (
  singleton boolean primary key default true check (singleton),
  minimum_build integer not null check (minimum_build >= 1),
  updated_at timestamptz not null default now()
);

comment on table public.app_version is
  'A versão mínima do aplicativo que o banco aceita (decisão 12 da E6). Uma linha só. Sobe por migration, e só depois de o APK que a satisfaz estar publicado.';
comment on column public.app_version.minimum_build is
  'O versionCode mínimo — o número depois do "+" no pubspec do aplicativo.';

-- O primeiro APK é o 1: a trava nasce sem recusar ninguém.
insert into public.app_version (minimum_build) values (1);

alter table public.app_version enable row level security;

-- Legível por quem estiver logado; escrita, só por migration. Não há política
-- de escrita, e o que o Supabase concede por padrão sai também, para que a
-- ausência de política não seja a única coisa entre a API e esta linha.
create policy app_version_select on public.app_version
  for select to authenticated
  using (true);

revoke all on public.app_version from anon, authenticated;
grant select on public.app_version to authenticated;

-- ---------------------------------------------------------------------------
-- A recusa pelo cabeçalho
-- ---------------------------------------------------------------------------

-- O aplicativo manda x-mae-app-build com o versionCode dele em toda chamada; o
-- PostgREST entrega os cabeçalhos da requisição em request.headers. Sem o
-- cabeçalho é a web, e passa. Com ele abaixo do mínimo — ou ilegível, que não
-- vem de aplicativo nenhum que saiu daqui —, recusa.
--
-- O código PT426 é a convenção do PostgREST para escolher o status HTTP da
-- resposta: sai como 426 Upgrade Required, que é exatamente o caso, e o
-- aplicativo o reconhece como "atualize", diferente de qualquer recusa do dia.
-- Interna, como as outras peças da gravação: não é operação do produto.
create or replace function internal.reject_outdated_app()
returns void
language plpgsql
stable
set search_path = public, pg_catalog
as $$
declare
  sent text := nullif(
    btrim(coalesce(current_setting('request.headers', true), '{}')::json ->> 'x-mae-app-build'),
    ''
  );
  minimum integer;
begin
  if sent is null then
    return;
  end if;

  select minimum_build into minimum from public.app_version;

  if sent !~ '^\d{1,9}$' or sent::integer < coalesce(minimum, 1) then
    raise exception using
      errcode = 'PT426',
      message = 'Esta versão do aplicativo está desatualizada.',
      detail = format('Versão mínima: %s.', minimum),
      hint = 'Atualize o MAE. O que está no aparelho não se perde.';
  end if;
end;
$$;

comment on function internal.reject_outdated_app is
  'Peça interna de save_meal_map: recusa o aplicativo abaixo da versão mínima pelo cabeçalho x-mae-app-build (decisão 12 da E6).';

-- ---------------------------------------------------------------------------
-- save_meal_map, com a trava na entrada
-- ---------------------------------------------------------------------------

-- Igual à de 20260911120000_gravacao_atomica_do_dia.sql, com uma linha a mais
-- no começo: a conferência da versão. Vem antes de tudo, inclusive de quem
-- grava, porque um aplicativo velho não deve receber nenhuma outra recusa —
-- qualquer outra o faria acreditar que o problema é o dia.
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
  change_entry jsonb;
  change_items jsonb;
  item_entry jsonb;
  map public.meal_map;
  current_meal uuid;
  current_change uuid;
  resolved_item public.food_item;
  item_quantity smallint;
  -- Indexado pelo identificador que o aparelho mandou, para que o mesmo gênero
  -- citado em duas refeições apareça uma vez só na resposta.
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

  if jsonb_typeof(meals) <> 'array' then
    raise exception using
      errcode = 'check_violation',
      message = 'As refeições do dia precisam vir numa lista.';
  end if;

  -- A restrição da tabela já recusaria a linha incoerente, mas com a mensagem
  -- do banco; aqui a recusa sai na língua de quem lê (RN#1 da US006).
  if is_non_school_day then
    if day_note is null then
      raise exception using
        errcode = 'check_violation',
        message = 'Dia não letivo precisa de uma observação dizendo o motivo.';
    end if;
    if jsonb_array_length(meals) > 0 then
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
  -- O cascade leva junto gêneros utilizados, alteração e gêneros da alteração.
  delete from public.meal where meal_map_id = map.id;

  for meal_entry in select value from jsonb_array_elements(meals) loop
    if not (meal_entry ->> 'type' = any (enum_range(null::public.meal_type)::text[])) then
      raise exception using
        errcode = 'check_violation',
        message = format('Refeição desconhecida: "%s".', meal_entry ->> 'type');
    end if;

    current_meal := coalesce(nullif(meal_entry ->> 'id', '')::uuid, gen_random_uuid());

    insert into public.meal (id, meal_map_id, type, description, acceptance)
    values (
      current_meal,
      map.id,
      (meal_entry ->> 'type')::public.meal_type,
      nullif(btrim(coalesce(meal_entry ->> 'description', '')), ''),
      nullif(meal_entry ->> 'acceptance', '')::public.acceptance_level
    );

    -- Gêneros utilizados na refeição.
    for item_entry in
      select value from jsonb_array_elements(coalesce(meal_entry -> 'food_items', '[]'::jsonb))
    loop
      resolved_item := internal.resolve_food_item(actor_school, item_entry);
      item_quantity := internal.checked_quantity(item_entry, resolved_item.name);

      -- Dois nomes que normalizam para o mesmo gênero chegam como duas linhas
      -- e viram uma só; a última quantidade é a que vale.
      insert into public.meal_food_item (meal_id, food_item_id, quantity)
      values (current_meal, resolved_item.id, item_quantity)
      on conflict (meal_id, food_item_id) do update set quantity = excluded.quantity;

      catalog := internal.remember_food_item(catalog, item_entry, resolved_item);
    end loop;

    -- A alteração do cardápio: no máximo uma por refeição (decisão 7 da E4).
    change_entry := meal_entry -> 'menu_change';
    if change_entry is not null and jsonb_typeof(change_entry) = 'object' then
      change_items := coalesce(change_entry -> 'food_items', '[]'::jsonb);

      if jsonb_typeof(change_items) <> 'array' or jsonb_array_length(change_items) = 0 then
        -- A troca sem os gêneros que entraram não descreve troca nenhuma, e é
        -- justamente essa a coluna que o formulário oficial pede preenchida.
        raise exception using
          errcode = 'check_violation',
          message = 'A alteração do cardápio precisa dos gêneros que entraram no lugar.';
      end if;

      current_change := coalesce(nullif(change_entry ->> 'id', '')::uuid, gen_random_uuid());

      insert into public.menu_change (id, meal_id, reason)
      values (current_change, current_meal, btrim(coalesce(change_entry ->> 'reason', '')));

      for item_entry in select value from jsonb_array_elements(change_items) loop
        resolved_item := internal.resolve_food_item(actor_school, item_entry);
        item_quantity := internal.checked_quantity(item_entry, resolved_item.name);

        insert into public.menu_change_food_item (menu_change_id, food_item_id, quantity)
        values (current_change, resolved_item.id, item_quantity)
        on conflict (menu_change_id, food_item_id) do update set quantity = excluded.quantity;

        catalog := internal.remember_food_item(catalog, item_entry, resolved_item);
      end loop;
    end if;
  end loop;

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
  'Grava o dia inteiro numa operação só: upsert do mapa pela data, substituição dos filhos e criação dos gêneros que faltarem (decisão 9 da E4). Recusa o aplicativo abaixo da versão mínima (decisão 12 da E6). Devolve o que aconteceu, inclusive quando o servidor tem edição mais recente.';
