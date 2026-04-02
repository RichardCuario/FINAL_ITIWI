alter table public.place_reviews enable row level security;

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
drop policy if exists "Anyone can submit place reviews" on public.place_reviews;
create policy "Anyone can submit place reviews"
on public.place_reviews
for insert
to anon, authenticated
with check (
  status = 'pending'
  and rating between 1 and 5
  and (
    user_id is null
    or user_id = auth.uid()
  )
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
