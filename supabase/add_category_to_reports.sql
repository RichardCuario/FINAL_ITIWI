-- Adds a required category to citizen reports.
-- Run this in the Supabase SQL Editor for an existing project.

alter table public.reports
  add column if not exists category text;

update public.reports
  set category = 'Other'
  where category is null;

alter table public.reports
  alter column category set default 'Other';

alter table public.reports
  alter column category set not null;
