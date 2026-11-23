-- Shared admin-role storage for the Admin Dashboard.
-- Run this in Supabase SQL Editor after the admin accounts have been created.

create extension if not exists pgcrypto;

create table if not exists public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  role_name text not null,
  feature text not null,
  permissions text[] not null default '{}',
  report_categories text[] not null default '{}',
  is_super_admin boolean not null default false,
  assigned_email text not null,
  auth_user_id uuid,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (assigned_email, feature)
);

create index if not exists admin_roles_assigned_email_idx
  on public.admin_roles (lower(assigned_email));

alter table public.admin_roles enable row level security;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and exists (
    select 1 from public.admin_roles role_record
    where role_record.is_super_admin = true
      and (role_record.auth_user_id = auth.uid() or (
        role_record.auth_user_id is null and
        lower(role_record.assigned_email) = lower(auth.jwt() ->> 'email')
      ))
  );
$$;

drop policy if exists "super admins manage admin roles" on public.admin_roles;
drop policy if exists "admins read assigned role" on public.admin_roles;

create policy "super admins manage admin roles"
on public.admin_roles
for all
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

create policy "admins read assigned role"
on public.admin_roles
for select
to authenticated
using (lower(assigned_email) = lower(coalesce(auth.jwt() ->> 'email', '')));

create or replace function public.set_admin_roles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists admin_roles_set_updated_at on public.admin_roles;
create trigger admin_roles_set_updated_at
before update on public.admin_roles
for each row execute function public.set_admin_roles_updated_at();
