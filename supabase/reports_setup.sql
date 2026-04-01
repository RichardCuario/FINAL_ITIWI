-- Supabase setup for citizen reports submitted from the Flutter app.
-- This app uses Firebase Auth / Google Sign-In, not Supabase Auth.
-- Because of that, `auth.jwt()` policies will block inserts/uploads.
-- Paste and run this whole file in the Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  message text not null,
  image_urls text[] not null default '{}',
  status text not null default 'pending'
    check (status in ('pending', 'reviewing', 'resolved', 'rejected')),
  rejection_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.reports enable row level security;

-- Drop old policies first so the user_id column type can be changed safely.
drop policy if exists "users can insert own reports" on public.reports;
drop policy if exists "users can view own reports" on public.reports;
drop policy if exists "users can update own reports" on public.reports;
drop policy if exists "public can insert reports" on public.reports;
drop policy if exists "public can view reports" on public.reports;
drop policy if exists "public can update reports" on public.reports;

-- Drop old foreign key if reports.user_id still points to auth/users/profiles UUID ids.
alter table public.reports
  drop constraint if exists reports_user_id_fkey;

-- Fix older schemas where user_id was created as uuid.
alter table public.reports
  alter column user_id drop default;

alter table public.reports
  alter column user_id type text using user_id::text;

alter table public.reports
  alter column user_id set not null;

alter table public.reports
  alter column message set not null;

alter table public.reports
  alter column image_urls set default '{}';

alter table public.reports
  alter column status set default 'pending';

alter table public.reports
  add column if not exists rejection_reason text;

create index if not exists reports_user_id_idx
  on public.reports (user_id);

create index if not exists reports_status_idx
  on public.reports (status);

create index if not exists reports_created_at_idx
  on public.reports (created_at desc);

create or replace function public.set_reports_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists reports_set_updated_at on public.reports;

create trigger reports_set_updated_at
before update on public.reports
for each row
execute function public.set_reports_updated_at();

-- The Flutter app is already authenticated with Firebase, so allow the app
-- to insert/update/select reports without requiring Supabase Auth JWTs.
create policy "public can insert reports"
on public.reports
for insert
to anon, authenticated
with check (true);

create policy "public can view reports"
on public.reports
for select
to anon, authenticated
using (true);

create policy "public can update reports"
on public.reports
for update
to anon, authenticated
using (true)
with check (true);

insert into storage.buckets (id, name, public)
values ('report-images', 'report-images', true)
on conflict (id) do nothing;

drop policy if exists "authenticated users can upload report images" on storage.objects;
drop policy if exists "public can view report images" on storage.objects;
drop policy if exists "users can update own report images" on storage.objects;
drop policy if exists "users can delete own report images" on storage.objects;
drop policy if exists "public can upload report images" on storage.objects;
drop policy if exists "public can update report images" on storage.objects;
drop policy if exists "public can delete report images" on storage.objects;

create policy "public can upload report images"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'report-images'
  and (storage.foldername(name))[1] = 'public'
);

create policy "public can view report images"
on storage.objects
for select
to public
using (bucket_id = 'report-images');

create policy "public can update report images"
on storage.objects
for update
to anon, authenticated
using (
  bucket_id = 'report-images'
  and (storage.foldername(name))[1] = 'public'
)
with check (
  bucket_id = 'report-images'
  and (storage.foldername(name))[1] = 'public'
);

create policy "public can delete report images"
on storage.objects
for delete
to anon, authenticated
using (
  bucket_id = 'report-images'
  and (storage.foldername(name))[1] = 'public'
);