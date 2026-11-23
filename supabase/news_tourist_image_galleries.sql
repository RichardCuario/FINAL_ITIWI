-- Run in Supabase SQL Editor before saving multi-image News or Tourist Guide records.
alter table public.news
  add column if not exists image_urls jsonb not null default '[]'::jsonb;

alter table public.places
  add column if not exists image_urls jsonb not null default '[]'::jsonb;

-- Keep existing single-image records visible in the new galleries.
update public.news
set image_urls = jsonb_build_array(image_url)
where image_url is not null and btrim(image_url) <> '' and image_urls = '[]'::jsonb;

update public.places
set image_urls = jsonb_build_array(image_url)
where image_url is not null and btrim(image_url) <> '' and image_urls = '[]'::jsonb;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'news_image_urls_max_five') then
    alter table public.news add constraint news_image_urls_max_five
      check (jsonb_typeof(image_urls) = 'array' and jsonb_array_length(image_urls) <= 5);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'places_image_urls_max_five') then
    alter table public.places add constraint places_image_urls_max_five
      check (jsonb_typeof(image_urls) = 'array' and jsonb_array_length(image_urls) <= 5);
  end if;
end;
$$;
