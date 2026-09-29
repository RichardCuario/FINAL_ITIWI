-- Adds the optional profile photo captured with each new place review.
-- Existing reviews keep their initials avatar when no photo was saved.

alter table public.place_reviews
  add column if not exists reviewer_photo_url text;

comment on column public.place_reviews.reviewer_photo_url is
  'Public profile photo URL captured from the reviewer at review submission.';
