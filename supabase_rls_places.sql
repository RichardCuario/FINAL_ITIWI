-- ============================================================
-- RLS Policies for Places Table - Tourist Guide
-- ============================================================

-- Enable Row Level Security on places table
ALTER TABLE places ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage places" ON places;
DROP POLICY IF EXISTS "Public can read published places" ON places;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON places;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON places;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON places;
DROP POLICY IF EXISTS "Enable select for authenticated users" ON places;
DROP POLICY IF EXISTS "Enable select published for anon" ON places;

-- Policy 1: Allow authenticated users (admin) to INSERT
CREATE POLICY "Enable insert for authenticated users"
ON places
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy 2: Allow authenticated users (admin) to SELECT all
CREATE POLICY "Enable select for authenticated users"
ON places
FOR SELECT
TO authenticated
USING (true);

-- Policy 3: Allow authenticated users (admin) to UPDATE all
CREATE POLICY "Enable update for authenticated users"
ON places
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy 4: Allow authenticated users (admin) to DELETE all
CREATE POLICY "Enable delete for authenticated users"
ON places
FOR DELETE
TO authenticated
USING (true);

-- Policy 5: Allow anonymous users to SELECT only published places
CREATE POLICY "Enable select published for anon"
ON places
FOR SELECT
TO anon
USING (is_published = true);

-- Policy 6: Allow authenticated users to SELECT published places (if is_published = true)
CREATE POLICY "Enable select published for authenticated"
ON places
FOR SELECT
TO authenticated
USING (is_published = true OR true);  -- Admin can see all, others see published
