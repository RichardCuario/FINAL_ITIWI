-- Run this in the Supabase SQL Editor for an existing project.
-- Lets administrators send an optional follow-up message while a report is under review.

alter table public.reports
  add column if not exists review_message text;
