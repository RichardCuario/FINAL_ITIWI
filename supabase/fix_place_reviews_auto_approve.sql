-- =====================================================
-- Fix Place Reviews Auto-Approval Policy
-- =====================================================
-- This updates the RLS policy to allow auto-approved reviews

drop policy if exists "Authenticated users can submit place reviews" on public.place_reviews;
create policy "Authenticated users can submit place reviews"
on public.place_reviews
for insert
to authenticated
with check (
  status in ('approved', 'pending')
  and rating between 1 and 5
  and (user_id is null or user_id = auth.uid())
  and exists (
    select 1
    from public.places p
    where p.id = place_reviews.place_id
      and p.is_published = true
  )
);

-- Also allow anon users (unauthenticated) to submit reviews with auto-approval
drop policy if exists "Anyone can submit place reviews" on public.place_reviews;
create policy "Anyone can submit place reviews"
on public.place_reviews
for insert
to anon, authenticated
with check (
  status in ('approved', 'pending')
  and rating between 1 and 5
  and exists (
    select 1
    from public.places p
    where p.id = place_reviews.place_id
      and p.is_published = true
  )
);
