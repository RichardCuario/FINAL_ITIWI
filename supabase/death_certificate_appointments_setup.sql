-- Supabase setup for death certificate appointments submitted from the Flutter app.
-- This app uses Firebase Auth / Google Sign-In, not Supabase Auth.

create extension if not exists pgcrypto;

create table if not exists public.death_certificate_appointments (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  service_name text not null default 'Death Certificate',
  deceased_full_name text not null,
  date_of_death text not null,
  place_of_death text not null,
  requestor_full_name text not null,
  contact_number text not null,
  email text not null,
  relationship_to_owner text not null,
  purpose text not null,
  appointment_date date not null,
  appointment_time text not null,
  notes text,
  status text not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.death_certificate_appointments enable row level security;

drop policy if exists "public can insert death certificate appointments" on public.death_certificate_appointments;
drop policy if exists "public can view death certificate appointments" on public.death_certificate_appointments;
drop policy if exists "public can update death certificate appointments" on public.death_certificate_appointments;

create index if not exists death_certificate_appointments_user_id_idx
  on public.death_certificate_appointments (user_id);

create index if not exists death_certificate_appointments_status_idx
  on public.death_certificate_appointments (status);

create index if not exists death_certificate_appointments_created_at_idx
  on public.death_certificate_appointments (created_at desc);

create or replace function public.set_death_certificate_appointments_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists death_certificate_appointments_set_updated_at on public.death_certificate_appointments;

create trigger death_certificate_appointments_set_updated_at
before update on public.death_certificate_appointments
for each row
execute function public.set_death_certificate_appointments_updated_at();

create policy "public can insert death certificate appointments"
on public.death_certificate_appointments
for insert
to anon, authenticated
with check (true);

create policy "public can view death certificate appointments"
on public.death_certificate_appointments
for select
to anon, authenticated
using (true);

create policy "public can update death certificate appointments"
on public.death_certificate_appointments
for update
to anon, authenticated
using (true)
with check (true);
