-- Create identity_verification table for tracking user ID verification
CREATE TABLE IF NOT EXISTS identity_verification (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Personal Information
  full_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  
  -- ID Information
  id_type TEXT NOT NULL, -- 'national_id', 'driver_license', 'passport', 'voter_id'
  id_number TEXT NOT NULL,
  
  -- Files
  id_front_photo_url TEXT,
  id_back_photo_url TEXT,
  selfie_photo_url TEXT,
  
  -- Status
  verification_status TEXT DEFAULT 'pending', -- 'pending', 'verified', 'rejected'
  rejection_reason TEXT,
  
  -- Timestamps
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  verified_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id) -- One verification per user
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_identity_verification_user_id ON identity_verification(user_id);
CREATE INDEX IF NOT EXISTS idx_identity_verification_status ON identity_verification(verification_status);

-- Add verification_status column to users table if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_completed_at TIMESTAMP WITH TIME ZONE;

-- Update RLS policies for identity_verification table
DROP POLICY IF EXISTS "Users can view their own verification" ON identity_verification;
DROP POLICY IF EXISTS "Users can insert their own verification" ON identity_verification;
DROP POLICY IF EXISTS "Users can update their own verification" ON identity_verification;

CREATE POLICY "Users can view their own verification"
ON identity_verification FOR SELECT
USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can insert their own verification"
ON identity_verification FOR INSERT
WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their own verification"
ON identity_verification FOR UPDATE
USING (auth.uid()::TEXT = user_id)
WITH CHECK (auth.uid()::TEXT = user_id);

-- Allow service role (admin) to view all verifications
CREATE POLICY "Service role can manage all verifications"
ON identity_verification
TO service_role
USING (true)
WITH CHECK (true);

-- Enable RLS
ALTER TABLE identity_verification ENABLE ROW LEVEL SECURITY;
