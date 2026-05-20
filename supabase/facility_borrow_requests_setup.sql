-- Supabase setup for facility borrow requests submitted from the Flutter app.
-- This app uses Firebase Auth / Google Sign-In, not Supabase Auth.

create extension if not exists pgcrypto;

create table if not exists public.facility_borrow_requests (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  facility_name text not null,
  full_name text not null,
  contact_number text not null,
  purpose text not null,
  expected_participants integer,
  event_date date not null,
  start_time text not null,
  end_time text not null,
  additional_information text,
  status text not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.facility_borrow_requests enable row level security;

drop policy if exists "public can insert facility borrow requests" on public.facility_borrow_requests;
drop policy if exists "public can view facility borrow requests" on public.facility_borrow_requests;
drop policy if exists "public can update facility borrow requests" on public.facility_borrow_requests;

create index if not exists facility_borrow_requests_user_id_idx
  on public.facility_borrow_requests (user_id);

create index if not exists facility_borrow_requests_status_idx
  on public.facility_borrow_requests (status);

create index if not exists facility_borrow_requests_created_at_idx
  on public.facility_borrow_requests (created_at desc);

create or replace function public.set_facility_borrow_requests_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists facility_borrow_requests_set_updated_at on public.facility_borrow_requests;

create trigger facility_borrow_requests_set_updated_at
before update on public.facility_borrow_requests
for each row
execute function public.set_facility_borrow_requests_updated_at();

create policy "public can insert facility borrow requests"
on public.facility_borrow_requests
for insert
to anon, authenticated
with check (true);

create policy "public can view facility borrow requests"
on public.facility_borrow_requests
for select
to anon, authenticated
using (true);

create policy "public can update facility borrow requests"
on public.facility_borrow_requests
for update
to anon, authenticated
using (true)
with check (true);
