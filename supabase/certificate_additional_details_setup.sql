-- Run in the iTIWI Supabase SQL Editor before using the updated certificate forms.
-- Existing requests keep null values for these newly collected details.
begin;

alter table public.birth_certificate_appointments
  add column if not exists place_of_birth text,
  add column if not exists mother_full_name text,
  add column if not exists father_full_name text;

alter table public.marriage_certificate_appointments
  add column if not exists place_of_marriage text;

commit;

select table_name, column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and (
    (table_name = 'birth_certificate_appointments'
      and column_name in ('place_of_birth', 'mother_full_name', 'father_full_name'))
    or (table_name = 'marriage_certificate_appointments'
      and column_name = 'place_of_marriage')
  )
order by table_name, column_name;
