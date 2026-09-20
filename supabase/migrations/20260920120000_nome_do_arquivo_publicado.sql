-- O nome com que o documento publicado chega no aparelho de quem recebe.
--
-- Até aqui esse nome só existia dentro da Edge Function: ela o calculava no
-- momento da geração e o embutia no link assinado que devolvia. Servia
-- enquanto o link era usado ali mesmo; não serve para a lista de documentos
-- gerados (US021), que assina um link novo dias depois e precisa saber com que
-- nome o arquivo sai.
--
-- Guardá-lo no registro, e não recalculá-lo em quem lê, é o que mantém a regra
-- num lugar só: o nome nasce do período dos mapas incluídos, e quem o soube
-- primeiro foi a geração. Recalculá-lo no navegador seria uma segunda
-- implementação da mesma regra, em outra linguagem, livre para divergir em
-- silêncio — e aí o mesmo documento chegaria à secretaria com dois nomes.
--
-- É também o que `document_template` já faz: `file_name` ao lado de
-- `file_path`, porque o caminho no balde é endereço, não nome.

alter table public.generated_document add column file_name text;

comment on column public.generated_document.file_name is
  'O nome do arquivo para quem o recebe, sem acento e sem espaço. O file_path é o endereço no balde; este é o nome.';

-- O nome acompanha o arquivo: existe quando o documento foi publicado, e não
-- existe quando não houve arquivo nenhum. É a mesma forma que o `file_path`
-- já tinha no check original.
alter table public.generated_document
  drop constraint generated_document_status_shape;

alter table public.generated_document
  add constraint generated_document_status_shape check (
    case status
      when 'processing' then
        completed_at is null and file_path is null and file_name is null
        and expires_at is null
      when 'available' then
        completed_at is not null and file_path is not null
        and file_name is not null and expires_at is not null
      when 'failed' then
        completed_at is not null and file_path is null and file_name is null
    end
  );

-- ---------------------------------------------------------------------------
-- A publicação passa a carimbar o nome junto
-- ---------------------------------------------------------------------------

-- A assinatura muda, então a antiga sai: `create or replace` deixaria as duas
-- de pé, e a chamada de dois argumentos resolveria para a que não grava nome.
drop function public.complete_document_generation(uuid, text);

create function public.complete_document_generation(
  p_document_id uuid,
  p_file_path text,
  p_file_name text
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

  if btrim(coalesce(p_file_name, '')) = '' then
    raise exception using
      errcode = 'check_violation',
      message = 'O documento publicado precisa do nome do arquivo.';
  end if;

  -- A janela de validade mora aqui, e não em quem chama: é a mesma data que a
  -- política do balde usa para deixar de servir o arquivo (RN#2 da US012). O
  -- link assinado é derivado dela, não o contrário.
  update public.generated_document
  set status = 'available',
      completed_at = now(),
      file_path = p_file_path,
      file_name = p_file_name,
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
  'Publica o documento gerado e bloqueia os mapas incluídos, numa transação só (RN#4 da US012). A validade de sete dias e o nome do arquivo são carimbados aqui.';

revoke execute on function public.complete_document_generation(uuid, text, text)
from public, anon, authenticated;
