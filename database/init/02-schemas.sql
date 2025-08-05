-- YTEmpire Database Schemas
-- Create all required schemas

-- Drop schemas if they exist (for clean installation)
DROP SCHEMA IF EXISTS users CASCADE;
DROP SCHEMA IF EXISTS content CASCADE;
DROP SCHEMA IF EXISTS analytics CASCADE;
DROP SCHEMA IF EXISTS campaigns CASCADE;
DROP SCHEMA IF EXISTS system CASCADE;

-- Create schemas
CREATE SCHEMA users;
CREATE SCHEMA content;
CREATE SCHEMA analytics;
CREATE SCHEMA campaigns;
CREATE SCHEMA system;

-- Set search path
SET search_path TO users, content, analytics, campaigns, system, public;

-- Create update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;