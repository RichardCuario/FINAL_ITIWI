-- Run in Supabase SQL Editor before editing About Us in the admin dashboard.
create table if not exists public.municipal_profile (
  id integer primary key check (id = 1),
  profile text not null default '',
  vision_mission text not null default '',
  vision text not null default '',
  mission text not null default '',
  history text not null default '',
  history_image_path text not null default '',
  geography text not null default '',
  geography_image_path text not null default '',
  citizens_charter text not null default '',
  citizens_charter_files jsonb not null default '[]'::jsonb check (jsonb_typeof(citizens_charter_files) = 'array'),
  officials jsonb not null default '[]'::jsonb check (jsonb_typeof(officials) = 'array'),
  updated_at timestamptz not null default now()
);

-- Also works when the earlier combined Vision and Mission schema already exists.
alter table public.municipal_profile add column if not exists vision text not null default '';
alter table public.municipal_profile add column if not exists mission text not null default '';
alter table public.municipal_profile add column if not exists citizens_charter_files jsonb not null default '[]'::jsonb;
alter table public.municipal_profile add column if not exists history_image_path text not null default '';
alter table public.municipal_profile add column if not exists geography_image_path text not null default '';

alter table public.municipal_profile enable row level security;

create or replace function public.can_manage_municipal_profile()
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_super_admin() or exists (
    select 1 from public.admin_roles role_record
    where role_record.feature = 'about-us'
      and 'about-us' = any(role_record.permissions)
      and (
        role_record.auth_user_id = auth.uid()
        or lower(role_record.assigned_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      )
  );
$$;

drop policy if exists "public reads municipal profile" on public.municipal_profile;
create policy "public reads municipal profile" on public.municipal_profile
for select to anon, authenticated using (true);

drop policy if exists "admins edit municipal profile" on public.municipal_profile;
drop policy if exists "admins insert municipal profile" on public.municipal_profile;
create policy "admins insert municipal profile" on public.municipal_profile
for insert to authenticated
with check (public.can_manage_municipal_profile());

drop policy if exists "admins update municipal profile" on public.municipal_profile;
create policy "admins update municipal profile" on public.municipal_profile
for update to authenticated using (public.can_manage_municipal_profile())
with check (public.can_manage_municipal_profile());

insert into public.municipal_profile (id) values (1) on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('municipal-officials', 'municipal-officials', true)
on conflict (id) do update set public = true;

drop policy if exists "admins upload municipal official photos" on storage.objects;
create policy "admins upload municipal official photos" on storage.objects
for insert to authenticated
with check (bucket_id = 'municipal-officials' and public.can_manage_municipal_profile());

drop policy if exists "public views municipal official photos" on storage.objects;
create policy "public views municipal official photos" on storage.objects
for select to anon, authenticated using (bucket_id = 'municipal-officials');

insert into storage.buckets (id, name, public)
values ('municipal-charter', 'municipal-charter', true)
on conflict (id) do update set public = true;

drop policy if exists "admins upload charter files" on storage.objects;
create policy "admins upload charter files" on storage.objects
for insert to authenticated
with check (bucket_id = 'municipal-charter' and public.can_manage_municipal_profile());

drop policy if exists "public views charter files" on storage.objects;
create policy "public views charter files" on storage.objects
for select to anon, authenticated using (bucket_id = 'municipal-charter');

insert into storage.buckets (id, name, public)
values ('municipal-profile-images', 'municipal-profile-images', true)
on conflict (id) do update set public = true;

drop policy if exists "admins upload municipal profile images" on storage.objects;
create policy "admins upload municipal profile images" on storage.objects
for insert to authenticated
with check (bucket_id = 'municipal-profile-images' and public.can_manage_municipal_profile());

drop policy if exists "public views municipal profile images" on storage.objects;
create policy "public views municipal profile images" on storage.objects
for select to anon, authenticated using (bucket_id = 'municipal-profile-images');
