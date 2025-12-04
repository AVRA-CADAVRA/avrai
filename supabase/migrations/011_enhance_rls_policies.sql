-- Migration: Enhance RLS Policies for Security
-- Created: 2025-11-30
-- Purpose: Enhance RLS policies to ensure users can only access their own data

-- Note: This migration assumes users table exists from previous migrations
-- Adjust table names and columns based on your actual schema

-- Ensure RLS is enabled on users table (if not already)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables WHERE tablename = 'users' AND rowsecurity = true
  ) THEN
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Policy: Users can only SELECT their own data
-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can view their own data" ON users;

CREATE POLICY "Users can view their own data"
  ON users
  FOR SELECT
  USING (auth.uid()::text = id);

-- Policy: Users can only UPDATE their own data
DROP POLICY IF EXISTS "Users can update their own data" ON users;

CREATE POLICY "Users can update their own data"
  ON users
  FOR UPDATE
  USING (auth.uid()::text = id)
  WITH CHECK (auth.uid()::text = id);

-- Policy: Users can only DELETE their own data
DROP POLICY IF EXISTS "Users can delete their own data" ON users;

CREATE POLICY "Users can delete their own data"
  ON users
  FOR DELETE
  USING (auth.uid()::text = id);

-- Policy: Service role can access all data (for admin operations)
DROP POLICY IF EXISTS "Service role can access all data" ON users;

CREATE POLICY "Service role can access all data"
  ON users
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Add comment
COMMENT ON POLICY "Users can view their own data" ON users IS 'RLS policy ensuring users can only view their own data';
COMMENT ON POLICY "Users can update their own data" ON users IS 'RLS policy ensuring users can only update their own data';
COMMENT ON POLICY "Service role can access all data" ON users IS 'RLS policy allowing service role (admin) to access all data';

