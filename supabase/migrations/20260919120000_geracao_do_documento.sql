-- A geração do documento oficial, do lado do banco (US012, US013).
--
-- O trabalho de arquivo é da Edge Function `generate-document`: ela lê o modelo
-- vigente no balde privado, preenche e guarda. O que é regra do produto — quem
-- pode pedir, com qual modelo, o que entra no documento e quando os mapas
-- ficam bloqueados — está aqui, porque regra de auditoria precisa valer no
-- banco e não só em quem chama (decisão 5 da E4).
--
-- São três passos, e a divisão não é estética: entre o pedido e o arquivo
-- pronto existe uma geração que pode falhar, e o registro tem de sobreviver a
-- ela (decisão 10 da E4).
--
--   start_document_generation     valida, registra 'processing' e amarra os mapas
--   complete_document_generation  publica o arquivo e bloqueia os mapas
--   fail_document_generation      registra a falha, sem bloquear nada
--
-- O bloqueio entra na publicação, e não no pedido. A decisão 5 da E4 o punha na
-- mesma transação do registro; o que ela não previa é o caminho da falha —
-- bloquear no pedido obrigaria a desbloquear sozinho quando a geração
-- falhasse, e desbloqueio sem rastro é exatamente o que a US023 não admite.
-- Bloquear junto com a publicação mantém a regra de pé ("o que saiu em
-- documento não se edita") e deixa a falha sem efeito colateral nenhum. A
-- janela em que um mapa ainda aceita edição durante a geração é o tempo do
-- preenchimento — 336 ms para um mês inteiro, medidos no spike.
--
-- As três vivem no public, e não no schema internal da gravação do dia, porque
-- aqui quem chama é a Edge Function pela API: uma função escondida por posição
-- seria inalcançável. O que as protege é o guarda de is_service() em cada uma,
-- somado à revogação do execute no fim do arquivo.

-- ---------------------------------------------------------------------------
-- O pedido
-- ---------------------------------------------------------------------------

create or replace function public.start_document_generation(
  p_school_id uuid,
  p_requested_by uuid,
  p_meal_map_ids uuid[]
)
returns public.generated_document
language plpgsql
as $$
declare
  template_id uuid;
  wanted uuid[];
  document public.generated_document;
begin
  if not public.is_service() then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'A geração do documento é do servidor.';
  end if;

  -- Sem duplicatas: a mesma data pedida duas vezes é um dia só no documento, e
  -- a chave primária de document_meal_map recusaria o segundo.
  select array_agg(distinct pedido) into wanted
  from unnest(p_meal_map_ids) as pedido;

  if wanted is null then
    raise exception using
      errcode = 'check_violation',
      message = 'Selecione ao menos um dia para gerar o documento.';
  end if;

  -- Quem pede é a merendeira da escola. A direção não gera documento
  -- (RN#1 da US022), e o perfil desativado não faz nada.
  if not exists (
    select 1 from public.profile
    where id = p_requested_by
      and school_id = p_school_id
      and active
      and role = 'cook'
  ) then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'Só a merendeira gera o documento do mapa.';
  end if;

  -- Sempre o modelo vigente (RN#1 da US015). Guardá-lo no registro é o que
  -- permite saber, depois, com qual modelo cada documento saiu (decisão 11).
  select id into template_id
  from public.document_template
  where school_id = p_school_id and is_current;

  if template_id is null then
    raise exception using
      errcode = 'check_violation',
      message = 'A escola ainda não tem um modelo oficial cadastrado.',
      hint = 'A direção envia o modelo na área de administração.';
  end if;

  -- Os dias têm de existir e ser desta escola. Um mapa já bloqueado é aceito
  -- de propósito: depois de uma correção, o documento do período é gerado de
  -- novo com os outros dias ainda bloqueados (CA#4 da US023).
  if (
    select count(*) from public.meal_map
    where id = any (wanted) and school_id = p_school_id
  ) <> array_length(wanted, 1) then
    raise exception using
      errcode = 'check_violation',
      message = 'Algum dia selecionado não existe mais.',
      hint = 'Recarregue o mês e tente de novo.';
  end if;

  insert into public.generated_document (school_id, document_template_id, requested_by)
  values (p_school_id, template_id, p_requested_by)
  returning * into document;

  insert into public.document_meal_map (generated_document_id, meal_map_id)
  select document.id, incluido from unnest(wanted) as incluido;

  return document;
end;
$$;

comment on function public.start_document_generation is
  'Abre a geração: valida o pedido, registra o documento em processamento e amarra os mapas incluídos. Não bloqueia nada — quem bloqueia é complete_document_generation.';

-- ---------------------------------------------------------------------------
-- A publicação, que é onde o bloqueio entra
-- ---------------------------------------------------------------------------

create or replace function public.complete_document_generation(
  p_document_id uuid,
  p_file_path text
)
returns public.generated_document
language plpgsql
as $$
declare
  document public.generated_document;
begin
  if not public.is_service() then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'A geração do documento é do servidor.';
  end if;

  if btrim(coalesce(p_file_path, '')) = '' then
    raise exception using
      errcode = 'check_violation',
      message = 'O documento publicado precisa do caminho do arquivo.';
  end if;

  -- A janela de validade mora aqui, e não em quem chama: é a mesma data que a
  -- política do balde usa para deixar de servir o arquivo (RN#2 da US012). O
  -- link assinado é derivado dela, não o contrário.
  update public.generated_document
  set status = 'available',
      completed_at = now(),
      file_path = p_file_path,
      expires_at = now() + interval '7 days'
  where id = p_document_id and status = 'processing'
  returning * into document;

  if not found then
    raise exception using
      errcode = 'check_violation',
      message = 'Esta geração já foi encerrada.';
  end if;

  -- O bloqueio dos mapas incluídos, na mesma transação da publicação
  -- (RN#4 da US012, RN#1 da US007). O `not locked` evita escrita à toa no dia
  -- que já estava bloqueado por um documento anterior.
  update public.meal_map
  set locked = true
  where not locked
    and id in (
      select meal_map_id from public.document_meal_map
      where generated_document_id = p_document_id
    );

  return document;
end;
$$;

comment on function public.complete_document_generation is
  'Publica o documento gerado e bloqueia os mapas incluídos, numa transação só (RN#4 da US012). A validade de sete dias é carimbada aqui.';

-- ---------------------------------------------------------------------------
-- A falha
-- ---------------------------------------------------------------------------

create or replace function public.fail_document_generation(p_document_id uuid)
returns public.generated_document
language plpgsql
as $$
declare
  document public.generated_document;
begin
  if not public.is_service() then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'A geração do documento é do servidor.';
  end if;

  -- O registro fica, com a falha à vista: é ele que explica à merendeira por
  -- que o documento que ela pediu não apareceu (decisão 10 da E4). Os mapas
  -- não são tocados — não houve documento, não há o que bloquear.
  update public.generated_document
  set status = 'failed', completed_at = now()
  where id = p_document_id and status = 'processing'
  returning * into document;

  if not found then
    raise exception using
      errcode = 'check_violation',
      message = 'Esta geração já foi encerrada.';
  end if;

  return document;
end;
$$;

comment on function public.fail_document_generation is
  'Encerra uma geração que não produziu arquivo. O registro permanece; nenhum mapa é bloqueado.';

-- ---------------------------------------------------------------------------
-- Só o servidor chama
-- ---------------------------------------------------------------------------

-- O guarda de is_service() dentro de cada função já recusaria a merendeira,
-- mas rota que existe é superfície: revogar o execute faz a API responder
-- antes de a função rodar. O service_role mantém o seu, que vem do dono.
revoke execute on function
  public.start_document_generation(uuid, uuid, uuid[]),
  public.complete_document_generation(uuid, text),
  public.fail_document_generation(uuid)
from public, anon, authenticated;
