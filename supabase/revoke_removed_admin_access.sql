
create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_roles role_record
    where role_record.is_super_admin = true
      and (
        role_record.auth_user_id = auth.uid()
        or lower(role_record.assigned_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      )
  );
$$;

create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_roles role_record
    where role_record.auth_user_id = auth.uid()
      or lower(role_record.assigned_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

create or replace function public.has_admin_feature(required_feature text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_roles role_record
    where (role_record.auth_user_id = auth.uid()
      or lower(role_record.assigned_email) = lower(coalesce(auth.jwt() ->> 'email', '')))
      and (role_record.is_super_admin
        or role_record.feature = required_feature
        or required_feature = any(role_record.permissions))
  );
$$;

revoke all on function public.is_super_admin() from public;
revoke all on function public.is_admin_user() from public;
revoke all on function public.has_admin_feature(text) from public;
grant execute on function public.is_super_admin() to authenticated;
grant execute on function public.is_admin_user() to authenticated;
grant execute on function public.has_admin_feature(text) to authenticated;

drop policy if exists "report admins read report admin roles" on public.admin_roles;
create policy "report admins read report admin roles"
on public.admin_roles
for select
to authenticated
using (public.is_super_admin() or public.has_admin_feature('reports'));
