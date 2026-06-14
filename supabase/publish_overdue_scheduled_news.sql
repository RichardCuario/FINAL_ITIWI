-- Manually publish all scheduled posts that are now due
UPDATE public.news
SET is_published = true
WHERE scheduled_at IS NOT NULL
  AND scheduled_at <= NOW()
  AND is_published = false;

-- Check how many were updated
SELECT COUNT(*) as news_published FROM public.news
WHERE scheduled_at IS NOT NULL
  AND scheduled_at <= NOW()
  AND is_published = true;
