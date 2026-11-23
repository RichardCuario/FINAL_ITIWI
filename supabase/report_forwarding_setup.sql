-- Persistent report forwarding between report administrators.
-- Run after reports_setup.sql and admin_roles_setup.sql.

alter table public.reports
  add column if not exists assigned_admin_role_id uuid references public.admin_roles(id) on delete set null;

alter table public.reports
  add column if not exists assigned_admin_email text;

alter table public.reports
  add column if not exists forwarded_by_email text;

alter table public.reports
  add column if not exists forwarded_at timestamptz;

create index if not exists reports_assigned_admin_email_idx
  on public.reports (lower(assigned_admin_email));

-- Report administrators need the recipient list in order to forward work.
drop policy if exists "report admins read report admin roles" on public.admin_roles;
create policy "report admins read report admin roles"
on public.admin_roles
for select
to authenticated
using (
  public.is_super_admin()
  or coalesce(auth.jwt() -> 'user_metadata' -> 'permissions', '[]'::jsonb) ? 'reports'
);
