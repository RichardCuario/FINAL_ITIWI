drop policy if exists "Authenticated users can submit place reviews" on public.place_reviews;

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
