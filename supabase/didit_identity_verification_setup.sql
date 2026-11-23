-- Run this after the existing identity_verification setup.
-- Didit owns document capture; the app no longer stores document images or ID numbers.
ALTER TABLE public.identity_verification
  ALTER COLUMN full_name DROP NOT NULL,
  ALTER COLUMN date_of_birth DROP NOT NULL,
  ALTER COLUMN id_type DROP NOT NULL,
  ALTER COLUMN id_number DROP NOT NULL;

ALTER TABLE public.identity_verification
  ADD COLUMN IF NOT EXISTS didit_session_id TEXT,
  ADD COLUMN IF NOT EXISTS didit_status TEXT,
  ADD COLUMN IF NOT EXISTS didit_decision JSONB;

CREATE UNIQUE INDEX IF NOT EXISTS identity_verification_didit_session_id_key
  ON public.identity_verification (didit_session_id)
  WHERE didit_session_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.didit_webhook_events (
  event_id TEXT PRIMARY KEY,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.didit_webhook_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.didit_webhook_events FROM anon, authenticated;
