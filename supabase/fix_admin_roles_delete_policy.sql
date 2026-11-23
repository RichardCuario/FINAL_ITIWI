-- Fixes deletion for super admins whose status is stored in admin_roles.
-- Run this for projects where admin_roles_setup.sql was already applied.

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean, false)
    or lower(coalesce(auth.jwt() -> 'user_metadata' ->> 'role', '')) like '%super%'
    or exists (
      select 1
      from public.admin_roles role_record
      where role_record.is_super_admin = true
        and lower(role_record.assigned_email) =
          lower(coalesce(auth.jwt() ->> 'email', ''))
    );
$$;

drop policy if exists "super admins manage admin roles" on public.admin_roles;
create policy "super admins manage admin roles"
on public.admin_roles
for all
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());
