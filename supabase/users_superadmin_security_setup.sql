-- Deploy /api/profile and release the updated mobile app BEFORE applying.
-- Old mobile builds use anonymous profile requests and must be upgraded.
-- Admins and superadmins can access the directory; citizens use /api/profile.
-- Run as the database owner in the iTIWI project, not a different connected project.
begin;

-- Fail before changing permissions if there is no persisted superadmin.
do $$ begin
  if not exists (select 1 from public.admin_roles where is_super_admin = true) then
    raise exception 'Create/verify a trusted superadmin assignment before applying this script';
  end if;
end $$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and (
    coalesce(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true'
    or exists (
      select 1 from public.admin_roles r where r.is_super_admin = true
      and (r.auth_user_id = auth.uid() or (
        r.auth_user_id is null and lower(r.assigned_email) = lower(auth.jwt() ->> 'email')
      ))
    )
  );
$$;
revoke all on function public.is_super_admin() from public, anon;
grant execute on function public.is_super_admin() to authenticated;

create or replace function public.can_access_user_directory()
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and (
    public.is_super_admin() or exists (
      select 1 from public.admin_roles r
      where r.auth_user_id = auth.uid() or (
        r.auth_user_id is null and lower(r.assigned_email) = lower(auth.jwt() ->> 'email')
      )
    )
  );
$$;
revoke all on function public.can_access_user_directory() from public, anon;
grant execute on function public.can_access_user_directory() to authenticated;

alter table public.users enable row level security;
revoke all on public.users from public, anon, authenticated;
grant select, insert, update, delete on public.users to authenticated;
grant all on public.users to service_role;

-- Restrictive policies prevent older permissive policies from reopening access.
drop policy if exists users_superadmin_boundary on public.users;
create policy users_superadmin_boundary on public.users as restrictive
for all to authenticated
using ((select public.can_access_user_directory()))
with check ((select public.can_access_user_directory()));
drop policy if exists users_superadmin_access on public.users;
create policy users_superadmin_access on public.users
for all to authenticated
using ((select public.can_access_user_directory()))
with check ((select public.can_access_user_directory()));

-- Old permissive role policies must not permit self-promotion.
alter table public.admin_roles enable row level security;
revoke all on public.admin_roles from public, anon;
revoke truncate, references, trigger on public.admin_roles from authenticated;
drop policy if exists admin_roles_insert_boundary on public.admin_roles;
create policy admin_roles_insert_boundary on public.admin_roles as restrictive
for insert to authenticated with check ((select public.is_super_admin()));
drop policy if exists admin_roles_update_boundary on public.admin_roles;
create policy admin_roles_update_boundary on public.admin_roles as restrictive
for update to authenticated using ((select public.is_super_admin()))
with check ((select public.is_super_admin()));
drop policy if exists admin_roles_delete_boundary on public.admin_roles;
create policy admin_roles_delete_boundary on public.admin_roles as restrictive
for delete to authenticated using ((select public.is_super_admin()));
commit;
