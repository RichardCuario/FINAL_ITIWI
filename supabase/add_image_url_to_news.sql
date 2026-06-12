-- Add image_url column to news table if it doesn't exist
ALTER TABLE news ADD COLUMN IF NOT EXISTS image_url text;

-- Create storage policy for NEWS bucket
CREATE POLICY "Allow public read access to news images" ON storage.objects
FOR SELECT
USING (bucket_id = 'NEWS');

CREATE POLICY "Allow authenticated users to upload news images" ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'NEWS'
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to delete their news images" ON storage.objects
FOR DELETE
USING (
  bucket_id = 'NEWS'
  AND auth.role() = 'authenticated'
);

