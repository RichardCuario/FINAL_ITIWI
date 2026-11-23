-- Run in the iTIWI Supabase SQL Editor before using the new Birth Certificate form.
begin;
alter table public.birth_certificate_appointments
  add column if not exists date_of_birth date,
  add column if not exists authorization_letter_path text,
  add column if not exists owner_valid_id_path text;

-- Images are private. The Firebase-authenticated upload API writes with service access.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('birth-certificate-documents', 'birth-certificate-documents', false, 2097152,
  array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "service admins read birth documents" on storage.objects;
create policy "service admins read birth documents" on storage.objects
for select to authenticated using (
  bucket_id = 'birth-certificate-documents' and (
    coalesce((auth.jwt() -> 'app_metadata' ->> 'is_super_admin')::boolean, false)
    or exists (
      select 1 from public.admin_roles r
      where (r.auth_user_id = auth.uid() or lower(r.assigned_email) = lower(auth.jwt() ->> 'email'))
        and (r.is_super_admin or r.feature = 'services' or 'services' = any(r.permissions))
    )
  )
);
commit;
