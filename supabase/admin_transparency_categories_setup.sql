-- Run once in the iTIWI project's SQL Editor before deploying the updated admin.
begin;

alter table public.admin_roles
  add column if not exists transparency_categories text[];

-- Preserve the existing access of transparency admins during the upgrade.
update public.admin_roles
set transparency_categories = case
  when is_super_admin or feature = 'transparency' or 'transparency' = any(permissions)
    then array['annual_budget', 'bids_projects', 'executive_orders',
      'financial_reports', 'legislative_ordinances', 'programs_projects']
  else '{}'::text[] end
where transparency_categories is null;

alter table public.admin_roles
  alter column transparency_categories set default '{}',
  alter column transparency_categories set not null;

-- Invoker rights: admins can already read their own role rows through RLS.
create or replace function public.can_manage_transparency_category(category text)
returns boolean language sql stable security invoker set search_path = ''
as $$
  select auth.uid() is not null and (
    coalesce((auth.jwt() -> 'app_metadata' ->> 'is_super_admin')::boolean, false)
    or exists (
      select 1 from public.admin_roles r
      where (r.auth_user_id = auth.uid()
        or lower(r.assigned_email) = lower(auth.jwt() ->> 'email'))
        and (r.is_super_admin or (
          (r.feature = 'transparency' or 'transparency' = any(r.permissions))
          and category = any(r.transparency_categories)
        ))
    )
  );
$$;

revoke all on function public.can_manage_transparency_category(text) from public;
grant execute on function public.can_manage_transparency_category(text) to authenticated;

do $$
declare
  category text;
  table_name text;
  predicate text;
begin
  foreach category in array array['annual_budget', 'bids_projects', 'executive_orders',
    'financial_reports', 'legislative_ordinances', 'programs_projects'] loop
    table_name := 'transparency_' || category;
    if to_regclass('public.' || table_name) is null then continue; end if;
    predicate := format('public.can_manage_transparency_category(%L)', category);
    execute format('alter table public.%I enable row level security', table_name);
    execute format('drop policy if exists "assigned transparency admins" on public.%I', table_name);
    execute format('create policy "assigned transparency admins" on public.%I for all to authenticated using (%s) with check (%s)', table_name, predicate, predicate);
    -- Restrictive write checks also constrain any older permissive policies.
    execute format('drop policy if exists "transparency category insert" on public.%I', table_name);
    execute format('create policy "transparency category insert" on public.%I as restrictive for insert to authenticated with check (%s)', table_name, predicate);
    execute format('drop policy if exists "transparency category update" on public.%I', table_name);
    execute format('create policy "transparency category update" on public.%I as restrictive for update to authenticated using (%s) with check (%s)', table_name, predicate, predicate);
    execute format('drop policy if exists "transparency category delete" on public.%I', table_name);
    execute format('create policy "transparency category delete" on public.%I as restrictive for delete to authenticated using (%s)', table_name, predicate);
  end loop;
end;
$$;

commit;

-- Verify the new column and policies after applying.
select column_name, data_type, is_nullable from information_schema.columns
where table_schema = 'public' and table_name = 'admin_roles'
  and column_name = 'transparency_categories';
select tablename, policyname from pg_policies
where schemaname = 'public' and policyname like 'transparency category%';
