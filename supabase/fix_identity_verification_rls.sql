-- Stricter admin-only policy for identity verification approvals.
-- This keeps RLS enabled and restricts sensitive writes to authenticated admins.

DROP POLICY IF EXISTS "Users can view their own verification" ON identity_verification;
DROP POLICY IF EXISTS "Users can insert their own verification" ON identity_verification;
DROP POLICY IF EXISTS "Users can update their own verification" ON identity_verification;
DROP POLICY IF EXISTS "Service role can manage all verifications" ON identity_verification;
DROP POLICY IF EXISTS "Admins can manage all verification records" ON identity_verification;
DROP POLICY IF EXISTS "Admins can manage all users" ON users;
DROP POLICY IF EXISTS "Users can view their own user record" ON users;
DROP POLICY IF EXISTS "Users can create their own user record" ON users;
DROP POLICY IF EXISTS "Users can update their own user record" ON users;

CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
  SELECT (
    COALESCE((auth.jwt() -> 'app_metadata' ->> 'role'), '') ILIKE '%admin%' OR
    COALESCE((auth.jwt() -> 'user_metadata' ->> 'role'), '') ILIKE '%admin%' OR
    COALESCE((auth.jwt() -> 'app_metadata' ->> 'is_super_admin'), '') = 'true' OR
    COALESCE((auth.jwt() -> 'user_metadata' ->> 'is_super_admin'), '') = 'true' OR
    COALESCE((auth.jwt() -> 'app_metadata' ->> 'isAdmin'), '') = 'true' OR
    COALESCE((auth.jwt() -> 'user_metadata' ->> 'isAdmin'), '') = 'true'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_user_active(p_user_id TEXT)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT COALESCE(
    (SELECT is_active FROM public.users WHERE id = p_user_id),
    TRUE
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_user_active(TEXT) TO anon, authenticated;

ALTER TABLE identity_verification ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own verification"
ON identity_verification FOR SELECT
TO authenticated
USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can insert their own verification"
ON identity_verification FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their own verification"
ON identity_verification FOR UPDATE
TO authenticated
USING (auth.uid()::TEXT = user_id)
WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Admins can manage all verification records"
ON identity_verification FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

CREATE POLICY "Users can view their own user record"
ON users FOR SELECT
TO authenticated
USING (auth.uid()::TEXT = id);

CREATE POLICY "Users can create their own user record"
ON users FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::TEXT = id);

CREATE POLICY "Users can update their own user record"
ON users FOR UPDATE
TO authenticated
USING (auth.uid()::TEXT = id)
WITH CHECK (auth.uid()::TEXT = id);

CREATE POLICY "Admins can manage all users"
ON users FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());
