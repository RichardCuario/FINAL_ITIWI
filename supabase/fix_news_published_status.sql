-- Update all existing news to be published (set is_published to true)
UPDATE public.news
SET is_published = true
WHERE is_published IS NULL OR is_published = false;

-- Verify the update
SELECT COUNT(*) as total_published FROM public.news WHERE is_published = true;
