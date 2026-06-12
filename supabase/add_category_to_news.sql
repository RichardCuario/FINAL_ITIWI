-- Add category column to news table
ALTER TABLE news ADD COLUMN IF NOT EXISTS category text;

-- Optional: Set a default value for existing records
UPDATE news SET category = 'Announcement' WHERE category IS NULL;
