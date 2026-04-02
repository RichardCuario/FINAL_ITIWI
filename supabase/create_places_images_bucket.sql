insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'places-images',
  'places-images',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view places images" on storage.objects;
create policy "Public can view places images"
on storage.objects
for select
to public
using (bucket_id = 'places-images');

drop policy if exists "Authenticated users can upload places images" on storage.objects;
create policy "Authenticated users can upload places images"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'places-images');

drop policy if exists "Authenticated users can update places images" on storage.objects;
create policy "Authenticated users can update places images"
on storage.objects
for update
to authenticated
using (bucket_id = 'places-images')
with check (bucket_id = 'places-images');

drop policy if exists "Authenticated users can delete places images" on storage.objects;
create policy "Authenticated users can delete places images"
on storage.objects
for delete
to authenticated
using (bucket_id = 'places-images');
