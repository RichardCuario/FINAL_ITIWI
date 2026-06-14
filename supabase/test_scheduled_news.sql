-- Test scheduled news functionality
-- Run this to see what's in your news table

-- See all news with their publish status
SELECT id, title, is_published, scheduled_at, created_at, NOW() as current_time
FROM news
ORDER BY created_at DESC
LIMIT 20;

-- Count how many are scheduled vs published
SELECT
  COUNT(*) as total_news,
  SUM(CASE WHEN is_published = true THEN 1 ELSE 0 END) as published,
  SUM(CASE WHEN is_published = false THEN 1 ELSE 0 END) as unpublished_scheduled,
  SUM(CASE WHEN scheduled_at IS NOT NULL THEN 1 ELSE 0 END) as has_scheduled_time
FROM news;

-- Check if there are any scheduled posts that should be published now
SELECT id, title, scheduled_at, is_published
FROM news
WHERE scheduled_at IS NOT NULL
  AND scheduled_at <= NOW()
  AND is_published = false;

-- Manually publish overdue scheduled news and verify
UPDATE public.news
SET is_published = true
WHERE scheduled_at IS NOT NULL
  AND scheduled_at <= NOW()
  AND is_published = false;

-- Check result
SELECT id, title, scheduled_at, is_published
FROM news
WHERE scheduled_at IS NOT NULL
ORDER BY scheduled_at DESC
LIMIT 10;
