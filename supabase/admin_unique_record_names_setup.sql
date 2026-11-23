-- Run in the project's Supabase SQL Editor after resolving any reported duplicates.
-- No records are deleted or renamed. The transaction fails if duplicates exist.
-- Names ignore case, leading/trailing whitespace, and repeated whitespace.
-- Transparency titles are unique within their category table.
begin;

do $$
declare
  entry record;
  duplicate_names text;
begin
  for entry in
    select * from (values
      ('barangays', 'name'),
      ('places', 'name'),
      ('hotlines', 'name'),
      ('transparency_annual_budget', 'title'),
      ('transparency_bids_projects', 'title'),
      ('transparency_executive_orders', 'title'),
      ('transparency_financial_reports', 'title'),
      ('transparency_legislative_ordinances', 'title'),
      ('transparency_programs_projects', 'title')
    ) as targets(table_name, name_column)
  loop
    -- Lock writes until the checks and unique indexes have completed.
    execute format('lock table public.%I in share row exclusive mode', entry.table_name);
    execute format(
      'select string_agg(normalized_name, '', '') from (
         select lower(btrim(regexp_replace(%I, ''\s+'', '' '', ''g''))) as normalized_name
         from public.%I
         group by 1 having count(*) > 1 limit 20
       ) duplicates', entry.name_column, entry.table_name
    ) into duplicate_names;
    if duplicate_names is not null then
      raise exception 'Resolve duplicate names in % before applying: %', entry.table_name, duplicate_names;
    end if;
    execute format(
      'create unique index if not exists %I on public.%I
         (lower(btrim(regexp_replace(%I, ''\s+'', '' '', ''g''))))',
      entry.table_name || '_normalized_name_unique', entry.table_name, entry.name_column
    );
  end loop;
end;
$$;

commit;

-- Verify all nine indexes exist and are valid after applying.
select c.relname as index_name, i.indisunique, i.indisvalid
from pg_index i join pg_class c on c.oid = i.indexrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname like '%_normalized_name_unique';
