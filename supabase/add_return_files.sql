-- Run once in the Supabase SQL Editor before uploading files for returned items.
alter table public.reports add column if not exists return_files jsonb;
alter table public.birth_certificate_appointments add column if not exists return_files jsonb;
alter table public.marriage_certificate_appointments add column if not exists return_files jsonb;
alter table public.death_certificate_appointments add column if not exists return_files jsonb;
alter table public.cenomar_appointments add column if not exists return_files jsonb;
alter table public.cenodeath_appointments add column if not exists return_files jsonb;

-- These fields hold the return message across all appointment types.
alter table public.birth_certificate_appointments add column if not exists rejection_reason text;
alter table public.birth_certificate_appointments add column if not exists remarks text;
alter table public.marriage_certificate_appointments add column if not exists rejection_reason text;
alter table public.marriage_certificate_appointments add column if not exists remarks text;
alter table public.death_certificate_appointments add column if not exists rejection_reason text;
alter table public.death_certificate_appointments add column if not exists remarks text;
alter table public.cenomar_appointments add column if not exists rejection_reason text;
alter table public.cenomar_appointments add column if not exists remarks text;
alter table public.cenodeath_appointments add column if not exists rejection_reason text;
alter table public.cenodeath_appointments add column if not exists remarks text;
