insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'transparency-pdfs',
  'transparency-pdfs',
  true,
  10485760,
  array['application/pdf']
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view transparency pdfs" on storage.objects;
create policy "Public can view transparency pdfs"
on storage.objects
for select
to public
using (bucket_id = 'transparency-pdfs');

drop policy if exists "Public can upload transparency pdfs" on storage.objects;
create policy "Public can upload transparency pdfs"
on storage.objects
for insert
to public
with check (bucket_id = 'transparency-pdfs');

drop policy if exists "Public can update transparency pdfs" on storage.objects;
create policy "Public can update transparency pdfs"
on storage.objects
for update
to public
using (bucket_id = 'transparency-pdfs')
with check (bucket_id = 'transparency-pdfs');

drop policy if exists "Public can delete transparency pdfs" on storage.objects;
create policy "Public can delete transparency pdfs"
on storage.objects
for delete
to public
using (bucket_id = 'transparency-pdfs');
