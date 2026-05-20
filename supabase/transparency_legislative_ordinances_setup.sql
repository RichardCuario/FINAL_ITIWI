begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.transparency_legislative_ordinances (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  pdf_url text,
  is_published boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.transparency_legislative_ordinances
  add column if not exists description text,
  add column if not exists pdf_url text,
  add column if not exists is_published boolean not null default true,
  add column if not exists display_order integer not null default 0,
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'transparency_legislative_ordinances_title_not_blank'
  ) then
    alter table public.transparency_legislative_ordinances
      add constraint transparency_legislative_ordinances_title_not_blank
      check (btrim(title) <> '');
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'transparency_legislative_ordinances_pdf_url_check'
  ) then
    alter table public.transparency_legislative_ordinances
      add constraint transparency_legislative_ordinances_pdf_url_check
      check (pdf_url is null or pdf_url ~* '^https?://');
  end if;
end $$;

create index if not exists transparency_legislative_ordinances_is_published_idx
  on public.transparency_legislative_ordinances using btree (is_published);

create index if not exists transparency_legislative_ordinances_display_order_idx
  on public.transparency_legislative_ordinances using btree (display_order);

create index if not exists transparency_legislative_ordinances_created_at_idx
  on public.transparency_legislative_ordinances using btree (created_at desc);

drop trigger if exists set_transparency_legislative_ordinances_updated_at on public.transparency_legislative_ordinances;
create trigger set_transparency_legislative_ordinances_updated_at
before update on public.transparency_legislative_ordinances
for each row
execute function public.set_updated_at();

alter table public.transparency_legislative_ordinances enable row level security;

drop policy if exists "Authenticated users can read published transparency legislative ordinances" on public.transparency_legislative_ordinances;
drop policy if exists "Public users can read published transparency legislative ordinances" on public.transparency_legislative_ordinances;

create policy "Public users can read published transparency legislative ordinances"
on public.transparency_legislative_ordinances
for select
to anon, authenticated
using (is_published = true);

drop policy if exists "Service role can manage transparency legislative ordinances" on public.transparency_legislative_ordinances;
create policy "Service role can manage transparency legislative ordinances"
on public.transparency_legislative_ordinances
for all
to service_role
using (true)
with check (true);

comment on table public.transparency_legislative_ordinances is 'Legislative Ordinances transparency records managed from the admin panel.';

commit;