-- Local LLM Models: Supabase Storage bucket (v1)
--
-- Purpose:
-- - Host LLM model files for download (CoreML, GGUF)
-- - Public read access (safe: models verified via SHA-256 + signed manifests)
-- - Service role upload only (prevents unauthorized modifications)
--
-- Security Model:
-- - Models are publicly readable (not sensitive data - open-source weights)
-- - Integrity: SHA-256 verification on client (prevents tampering)
-- - Authenticity: Signed manifests (Ed25519) prevent MITM
-- - Access Control: Only service role can upload/modify
--
-- Bucket:
-- - id/name: local-llm-models
-- - public: true (read access for all, write restricted)

INSERT INTO storage.buckets (id, name, public)
VALUES ('local-llm-models', 'local-llm-models', true)
ON CONFLICT (id) DO NOTHING;

-- Public read access (models are verified via SHA-256, so public access is safe)
DROP POLICY IF EXISTS "Public read access for LLM models" ON storage.objects;
CREATE POLICY "Public read access for LLM models" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'local-llm-models');

-- Service role can upload models (prevents unauthorized uploads)
DROP POLICY IF EXISTS "Service role can upload LLM models" ON storage.objects;
CREATE POLICY "Service role can upload LLM models" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );

-- Service role can update models (for model updates/rollbacks)
DROP POLICY IF EXISTS "Service role can update LLM models" ON storage.objects;
CREATE POLICY "Service role can update LLM models" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  )
  WITH CHECK (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );

-- Service role can delete models (for cleanup/rollbacks)
DROP POLICY IF EXISTS "Service role can delete LLM models" ON storage.objects;
CREATE POLICY "Service role can delete LLM models" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );

-- Optional: Track model downloads (for monitoring/analytics)
-- Uncomment if you want to track download patterns
/*
CREATE TABLE IF NOT EXISTS public.model_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  model_id TEXT NOT NULL,
  platform TEXT NOT NULL,
  downloaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  file_size_bytes BIGINT,
  download_duration_ms INTEGER,
  verification_passed BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_model_downloads_user_id 
  ON public.model_downloads(user_id);
CREATE INDEX IF NOT EXISTS idx_model_downloads_model_id 
  ON public.model_downloads(model_id);
CREATE INDEX IF NOT EXISTS idx_model_downloads_downloaded_at 
  ON public.model_downloads(downloaded_at DESC);

-- RLS for model_downloads (users can see their own downloads)
ALTER TABLE public.model_downloads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own downloads" ON public.model_downloads
  FOR SELECT
  USING (auth.uid() = user_id);
*/
