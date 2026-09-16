-- Um perfil não se promove sozinho.
--
-- A política `profile_update_self` (migration de RLS da E4) deixa a pessoa
-- editar a própria linha, e é isso que se quer: corrigir o próprio nome não
-- precisa da direção. Só que RLS não sabe olhar coluna — o `with check` não
-- enxerga o valor anterior —, então "pode editar a própria linha" acabava
-- valendo também para a coluna `role`.
--
-- Não é hipótese: confirmado em 16/09/2026 num PATCH pelo PostgREST, com o
-- token de uma merendeira. Ela virou `admin` no próprio perfil, e pelo mesmo
-- caminho poderia se reativar depois de desativada (CA#2 da US016) ou mudar de
-- escola, que é o recorte de tudo o que as políticas decidem. Derruba a RNF#1
-- da US016 no único lugar em que ela vale: no servidor.
--
-- O conserto segue o padrão que a etapa anterior já usou para a coluna
-- `locked`: o que a política não alcança, o gatilho recusa. A política continua
-- decidindo QUAIS linhas; o gatilho decide QUAIS COLUNAS, e é só ele que sabe
-- comparar o antes com o depois.

create or replace function public.reject_privileged_profile_change()
returns trigger
language plpgsql
as $$
begin
  -- O servidor continua podendo tudo: é ele quem aplica o seed, as migrations
  -- e o que as Edge Functions precisarem fazer.
  if public.is_service() then
    return new;
  end if;

  -- Identidade e escola não mudam por dentro do aplicativo, nem para a
  -- direção. A escola é a fronteira de todas as políticas: quem a reescreve
  -- não muda de linha, muda de universo.
  if new.id is distinct from old.id
     or new.school_id is distinct from old.school_id then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'A identidade e a escola de um perfil não se alteram pelo aplicativo.';
  end if;

  -- Perfil, acesso e e-mail são da direção (RN#1 e CA#1 da US016). O nome fica
  -- de fora de propósito: corrigir o próprio nome é da pessoa.
  if not public.current_role_is('admin')
     and (new.role is distinct from old.role
          or new.active is distinct from old.active
          or new.email is distinct from old.email) then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'Só a direção altera perfil, acesso e e-mail.',
      hint = 'Fale com a direção da escola.';
  end if;

  -- E nem a direção mexe no próprio papel ou no próprio acesso. A escola tem
  -- uma direção só: uma direção que se rebaixa ou se desativa tranca a gestão
  -- de acessos para fora do aplicativo, e não há caminho de volta por dentro
  -- dele.
  if old.id = auth.uid()
     and (new.role is distinct from old.role
          or new.active is distinct from old.active) then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'O próprio perfil e o próprio acesso não se alteram.',
      hint = 'Peça a outra pessoa da direção, ou ao administrador do sistema.';
  end if;

  return new;
end;
$$;

comment on function public.reject_privileged_profile_change() is
  'Guarda as colunas do perfil que a política de RLS não alcança: papel, acesso, e-mail, escola e identidade.';

create trigger profile_privileged_change_guard
  before update on public.profile
  for each row execute function public.reject_privileged_profile_change();
