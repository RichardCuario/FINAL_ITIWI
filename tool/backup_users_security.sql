select json_build_object(
 'functions',(select json_agg(pg_get_functiondef(p.oid)) from pg_proc p where p.pronamespace='public'::regnamespace and p.proname in ('is_super_admin','can_access_user_directory')),
 'policies',(select json_agg(p) from pg_policies p where schemaname='public' and tablename in ('users','admin_roles')),
 'grants',(select json_agg(g) from information_schema.role_table_grants g where table_schema='public' and table_name in ('users','admin_roles')),
 'rls',(select json_agg(x) from (select relname,relrowsecurity from pg_class where oid in ('public.users'::regclass,'public.admin_roles'::regclass))x)
) as before_security_change;