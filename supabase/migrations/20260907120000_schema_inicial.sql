-- Schema inicial do MAE — Mapa da Alimentação Escolar.
--
-- Projeto físico da etapa E4, derivado do modelo ER em
-- docs/04-banco-de-dados/modelo-er.md. Identificadores em inglês,
-- comentários e conteúdo em português (decisão 13).

-- ---------------------------------------------------------------------------
-- Tipos enumerados
-- ---------------------------------------------------------------------------

-- Perfis do sistema: a direção e a merendeira (RN#1 da US016).
create type public.user_role as enum ('admin', 'cook');

-- As três refeições de um dia letivo (RN#1 da US001).
create type public.meal_type as enum ('morning_snack', 'lunch', 'afternoon_snack');

-- Grau de aceitação, por refeição (CA#2 da US004).
create type public.acceptance_level as enum ('great', 'good', 'poor');

-- Situação da geração de um documento (decisão 10).
create type public.document_status as enum ('processing', 'available', 'failed');

-- ---------------------------------------------------------------------------
-- Escola e pessoas
-- ---------------------------------------------------------------------------

create table public.school (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text not null,
  school_year smallint not null,
  created_at timestamptz not null default now(),
  constraint school_name_not_blank check (btrim(name) <> ''),
  constraint school_year_range check (school_year between 2000 and 2100)
);

comment on table public.school is
  'Escola: raiz de tudo e recorte de visibilidade dos perfis (US015).';

-- Estende a conta do serviço de autenticação; credenciais ficam lá (decisão 2).
create table public.profile (
  id uuid primary key references auth.users (id) on delete restrict,
  school_id uuid not null references public.school (id) on delete restrict,
  name text not null,
  email text not null unique,
  role public.user_role not null,
  active boolean not null default true,
  last_access timestamptz,
  created_at timestamptz not null default now(),
  constraint profile_name_not_blank check (btrim(name) <> '')
);

comment on table public.profile is
  'Perfil de acesso. Desativar é active = false; a linha nunca é removida (CA#2 da US016).';

create index profile_school_idx on public.profile (school_id);

-- ---------------------------------------------------------------------------
-- Catálogo de gêneros
-- ---------------------------------------------------------------------------

create table public.food_item (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.school (id) on delete restrict,
  name text not null,
  -- Mantido pelo banco: é ele que carrega a unicidade, para que "Arroz" e
  -- "arroz " não entrem como itens diferentes quando as duas merendeiras
  -- cadastram o mesmo gênero de aparelhos diferentes (decisão 9).
  normalized_name text generated always as
    (lower(btrim(regexp_replace(name, '\s+', ' ', 'g')))) stored,
  default_unit text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint food_item_name_not_blank check (btrim(name) <> ''),
  constraint food_item_unit_not_blank check (btrim(default_unit) <> '')
);

comment on table public.food_item is
  'Gênero alimentício do catálogo da escola, com a sua unidade padrão (US009).';

create unique index food_item_school_name_key
  on public.food_item (school_id, normalized_name);

-- ---------------------------------------------------------------------------
-- O mapa do dia
-- ---------------------------------------------------------------------------

create table public.meal_map (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.school (id) on delete restrict,
  map_date date not null,
  non_school_day boolean not null default false,
  note text,
  meals_served smallint,
  -- Único estado armazenado; os demais são derivados na leitura (decisão 4).
  locked boolean not null default false,
  updated_by uuid references public.profile (id) on delete restrict,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  -- Dia não letivo tem observação e não conta refeições; dia letivo não tem
  -- observação de dia não letivo (RN#1 da US006).
  constraint meal_map_day_shape check (
    case
      when non_school_day then btrim(coalesce(note, '')) <> '' and meals_served is null
      else note is null
    end
  ),
  constraint meal_map_meals_served_positive check (meals_served is null or meals_served > 0)
);

comment on table public.meal_map is
  'Mapa de um dia. Um por data em cada escola; letivo ou não letivo, nunca os dois.';

create unique index meal_map_school_date_key on public.meal_map (school_id, map_date);
create index meal_map_locked_idx on public.meal_map (school_id, locked);

create table public.meal (
  id uuid primary key default gen_random_uuid(),
  meal_map_id uuid not null references public.meal_map (id) on delete cascade,
  type public.meal_type not null,
  -- O cardápio previsto, em texto livre. Permanece fiel ao previsto mesmo
  -- quando houve troca — é isso que dá sentido à justificativa (decisão 7).
  description text,
  acceptance public.acceptance_level
);

comment on table public.meal is
  'Uma das três refeições do dia. description e acceptance aceitam nulo: o registro pode ficar parcial (CA#3 da US001).';

create unique index meal_map_type_key on public.meal (meal_map_id, type);

-- ---------------------------------------------------------------------------
-- Gêneros da refeição e da alteração
-- ---------------------------------------------------------------------------

-- Alimenta a coluna GÊNEROS UTILIZADOS do documento, consolidada por dia na
-- geração; aqui é capturada por refeição (decisão 7).
create table public.meal_food_item (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.meal (id) on delete cascade,
  food_item_id uuid not null references public.food_item (id) on delete restrict,
  quantity smallint not null,
  constraint meal_food_item_quantity_positive check (quantity > 0)
);

create unique index meal_food_item_key
  on public.meal_food_item (meal_id, food_item_id);
create index meal_food_item_food_idx on public.meal_food_item (food_item_id);

-- A alteração registra o que entrou, nunca o que saiu: o formulário oficial
-- não pede o item substituído (decisão 7). Uma por refeição.
create table public.menu_change (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null unique references public.meal (id) on delete cascade,
  reason text not null,
  constraint menu_change_reason_not_blank check (btrim(reason) <> '')
);

comment on table public.menu_change is
  'Alteração do cardápio: o motivo em texto livre. Os gêneros usados na troca estão em menu_change_food_item.';

-- Alimenta a coluna "em caso de alterações, descreva os gêneros utilizados e
-- as quantidades" do documento oficial.
create table public.menu_change_food_item (
  id uuid primary key default gen_random_uuid(),
  menu_change_id uuid not null references public.menu_change (id) on delete cascade,
  food_item_id uuid not null references public.food_item (id) on delete restrict,
  quantity smallint not null,
  constraint menu_change_food_item_quantity_positive check (quantity > 0)
);

create unique index menu_change_food_item_key
  on public.menu_change_food_item (menu_change_id, food_item_id);
create index menu_change_food_item_food_idx
  on public.menu_change_food_item (food_item_id);

-- ---------------------------------------------------------------------------
-- Modelo oficial e documentos gerados
-- ---------------------------------------------------------------------------

create table public.document_template (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.school (id) on delete restrict,
  file_name text not null,
  file_path text not null,
  uploaded_by uuid references public.profile (id) on delete restrict,
  uploaded_at timestamptz not null default now(),
  is_current boolean not null default true
);

comment on table public.document_template is
  'Versão do modelo oficial. As anteriores ficam, para saber com qual modelo cada documento saiu (decisão 11).';

-- Exatamente uma versão vigente por escola (RN#1 da US015).
create unique index document_template_current_key
  on public.document_template (school_id) where is_current;

create table public.generated_document (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.school (id) on delete restrict,
  document_template_id uuid not null references public.document_template (id) on delete restrict,
  requested_by uuid not null references public.profile (id) on delete restrict,
  status public.document_status not null default 'processing',
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  file_path text,
  expires_at timestamptz,
  -- O registro é permanente; o arquivo, não (decisão 10).
  constraint generated_document_status_shape check (
    case status
      when 'processing' then completed_at is null and file_path is null and expires_at is null
      when 'available' then completed_at is not null and file_path is not null and expires_at is not null
      when 'failed' then completed_at is not null and file_path is null
    end
  )
);

comment on table public.generated_document is
  'Registro de cada geração. Permanece depois de o arquivo expirar — é o que sustenta a lista de documentos (US021, US022).';

create index generated_document_school_idx
  on public.generated_document (school_id, requested_at desc);

create table public.document_meal_map (
  generated_document_id uuid not null references public.generated_document (id) on delete cascade,
  meal_map_id uuid not null references public.meal_map (id) on delete restrict,
  primary key (generated_document_id, meal_map_id)
);

comment on table public.document_meal_map is
  'Ligação pura: é dela que derivam o período e a quantidade de mapas de um documento.';

create index document_meal_map_map_idx on public.document_meal_map (meal_map_id);

-- ---------------------------------------------------------------------------
-- Desbloqueio
-- ---------------------------------------------------------------------------

create table public.meal_map_unlock (
  id uuid primary key default gen_random_uuid(),
  meal_map_id uuid not null references public.meal_map (id) on delete restrict,
  unlocked_by uuid not null references public.profile (id) on delete restrict,
  unlocked_at timestamptz not null default now(),
  reason text not null,
  constraint meal_map_unlock_reason_not_blank check (btrim(reason) <> '')
);

comment on table public.meal_map_unlock is
  'Histórico permanente de reaberturas. Somente inserção (RNF#1 da US023).';

create index meal_map_unlock_map_idx
  on public.meal_map_unlock (meal_map_id, unlocked_at desc);
