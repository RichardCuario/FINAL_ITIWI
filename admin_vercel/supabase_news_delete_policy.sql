-- Run this in the Supabase SQL Editor for the project used by admin_vercel/auth.js
-- Project URL: https://jbhlbukxankrtcwhqoll.supabase.co
--
-- Why this is needed:
-- The admin panel currently allows a temporary local admin login
-- (admin@itiwi.local / Admin1234), but that login does NOT create a real
-- Supabase authenticated session. Requests are still sent using the anon key,
-- so DELETE on public.news will be blocked unless the table has an anon delete
-- policy. The safer option is to create a real Supabase admin user and use the
-- authenticated-only policies below.

alter table public.news enable row level security;

drop policy if exists "Allow authenticated select on news" on public.news;
drop policy if exists "Allow authenticated insert on news" on public.news;
drop policy if exists "Allow authenticated update on news" on public.news;
drop policy if exists "Allow authenticated delete on news" on public.news;

create policy "Allow authenticated select on news"
on public.news
for select
to authenticated
using (true);

create policy "Allow authenticated insert on news"
on public.news
for insert
to authenticated
with check (true);

create policy "Allow authenticated update on news"
on public.news
for update
to authenticated
using (true)
with check (true);

create policy "Allow authenticated delete on news"
on public.news
for delete
to authenticated
using (true);

-- If you insist on keeping the temporary local admin login, you would also need
-- anon policies. That is not recommended for production because anyone using the
-- public anon key could potentially modify data.
--
-- Example only (unsafe for production):
--
-- create policy "Allow anon delete on news"
-- on public.news
-- for delete
-- to anon
-- using (true);
