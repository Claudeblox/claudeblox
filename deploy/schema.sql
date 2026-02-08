-- ClaudeBlox schema for Supabase
-- Run this in the SQL Editor in Supabase dashboard

CREATE SCHEMA IF NOT EXISTS claudeblox;

CREATE TABLE IF NOT EXISTS claudeblox.logs (
    id BIGSERIAL PRIMARY KEY,
    action TEXT NOT NULL,
    message TEXT DEFAULT '',
    role TEXT DEFAULT 'system',
    details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast recent logs queries
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON claudeblox.logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_action ON claudeblox.logs (action);
