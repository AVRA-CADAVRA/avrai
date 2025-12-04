-- Migration: Audit Log Table
-- Created: 2025-11-30
-- Purpose: Create audit log table for tracking sensitive data access and security events

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  type TEXT NOT NULL, -- 'data_access', 'security_event', 'data_modification', 'anonymization'
  user_id TEXT, -- User ID (if applicable)
  agent_id TEXT, -- Agent ID (if applicable)
  field_name TEXT, -- Field name (if applicable)
  action TEXT, -- Action performed ('read', 'write', 'delete', 'update', etc.)
  event_type TEXT, -- Event type (for security events)
  status TEXT, -- Status ('success', 'failure', 'blocked')
  old_value TEXT, -- Previous value (may be masked)
  new_value TEXT, -- New value (may be masked)
  metadata JSONB, -- Additional metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_agent_id ON audit_logs(agent_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_type ON audit_logs(type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_field_name ON audit_logs(field_name);

-- RLS Policies for audit_logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own audit logs
CREATE POLICY "Users can view their own audit logs"
  ON audit_logs
  FOR SELECT
  USING (auth.uid()::text = user_id);

-- Policy: Service role can insert audit logs
CREATE POLICY "Service role can insert audit logs"
  ON audit_logs
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

-- Policy: Service role can view all audit logs (for security monitoring)
CREATE POLICY "Service role can view all audit logs"
  ON audit_logs
  FOR SELECT
  USING (auth.role() = 'service_role');

-- Policy: No updates or deletes allowed (audit logs are immutable)
-- (No policies needed - default deny all)

-- Add comment
COMMENT ON TABLE audit_logs IS 'Audit log table for tracking sensitive data access and security events';

