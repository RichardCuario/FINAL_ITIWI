-- Fix RLS policies for transparency tables to allow authenticated admin users

-- For transparency_annual_budget
drop policy if exists "Authenticated users can manage transparency annual budget" on public.transparency_annual_budget;
create policy "Authenticated users can manage transparency annual budget"
on public.transparency_annual_budget
for all
to authenticated
using (true)
with check (true);

-- For transparency_bids_projects
drop policy if exists "Authenticated users can manage transparency bids" on public.transparency_bids_projects;
create policy "Authenticated users can manage transparency bids"
on public.transparency_bids_projects
for all
to authenticated
using (true)
with check (true);

-- For transparency_executive_orders
drop policy if exists "Authenticated users can manage transparency executive orders" on public.transparency_executive_orders;
create policy "Authenticated users can manage transparency executive orders"
on public.transparency_executive_orders
for all
to authenticated
using (true)
with check (true);

-- For transparency_financial_reports
drop policy if exists "Authenticated users can manage transparency financial reports" on public.transparency_financial_reports;
create policy "Authenticated users can manage transparency financial reports"
on public.transparency_financial_reports
for all
to authenticated
using (true)
with check (true);

-- For transparency_legislative_ordinances
drop policy if exists "Authenticated users can manage transparency legislative ordinances" on public.transparency_legislative_ordinances;
create policy "Authenticated users can manage transparency legislative ordinances"
on public.transparency_legislative_ordinances
for all
to authenticated
using (true)
with check (true);

-- For transparency_programs_projects
drop policy if exists "Authenticated users can manage transparency programs" on public.transparency_programs_projects;
create policy "Authenticated users can manage transparency programs"
on public.transparency_programs_projects
for all
to authenticated
using (true)
with check (true);
