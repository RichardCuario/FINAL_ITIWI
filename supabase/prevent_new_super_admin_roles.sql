-- Apply to the iTIWI Supabase project after its existing Super Admin role exists.
-- Existing Super Admin assignments remain valid, but cannot be granted anew.
begin;

create or replace function public.prevent_new_super_admin_roles()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.is_super_admin = true then
      raise exception 'New Super Admin access cannot be granted';
    end if;
  elsif tg_op = 'UPDATE' then
    if new.is_super_admin = true and old.is_super_admin = false then
      raise exception 'New Super Admin access cannot be granted';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.prevent_new_super_admin_roles() from public, anon, authenticated;

drop trigger if exists prevent_new_super_admin_roles on public.admin_roles;
create trigger prevent_new_super_admin_roles
before insert or update of is_super_admin on public.admin_roles
for each row execute function public.prevent_new_super_admin_roles();

commit;
