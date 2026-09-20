-- A gestão da direção, do lado do banco (US015, US016).
--
-- A tela de gestão (issue #68) escreve em três lugares — os dados da escola,
-- os perfis de acesso e o modelo oficial —, e dois deles já estavam de pé
-- desde a E4: `school_update` e `profile_admin_insert`/`profile_admin_update`
-- dizem quem pode o quê, e o gatilho `profile_privileged_change_guard` cuida
-- das colunas que a política não alcança.
--
-- Faltavam duas coisas, e as duas estão aqui:
--
--   replace_document_template  troca o modelo vigente sem deixar a escola sem
--                              modelo nenhum no meio do caminho
--   touch_last_access          carimba o último acesso com a hora do servidor
--
-- O que NÃO está aqui, de propósito: criar o acesso de uma merendeira. Isso
-- nasce em `auth.users`, que só a chave secreta escreve, e é da Edge Function
-- `create-access`. O banco entra depois, com a linha de `profile`.

-- ---------------------------------------------------------------------------
-- O modelo oficial: trocar é uma operação só
-- ---------------------------------------------------------------------------

-- "Existe sempre exatamente um template vigente" (RN#1 da US015) é um índice
-- único parcial desde a E4, e é ele que torna a troca indivisível: inserir a
-- versão nova antes de baixar a antiga é recusado pelo índice, e baixar a
-- antiga antes de inserir a nova deixaria a escola sem modelo se a segunda
-- chamada não chegasse — e sem modelo vigente a geração do documento para de
-- funcionar para as duas merendeiras.
--
-- Duas chamadas do navegador não têm como ser uma transação só. Esta função
-- tem, e é essa a razão de ela existir.
--
-- Fica em security invoker (o padrão) de propósito: quem decide se esta pessoa
-- pode escrever aqui continuam sendo as políticas da tabela. A conferência
-- explícita logo abaixo é para a recusa chegar com uma frase que a direção
-- possa ler, e não como uma violação de política.
create or replace function public.replace_document_template(
  p_file_name text,
  p_file_path text
)
returns public.document_template
language plpgsql
as $$
declare
  -- Prefixo para não colidir com a coluna `school_id` da tabela, que aparece
  -- no update e no insert logo abaixo.
  v_school uuid;
  created public.document_template;
begin
  v_school := public.current_school_id();

  if v_school is null or not public.current_role_is('admin') then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'Só a direção troca o modelo oficial.';
  end if;

  if btrim(coalesce(p_file_name, '')) = '' or btrim(coalesce(p_file_path, '')) = '' then
    raise exception using
      errcode = 'check_violation',
      message = 'O arquivo do modelo não chegou. Escolha o arquivo e envie de novo.';
  end if;

  -- O balde guarda cada versão em `<escola>/<arquivo>`, e a política do balde
  -- recorta por perfil, não por pasta. Amarrar o caminho à escola aqui é o que
  -- impede o registro de uma escola apontar para o arquivo de outra.
  if p_file_path not like v_school::text || '/%' then
    raise exception using
      errcode = 'check_violation',
      message = 'O arquivo não foi guardado na pasta desta escola.';
  end if;

  -- A anterior continua na tabela: é ela que diz com qual modelo cada
  -- documento já gerado saiu (decisão 11 da E4).
  update public.document_template
  set is_current = false
  where school_id = v_school and is_current;

  insert into public.document_template
    (school_id, file_name, file_path, uploaded_by, is_current)
  values
    (v_school, btrim(p_file_name), p_file_path, auth.uid(), true)
  returning * into created;

  return created;
end;
$$;

comment on function public.replace_document_template is
  'Publica uma versão nova do modelo oficial e baixa a anterior, numa transação só (RN#1 da US015).';

-- Quem chama é a direção, do navegador, com a sessão dela. O anônimo não tem o
-- que fazer aqui, e `authenticated` recebe o execute de volta explicitamente:
-- revogar de `public` alcança todos os papéis, inclusive o dela.
revoke execute on function public.replace_document_template(text, text)
from public, anon;

grant execute on function public.replace_document_template(text, text)
to authenticated;

-- ---------------------------------------------------------------------------
-- O último acesso
-- ---------------------------------------------------------------------------

-- A coluna existe desde a E4 e ninguém a escrevia; a gestão de acessos é quem
-- a exibe, e por isso é aqui que ela passa a ser preenchida.
--
-- Por que uma função, e não um update do navegador: o valor é a hora do
-- SERVIDOR. Enviado pelo cliente, "último acesso" passaria a ser o que o
-- relógio do aparelho disser — e a gravação do dia já ensinou, na #60, que o
-- relógio do aparelho está adiantado com frequência. É também o que impede a
-- coluna de ser escrita com qualquer valor por quem sabe montar um PATCH.
--
-- Escreve a própria linha e só ela: a política `profile_update_self` da E4 já
-- diz isso, e a função não pede mais do que ela dá.
create or replace function public.touch_last_access()
returns void
language sql
as $$
  update public.profile
  set last_access = now()
  where id = auth.uid();
$$;

comment on function public.touch_last_access is
  'Carimba o último acesso de quem está logada, com a hora do servidor (US016).';

revoke execute on function public.touch_last_access() from public, anon;

grant execute on function public.touch_last_access() to authenticated;
