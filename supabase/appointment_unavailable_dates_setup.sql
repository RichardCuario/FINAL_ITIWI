-- Run in the Supabase SQL Editor before enabling appointment date management.
-- Admin-added closures apply to all online-service appointment types.
create table if not exists public.appointment_unavailable_dates (
  date date primary key,
  reason text not null default 'Unavailable for appointments',
  created_at timestamptz not null default now()
);

alter table public.appointment_unavailable_dates enable row level security;

drop policy if exists "anyone can read unavailable appointment dates" on public.appointment_unavailable_dates;
create policy "anyone can read unavailable appointment dates"
on public.appointment_unavailable_dates for select
to anon, authenticated using (true);

drop policy if exists "admins can add unavailable appointment dates" on public.appointment_unavailable_dates;
create policy "admins can add unavailable appointment dates"
on public.appointment_unavailable_dates for insert
to authenticated with check (auth.uid() is not null);

drop policy if exists "admins can remove unavailable appointment dates" on public.appointment_unavailable_dates;
create policy "admins can remove unavailable appointment dates"
on public.appointment_unavailable_dates for delete
to authenticated using (auth.uid() is not null);
