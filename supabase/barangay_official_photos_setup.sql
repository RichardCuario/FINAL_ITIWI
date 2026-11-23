-- Run in the Supabase SQL Editor before uploading official photos.
insert into storage.buckets (id, name, public)
values ('barangay-officials', 'barangay-officials', true)
on conflict (id) do update set public = true;

drop policy if exists "admins upload barangay official photos" on storage.objects;
create policy "admins upload barangay official photos"
on storage.objects for insert to authenticated
with check (bucket_id = 'barangay-officials');

drop policy if exists "anyone views barangay official photos" on storage.objects;
create policy "anyone views barangay official photos"
on storage.objects for select to anon, authenticated
using (bucket_id = 'barangay-officials');
