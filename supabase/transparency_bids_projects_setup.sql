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

create table if not exists public.transparency_bids_projects (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  pdf_url text,
  is_published boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.transparency_bids_projects
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
    where conname = 'transparency_bids_projects_title_not_blank'
  ) then
    alter table public.transparency_bids_projects
      add constraint transparency_bids_projects_title_not_blank
      check (btrim(title) <> '');
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'transparency_bids_projects_pdf_url_check'
  ) then
    alter table public.transparency_bids_projects
      add constraint transparency_bids_projects_pdf_url_check
      check (pdf_url is null or pdf_url ~* '^https?://');
  end if;
end $$;

create index if not exists transparency_bids_projects_is_published_idx
  on public.transparency_bids_projects using btree (is_published);

create index if not exists transparency_bids_projects_display_order_idx
  on public.transparency_bids_projects using btree (display_order);

create index if not exists transparency_bids_projects_created_at_idx
  on public.transparency_bids_projects using btree (created_at desc);

drop trigger if exists set_transparency_bids_projects_updated_at on public.transparency_bids_projects;
create trigger set_transparency_bids_projects_updated_at
before update on public.transparency_bids_projects
for each row
execute function public.set_updated_at();

alter table public.transparency_bids_projects enable row level security;

drop policy if exists "Authenticated users can read published transparency bids projects" on public.transparency_bids_projects;
drop policy if exists "Public users can read published transparency bids projects" on public.transparency_bids_projects;

create policy "Public users can read published transparency bids projects"
on public.transparency_bids_projects
for select
to anon, authenticated
using (is_published = true);

drop policy if exists "Service role can manage transparency bids projects" on public.transparency_bids_projects;
create policy "Service role can manage transparency bids projects"
on public.transparency_bids_projects
for all
to service_role
using (true)
with check (true);

comment on table public.transparency_bids_projects is 'Bids and Projects transparency records managed from the admin panel.';

commit;