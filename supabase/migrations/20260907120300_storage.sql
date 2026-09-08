-- Baldes privados do Storage: o modelo oficial e os documentos gerados.
-- Nenhum dos dois pode ser público (RNF#1 da US012, e a regra de sigilo do
-- projeto: documento com brasão da prefeitura não fica exposto).

insert into storage.buckets (id, name, public)
values
  ('document-templates', 'document-templates', false),
  ('generated-documents', 'generated-documents', false)
on conflict (id) do nothing;

-- O modelo oficial é enviado e trocado pela direção (CA#1 e CA#3 da US015);
-- a merendeira nunca precisa tocá-lo — quem o lê na geração é o servidor.
create policy document_template_admin_read on storage.objects
  for select to authenticated
  using (bucket_id = 'document-templates' and public.current_role_is('admin'));

create policy document_template_admin_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'document-templates' and public.current_role_is('admin'));

create policy document_template_admin_update on storage.objects
  for update to authenticated
  using (bucket_id = 'document-templates' and public.current_role_is('admin'))
  with check (bucket_id = 'document-templates' and public.current_role_is('admin'));

create policy document_template_admin_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'document-templates' and public.current_role_is('admin'));

-- O documento gerado é lido pelos dois perfis da escola: a merendeira para
-- compartilhar de novo (US021), a direção para baixar (US022). Escrever é do
-- servidor, e o arquivo sai do ar em até 7 dias (RN#2 da US012).
create policy generated_document_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'generated-documents'
    and exists (
      select 1 from public.generated_document gd
      where gd.file_path = storage.objects.name
        and gd.school_id = public.current_school_id()
        and gd.status = 'available'
        and gd.expires_at > now()
    )
  );
