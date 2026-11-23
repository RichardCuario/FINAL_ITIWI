-- Run in the iTIWI Supabase SQL Editor before using the updated Marriage form.
-- Older requests keep a null date; new requests require a date in the app.
alter table public.marriage_certificate_appointments
  add column if not exists marriage_date date;

select column_name, data_type from information_schema.columns
where table_schema = 'public'
  and table_name = 'marriage_certificate_appointments'
  and column_name = 'marriage_date';
