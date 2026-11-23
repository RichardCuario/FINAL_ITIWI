-- Apply to the iTIWI Supabase project before deploying the Barangay form changes.
begin;

alter table public.barangays
  alter column description drop not null,
  alter column geographic_data drop not null,
  alter column latitude drop not null,
  alter column longitude drop not null;

commit;
