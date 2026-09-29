-- Create storage bucket for identity verification ID uploads
-- Run this in Supabase SQL Editor

-- Create the storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('identity-uploads', 'identity-uploads', true)
ON CONFLICT (id) DO UPDATE SET public = true;
