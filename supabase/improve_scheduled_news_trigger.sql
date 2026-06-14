-- Enhanced trigger to handle scheduled news publishing
-- This replaces the previous trigger with better logic

CREATE OR REPLACE FUNCTION public.check_and_publish_news()
RETURNS TRIGGER AS $$
BEGIN
  -- If scheduled_at is set and the time has passed, mark as published
  IF NEW.scheduled_at IS NOT NULL AND NEW.scheduled_at <= NOW() THEN
    NEW.is_published := true;
  -- If scheduled_at is in the future, mark as unpublished
  ELSIF NEW.scheduled_at IS NOT NULL AND NEW.scheduled_at > NOW() THEN
    NEW.is_published := false;
  -- If no scheduled_at, publish immediately
  ELSIF NEW.scheduled_at IS NULL THEN
    NEW.is_published := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate the trigger
DROP TRIGGER IF EXISTS trigger_check_and_publish_news ON news;

CREATE TRIGGER trigger_check_and_publish_news
BEFORE INSERT OR UPDATE ON news
FOR EACH ROW
EXECUTE FUNCTION public.check_and_publish_news();

-- Drop the old function first (if it exists with different signature)
DROP FUNCTION IF EXISTS public.publish_scheduled_news();

-- Create a stored procedure to manually publish overdue scheduled news
CREATE FUNCTION public.publish_scheduled_news()
RETURNS void AS $$
BEGIN
  UPDATE public.news
  SET is_published = true
  WHERE scheduled_at IS NOT NULL
    AND scheduled_at <= NOW()
    AND is_published = false;
END;
$$ LANGUAGE plpgsql;
