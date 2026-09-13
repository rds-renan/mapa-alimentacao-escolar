-- A gravação do dia como unidade atômica (decisão 9 da E4).
--
-- O dia inteiro — mapa, refeições, alteração do cardápio e gêneros utilizados —
-- sobe numa chamada só: ou grava tudo, ou não grava nada. É a operação que a
-- fila de envio do cliente chama (decisão 3 da E5), e é por isso que ela ficou
-- para esta etapa: o contrato nasce junto com quem o consome.
--
-- O que ela resolve, e que nenhuma restrição de coluna alcançava:
--   * o dia é identificado pela data, não pelo UUID do aparelho;
--   * os filhos são substituídos pelos enviados, sem marcar exclusões;
--   * o gênero que ainda não existe nasce aqui, e o que já existe é adotado;
--   * o conflito entre aparelhos é decidido num lugar só, pela última edição.

-- ---------------------------------------------------------------------------
-- Apoio, num schema fora da API
-- ---------------------------------------------------------------------------

-- As peças internas da gravação vivem aqui e não no public porque o PostgREST
-- publica como rota tudo que está nos schemas expostos, e o public é um deles
-- (api.schemas, em supabase/config.toml). Resolver o gênero, validar a
-- quantidade e montar a resposta não são operações do produto: são metade de
-- uma operação, e uma rota que executa metade de uma gravação é superfície que
-- não precisa existir.
--
-- Esconder por posição, e não por permissão. Deixá-las no public e revogar o
-- execute daria o mesmo resultado no papel, mas as rotas continuariam
-- existindo, recusando caso a caso — e recusa depende de o Supabase não voltar
-- a conceder execute por default privilege na próxima criação de função, que é
-- exatamente como elas ganharam permissão da primeira vez. Aqui não há o que
-- revogar.
--
-- Nada recebe usage neste schema: quem entra é save_meal_map, que roda como o
-- dono.
create schema if not exists internal;

comment on schema internal is
  'Peças internas das operações do public. Não é exposto pela API (ver api.schemas em supabase/config.toml).';

-- A mesma normalização da coluna gerada food_item.normalized_name. Existe para
-- que a busca use exatamente a regra que o índice único usa — se as duas
-- expressões divergirem, a função tenta inserir o que o índice recusa.
create or replace function internal.normalized_food_item_name(value text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select lower(btrim(regexp_replace(value, '\s+', ' ', 'g')));
$$;

-- Devolve o gênero que a refeição aponta, criando-o se ainda não existir.
--
-- A ordem importa: primeiro o identificador (é o caminho do reenvio, que
-- precisa achar o que ele mesmo criou), depois o nome (é o caminho da
-- convergência, quando duas merendeiras cadastram o mesmo gênero offline) e só
-- então a criação. Adotar o existente é o que impede "Arroz" duas vezes.
--
-- Não é security definer de propósito: chamada de dentro de save_meal_map, roda
-- como o dono, e só a partir de uma escola que já foi conferida lá.
create or replace function internal.resolve_food_item(p_school_id uuid, p_item jsonb)
returns public.food_item
language plpgsql
set search_path = public, pg_catalog
as $$
declare
  sent_id uuid := nullif(p_item ->> 'food_item_id', '')::uuid;
  item_name text := btrim(coalesce(p_item ->> 'name', ''));
  item_unit text := btrim(coalesce(p_item ->> 'unit', ''));
  found_item public.food_item;
begin
  if sent_id is not null then
    select * into found_item from public.food_item
    where id = sent_id and school_id = p_school_id;
    if found then
      return found_item;
    end if;
  end if;

  if item_name = '' then
    raise exception using
      errcode = 'check_violation',
      message = 'Um dos gêneros enviados não tem nome nem cadastro no catálogo.';
  end if;

  select * into found_item from public.food_item
  where school_id = p_school_id
    and normalized_name = internal.normalized_food_item_name(item_name);
  if found then
    return found_item;
  end if;

  if item_unit = '' then
    raise exception using
      errcode = 'check_violation',
      message = format('O gênero "%s" ainda não está no catálogo e precisa de uma unidade.', item_name);
  end if;

  -- O identificador só serve para nascer se ainda não for de ninguém. Se já
  -- existe e não é desta escola, o gênero nasce com identificador novo — e não
  -- com a chave alheia, que faria a gravação morrer numa mensagem de banco.
  if sent_id is not null and exists (select 1 from public.food_item where id = sent_id) then
    sent_id := null;
  end if;

  -- Duas gravações simultâneas podem chegar aqui com o mesmo nome novo; quem
  -- perder a corrida adota o gênero que a outra acabou de criar.
  begin
    insert into public.food_item (id, school_id, name, default_unit)
    values (coalesce(sent_id, gen_random_uuid()), p_school_id, item_name, item_unit)
    returning * into found_item;
  exception when unique_violation then
    select * into found_item from public.food_item
    where school_id = p_school_id
      and normalized_name = internal.normalized_food_item_name(item_name);
    if not found then
      raise;
    end if;
  end;

  return found_item;
end;
$$;

comment on function internal.resolve_food_item is
  'Peça interna de save_meal_map: acha o gênero por identificador, depois por nome, e só então cria (decisão 9).';


-- A quantidade é inteira, positiva e obrigatória quando o gênero foi citado
-- (RN#1 da US003). A restrição da tabela já recusaria, mas a mensagem dela não
-- diz de qual gênero se trata — e a tela precisa apontar a linha errada.
create or replace function internal.checked_quantity(p_item jsonb, p_name text)
returns smallint
language plpgsql
set search_path = pg_catalog
as $$
declare
  raw_value text := nullif(btrim(coalesce(p_item ->> 'quantity', '')), '');
  value smallint;
begin
  if raw_value is null or raw_value !~ '^\d+$' then
    raise exception using
      errcode = 'check_violation',
      message = format('A quantidade de "%s" precisa ser um número inteiro.', p_name);
  end if;

  value := raw_value::smallint;
  if value <= 0 then
    raise exception using
      errcode = 'check_violation',
      message = format('A quantidade de "%s" precisa ser maior que zero.', p_name);
  end if;

  return value;
end;
$$;

comment on function internal.checked_quantity is
  'Peça interna de save_meal_map: valida a quantidade dizendo de qual gênero se trata.';


-- Acumula, para a resposta, o gênero que valeu para cada item enviado. A chave
-- é o identificador que o aparelho mandou, para que o mesmo gênero citado em
-- duas refeições apareça uma vez só e para que o aparelho saiba qual dos seus
-- identificadores foi trocado por qual.
create or replace function internal.remember_food_item(
  p_catalog jsonb, p_item jsonb, p_food_item public.food_item
)
returns jsonb
language sql
set search_path = pg_catalog
as $$
  select p_catalog || jsonb_build_object(
    coalesce(nullif(p_item ->> 'food_item_id', ''), p_food_item.id::text),
    jsonb_build_object(
      'sent_id', nullif(p_item ->> 'food_item_id', ''),
      'id', p_food_item.id,
      'name', p_food_item.name,
      'unit', p_food_item.default_unit,
      -- Nasceu nesta transação: é gênero novo, e o catálogo local precisa dele.
      'created', p_food_item.created_at >= transaction_timestamp()
    )
  );
$$;

comment on function internal.remember_food_item is
  'Peça interna de save_meal_map: monta a lista de gêneros que a resposta devolve ao aparelho.';


-- ---------------------------------------------------------------------------
-- O carimbo de última edição passa a ser dado, não relógio do servidor
-- ---------------------------------------------------------------------------

-- Substitui a versão da migration 20260907120100. Mudou uma coisa: quando quem
-- escreve é o servidor — a função de gravação do dia, a edge function da
-- geração, a manutenção local —, o gatilho não carimba nada.
--
-- O motivo é o CA#3 da US011. O carimbo decide qual edição prevalece, e a
-- pergunta é "quando a merendeira mexeu no mapa", não "quando o servidor
-- recebeu". Um mapa preenchido na sexta sem sinal e enviado no domingo tem que
-- perder para a correção feita no sábado pela colega — carimbar a chegada
-- inverteria o resultado. Quem manda a data da edição é o aparelho, e é
-- save_meal_map quem a grava; por isso o gatilho sai da frente.
--
-- O efeito colateral que a E4 já tinha previsto continua valendo pela mesma
-- razão: reabertura não é edição e não pode mover o carimbo.
create or replace function public.stamp_meal_map_update()
returns trigger
language plpgsql
as $$
begin
  if public.is_service() then
    return new;
  end if;

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

-- ---------------------------------------------------------------------------
-- A gravação do dia
-- ---------------------------------------------------------------------------

-- Formato do que entra:
--
--   {
--     "id": "uuid gerado no aparelho",
--     "map_date": "2026-09-10",
--     "updated_at": "2026-09-10T18:30:00-03:00",
--     "non_school_day": false,
--     "note": null,
--     "meals_served": 312,
--     "meals": [
--       {
--         "id": "uuid",
--         "type": "morning_snack | lunch | afternoon_snack",
--         "description": "o cardápio previsto, em texto livre",
--         "acceptance": "great | good | poor",
--         "food_items": [
--           { "food_item_id": "uuid", "name": "Arroz", "unit": "quilo", "quantity": 3 }
--         ],
--         "menu_change": {
--           "reason": "por que houve a troca",
--           "food_items": [ ... ]
--         }
--       }
--     ]
--   }
--
-- E do que sai:
--
--   {
--     "status": "saved" | "superseded",
--     "meal_map_id": "...", "sent_meal_map_id": "...",
--     "map_date": "...", "locked": false,
--     "updated_at": "...", "updated_by": "...",
--     "food_items": [ { "sent_id": "...", "id": "...", "name": "...",
--                       "unit": "...", "created": true } ]
--   }
--
-- "superseded" quer dizer que o servidor tem edição mais recente e nada foi
-- gravado: o cliente recarrega o dia e avisa a usuária, nunca resolve calado
-- (CA#3 da US011). A lista de gêneros devolve o identificador que valeu, para
-- o aparelho adotá-lo no lugar do que ele tinha inventado.
--
-- É security definer, como unlock_meal_map: por isso não passa pelas políticas
-- de acesso e faz as verificações de perfil e de escola aqui dentro, na
-- primeira coisa que executa. A escola vem sempre do perfil de quem chamou —
-- o payload não tem como dizer em que escola quer gravar.
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
  'Grava o dia inteiro numa operação só: upsert do mapa pela data, substituição dos filhos e criação dos gêneros que faltarem (decisão 9 da E4). Devolve o que aconteceu, inclusive quando o servidor tem edição mais recente.';

-- save_meal_map continua com o execute que o Supabase dá a todo mundo no
-- public, como unlock_meal_map. Aqui a rota TEM que existir — é por ela que o
-- aplicativo grava —, então quem recusa quem é a própria função, nas primeiras
-- linhas, com a mensagem que a pessoa lê. Fechar a porta devolveria um erro de
-- permissão sem texto, e quem chegou sem sessão precisa ser mandado ao login,
-- não informado de que a função existe e não é dele.
