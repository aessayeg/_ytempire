-- 02-schemas.sql: Create database schemas
-- YTEmpire MVP Schema Organization
-- Purpose: Logical separation of different data domains

\c ytempire_dev;

-- Create schemas for logical data organization
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS content;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS campaigns;

-- Set search path to include all schemas
ALTER DATABASE ytempire_dev SET search_path TO public, analytics, content, users, campaigns;

-- Grant usage permissions to application user (will be created later)
-- This ensures proper access control
DO $$
BEGIN
    -- Grant schema usage (will be applied when app user is created)
    RAISE NOTICE 'Schemas created: analytics, content, users, campaigns';
END $$;

-- Create comments for documentation
COMMENT ON SCHEMA analytics IS 'YouTube analytics data, metrics, and time-series data';
COMMENT ON SCHEMA content IS 'Video metadata, thumbnails, descriptions, and tags';
COMMENT ON SCHEMA users IS 'User management, authentication, and permissions';
COMMENT ON SCHEMA campaigns IS 'Marketing campaigns, ROI metrics, and performance tracking';