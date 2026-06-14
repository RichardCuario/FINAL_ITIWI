-- Add missing columns to news table if they don't exist
ALTER TABLE news ADD COLUMN IF NOT EXISTS category text;
ALTER TABLE news ADD COLUMN IF NOT EXISTS scheduled_at timestamptz;
ALTER TABLE news ADD COLUMN IF NOT EXISTS is_published boolean DEFAULT false;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS news_category_idx ON news(category);
CREATE INDEX IF NOT EXISTS news_scheduled_at_idx ON news(scheduled_at);
CREATE INDEX IF NOT EXISTS news_is_published_idx ON news(is_published);

-- Set default category for existing records
UPDATE news SET category = 'Announcement' WHERE category IS NULL;

-- Update existing news to be published if they don't have scheduled_at set
UPDATE news SET is_published = true WHERE scheduled_at IS NULL;

-- Create a function to publish scheduled news automatically
CREATE OR REPLACE FUNCTION public.publish_scheduled_news()
RETURNS void AS $$
BEGIN
  UPDATE public.news
  SET is_published = true
  WHERE scheduled_at IS NOT NULL
    AND scheduled_at <= NOW()
    AND is_published = false;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to check and publish when a news record is inserted/updated
CREATE OR REPLACE FUNCTION public.check_and_publish_news()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.scheduled_at IS NOT NULL AND NEW.scheduled_at <= NOW() THEN
    NEW.is_published := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_and_publish_news ON news;

CREATE TRIGGER trigger_check_and_publish_news
BEFORE INSERT OR UPDATE ON news
FOR EACH ROW
EXECUTE FUNCTION public.check_and_publish_news();

