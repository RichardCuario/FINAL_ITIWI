-- =====================================================
-- Tourist Guide / Places Database Setup
-- =====================================================
-- Creates and aligns the database used by:
--   - admin_vercel/tourist_guide.html
--   - admin_vercel/places.html
--   - lib/tourist_guide_page.dart
--   - lib/place_service.dart
--
-- Tables:
--   - public.places
--   - public.place_reviews
--
-- This script is safe to run on an existing project because it uses
-- IF NOT EXISTS checks and additive ALTER TABLE statements where possible.
-- =====================================================

begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Tourist destination',
  location text,
  short_location text,
  full_address text,
  description text,
  image_url text,
  phone text,
  website_url text,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  distance_label text,
  is_featured boolean not null default false,
  is_published boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.places
  add column if not exists location text,
  add column if not exists short_location text,
  add column if not exists full_address text,
  add column if not exists description text,
  add column if not exists image_url text,
  add column if not exists phone text,
  add column if not exists website_url text,
  add column if not exists latitude numeric(10, 7),
  add column if not exists longitude numeric(10, 7),
  add column if not exists distance_label text,
  add column if not exists is_featured boolean not null default false,
  add column if not exists is_published boolean not null default true,
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'places_name_not_blank'
  ) then
    alter table public.places
      add constraint places_name_not_blank check (btrim(name) <> '');
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'places_category_not_blank'
  ) then
    alter table public.places
      add constraint places_category_not_blank check (btrim(category) <> '');
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'places_website_url_check'
  ) then
    alter table public.places
      add constraint places_website_url_check check (
        website_url is null or website_url ~* '^https?://'
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'places_image_url_check'
  ) then
    alter table public.places
      add constraint places_image_url_check check (
        image_url is null or image_url ~* '^https?://'
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'places_latitude_check'
  ) then
    alter table public.places
      add constraint places_latitude_check check (
        latitude is null or (latitude >= -90 and latitude <= 90)
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'places_longitude_check'
  ) then
    alter table public.places
      add constraint places_longitude_check check (
        longitude is null or (longitude >= -180 and longitude <= 180)
      );
  end if;
end $$;

update public.places
set location = coalesce(nullif(location, ''), nullif(short_location, ''), nullif(full_address, ''))
where coalesce(location, '') = '';

update public.places
set short_location = coalesce(nullif(short_location, ''), nullif(location, ''))
where coalesce(short_location, '') = '' and coalesce(location, '') <> '';

create or replace function public.sync_place_location_fields()
returns trigger
language plpgsql
as $$
begin
  if coalesce(new.location, '') = '' then
    new.location := coalesce(nullif(new.short_location, ''), nullif(new.full_address, ''), '');
  end if;

  if coalesce(new.short_location, '') = '' then
    new.short_location := coalesce(nullif(new.location, ''), '');
  end if;

  return new;
end;
$$;

drop trigger if exists sync_place_location_fields on public.places;
create trigger sync_place_location_fields
before insert or update on public.places
for each row
execute function public.sync_place_location_fields();

create index if not exists places_name_idx
  on public.places using btree (name);

create index if not exists places_category_idx
  on public.places using btree (category);

create index if not exists places_is_published_idx
  on public.places using btree (is_published);

create index if not exists places_is_featured_idx
  on public.places using btree (is_featured);

create index if not exists places_created_at_idx
  on public.places using btree (created_at desc);

drop trigger if exists set_places_updated_at on public.places;
create trigger set_places_updated_at
before update on public.places
for each row
execute function public.set_updated_at();

create table if not exists public.place_reviews (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  user_id uuid,
  reviewer_name text,
  rating smallint not null,
  review text,
  review_text text,
  status text not null default 'pending',
  admin_notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.place_reviews
  add column if not exists user_id uuid,
  add column if not exists reviewer_name text,
  add column if not exists rating smallint,
  add column if not exists review text,
  add column if not exists review_text text,
  add column if not exists status text not null default 'pending',
  add column if not exists admin_notes text,
  add column if not exists created_at timestamptz not null default timezone('utc', now()),
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'place_reviews_rating_check'
  ) then
    alter table public.place_reviews
      add constraint place_reviews_rating_check check (rating between 1 and 5);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'place_reviews_status_check'
  ) then
    alter table public.place_reviews
      add constraint place_reviews_status_check check (status in ('pending', 'approved', 'rejected'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'place_reviews_reviewer_name_not_blank'
  ) then
    alter table public.place_reviews
      add constraint place_reviews_reviewer_name_not_blank check (
        reviewer_name is null or btrim(reviewer_name) <> ''
      );
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'place_reviews_review_text_not_blank'
  ) then
    alter table public.place_reviews
      add constraint place_reviews_review_text_not_blank check (
        review_text is null or btrim(review_text) <> ''
      );
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'place_reviews_review_not_blank'
  ) then
    alter table public.place_reviews
      add constraint place_reviews_review_not_blank check (
        review is null or btrim(review) <> ''
      );
  end if;
end $$;

update public.place_reviews
set review_text = coalesce(nullif(review_text, ''), nullif(review, ''))
where coalesce(review_text, '') = '';

update public.place_reviews
set review = coalesce(nullif(review, ''), nullif(review_text, ''))
where coalesce(review, '') = '';

create or replace function public.sync_place_review_fields()
returns trigger
language plpgsql
as $$
begin
  if coalesce(new.review_text, '') = '' then
    new.review_text := coalesce(nullif(new.review, ''), '');
  end if;

  if coalesce(new.review, '') = '' then
    new.review := coalesce(nullif(new.review_text, ''), '');
  end if;

  return new;
end;
$$;

drop trigger if exists sync_place_review_fields on public.place_reviews;
create trigger sync_place_review_fields
before insert or update on public.place_reviews
for each row
execute function public.sync_place_review_fields();

create index if not exists place_reviews_place_id_idx
  on public.place_reviews using btree (place_id);

create index if not exists place_reviews_status_idx
  on public.place_reviews using btree (status);

create index if not exists place_reviews_created_at_idx
  on public.place_reviews using btree (created_at desc);

create index if not exists place_reviews_place_status_idx
  on public.place_reviews using btree (place_id, status);

create index if not exists place_reviews_user_id_idx
  on public.place_reviews using btree (user_id);

drop trigger if exists set_place_reviews_updated_at on public.place_reviews;
create trigger set_place_reviews_updated_at
before update on public.place_reviews
for each row
execute function public.set_updated_at();

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'profiles'
  ) then
    begin
      alter table public.place_reviews
        add constraint place_reviews_user_id_fkey
        foreign key (user_id)
        references public.profiles(id)
        on delete set null;
    exception
      when duplicate_object then
        null;
    end;
  end if;
end $$;

alter table public.places enable row level security;
alter table public.place_reviews enable row level security;

drop policy if exists "Public can read published places" on public.places;
create policy "Public can read published places"
on public.places
for select
to anon, authenticated
using (is_published = true);

drop policy if exists "Admins can manage places" on public.places;
create policy "Admins can manage places"
on public.places
for all
to authenticated
using ((auth.jwt() ->> 'role') = 'admin')
with check ((auth.jwt() ->> 'role') = 'admin');

drop policy if exists "Public can read approved place reviews" on public.place_reviews;
create policy "Public can read approved place reviews"
on public.place_reviews
for select
to anon, authenticated
using (
  status = 'approved'
  and exists (
    select 1
    from public.places p
    where p.id = place_reviews.place_id
      and p.is_published = true
  )
);

drop policy if exists "Authenticated users can submit place reviews" on public.place_reviews;
create policy "Authenticated users can submit place reviews"
on public.place_reviews
for insert
to authenticated
with check (
  status = 'pending'
  and rating between 1 and 5
  and (user_id is null or user_id = auth.uid())
  and exists (
    select 1
    from public.places p
    where p.id = place_reviews.place_id
      and p.is_published = true
  )
);

drop policy if exists "Authors can update their pending place reviews" on public.place_reviews;
create policy "Authors can update their pending place reviews"
on public.place_reviews
for update
to authenticated
using (
  user_id = auth.uid()
  and status = 'pending'
)
with check (
  user_id = auth.uid()
  and status = 'pending'
);

drop policy if exists "Admins can manage place reviews" on public.place_reviews;
create policy "Admins can manage place reviews"
on public.place_reviews
for all
to authenticated
using ((auth.jwt() ->> 'role') = 'admin')
with check ((auth.jwt() ->> 'role') = 'admin');

comment on table public.places is 'Admin-managed tourist guide destination listings.';
comment on table public.place_reviews is 'Tourist guide visitor reviews and moderation records.';
comment on column public.places.location is 'Compatibility field used by the Flutter tourist guide page.';
comment on column public.places.short_location is 'Admin-facing short location label.';
comment on column public.place_reviews.review is 'Compatibility field used by the Flutter app submitReview().';
comment on column public.place_reviews.review_text is 'Canonical review body text for admin moderation and display.';

commit;
