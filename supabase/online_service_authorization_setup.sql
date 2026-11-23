-- Run birth_certificate_details_setup.sql first to create the private upload bucket.
-- Then run this script to add authorization letters to the other online services.
begin;
do $$
declare service_table text;
begin
  foreach service_table in array array[
    'marriage_certificate_appointments', 'death_certificate_appointments',
    'cenomar_appointments', 'cenodeath_appointments', 'facility_borrow_requests'
  ] loop
    if to_regclass('public.' || service_table) is null then continue; end if;
    execute format('alter table public.%I add column if not exists authorization_letter_path text', service_table);
    execute format('alter table public.%I add column if not exists relationship_to_owner text', service_table);
  end loop;
end;
$$;
commit;

select table_name, column_name from information_schema.columns
where table_schema = 'public' and column_name = 'authorization_letter_path'
order by table_name;
