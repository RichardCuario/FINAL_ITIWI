-- =====================================================
-- Places and Place Reviews Setup
-- =====================================================
-- Creates:
--   - public.places
--   - public.place_reviews
-- Adds:
--   - updated_at trigger support
--   - indexes for admin/public queries
--   - row level security policies for public reads and authenticated submissions
--
-- Notes:
--   - This script assumes Supabase auth is enabled.
--   - Admin policies use auth.jwt() ->> 'role' = 'admin' to match a common
--     browser-admin setup. Adjust if your project uses a different admin claim.
--   - place_reviews.user_id references public.profiles(id) if that table exists.
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
  category text not null,
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
  updated_at timestamptz not null default timezone('utc', now()),
  constraint places_name_not_blank check (btrim(name) <> ''),
  constraint places_category_not_blank check (btrim(category) <> ''),
  constraint places_website_url_check check (
    website_url is null
    or website_url ~* '^https?://'
  ),
  constraint places_image_url_check check (
    image_url is null
    or image_url ~* '^https?://'
  ),
  constraint places_latitude_check check (
    latitude is null
    or (latitude >= -90 and latitude <= 90)
  ),
  constraint places_longitude_check check (
    longitude is null
    or (longitude >= -180 and longitude <= 180)
  )
);

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
  review_text text,
  status text not null default 'pending',
  admin_notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint place_reviews_rating_check check (rating between 1 and 5),
  constraint place_reviews_status_check check (status in ('pending', 'approved', 'rejected')),
  constraint place_reviews_reviewer_name_not_blank check (
    reviewer_name is null or btrim(reviewer_name) <> ''
  ),
  constraint place_reviews_review_text_not_blank check (
    review_text is null or btrim(review_text) <> ''
  )
);

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

comment on table public.places is 'Admin-managed destination/place listings for tourism, religious, and popular spots.';
comment on table public.place_reviews is 'User-submitted reviews and moderation records for places.';
comment on column public.place_reviews.status is 'Moderation status: pending, approved, rejected.';

commit;