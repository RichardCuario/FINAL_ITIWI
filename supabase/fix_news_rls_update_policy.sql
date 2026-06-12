-- Fix RLS UPDATE policy for news table
-- This allows authenticated users (admins) to update news articles

-- Check if RLS is enabled
ALTER TABLE news ENABLE ROW LEVEL SECURITY;

-- Drop existing UPDATE policy if it exists
DROP POLICY IF EXISTS "Allow authenticated users to update news" ON news;

-- Create UPDATE policy for authenticated users
CREATE POLICY "Allow authenticated users to update news" ON news
FOR UPDATE
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Ensure SELECT and INSERT policies exist
DROP POLICY IF EXISTS "Allow public read access to news" ON news;
CREATE POLICY "Allow public read access to news" ON news
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert news" ON news;
CREATE POLICY "Allow authenticated users to insert news" ON news
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow authenticated users to delete news" ON news;
CREATE POLICY "Allow authenticated users to delete news" ON news
FOR DELETE
USING (auth.role() = 'authenticated');
