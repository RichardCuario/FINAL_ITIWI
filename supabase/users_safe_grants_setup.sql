-- Safe before the mobile profile API rollout: preserve existing CRUD and RLS.
-- Browser roles do not create database constraints/triggers or truncate tables.
begin;
revoke truncate, references, trigger on public.users from public, anon, authenticated;
revoke truncate, references, trigger on public.admin_roles from public, anon, authenticated;
commit;
