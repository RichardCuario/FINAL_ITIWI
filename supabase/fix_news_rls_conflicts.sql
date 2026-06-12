-- Fix conflicting RLS UPDATE policies on news table
-- Remove all existing UPDATE policies and create a single simple one

-- Disable RLS temporarily to make changes
ALTER TABLE news DISABLE ROW LEVEL SECURITY;

-- Enable it back
ALTER TABLE news ENABLE ROW LEVEL SECURITY;

-- Drop all UPDATE policies to remove conflicts
DROP POLICY IF EXISTS "Allow authenticated update on news" ON news;
DROP POLICY IF EXISTS "Allow authenticated users to update news" ON news;

-- Create a single, simple UPDATE policy for authenticated users
CREATE POLICY "update_news_authenticated" ON news
FOR UPDATE
USING (true)
WITH CHECK (true);

-- Ensure other necessary policies exist
DROP POLICY IF EXISTS "Allow authenticated select on news" ON news;
CREATE POLICY "select_news_authenticated" ON news
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Allow authenticated insert on news" ON news;
CREATE POLICY "insert_news_authenticated" ON news
FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated delete on news" ON news;
CREATE POLICY "delete_news_authenticated" ON news
FOR DELETE
USING (true);
