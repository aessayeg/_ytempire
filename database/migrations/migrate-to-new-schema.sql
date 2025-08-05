-- YTEmpire Schema Migration Script
-- Migrates from old single-schema structure to new multi-schema structure
-- IMPORTANT: Backup your database before running this migration!

BEGIN;

-- Step 1: Create new schemas and tables
-- (This assumes the new schema files have not been run yet)

-- Create extensions if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create new schemas
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS content;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS campaigns;
CREATE SCHEMA IF NOT EXISTS system;

-- Create update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create new tables (run schema files 03-07)
-- Note: In production, you would include the full schema here
-- For brevity, assuming the schema files are run separately

-- Step 3: Migrate data from old tables to new tables

-- Migrate users to users.accounts and users.profiles
INSERT INTO users.accounts (
    account_id,
    email,
    username,
    password_hash,
    account_type,
    account_status,
    email_verified,
    created_at,
    updated_at
)
SELECT 
    id,
    email,
    username,
    password_hash,
    CASE 
        WHEN role = 'admin' THEN 'admin'
        WHEN role = 'user' THEN 'creator'
        ELSE 'creator'
    END as account_type,
    CASE 
        WHEN is_active THEN 'active'
        ELSE 'suspended'
    END as account_status,
    email_verified,
    created_at,
    updated_at
FROM ytempire.users
ON CONFLICT (email) DO NOTHING;

-- Create profiles for migrated users
INSERT INTO users.profiles (
    account_id,
    first_name,
    last_name,
    avatar_url,
    created_at,
    updated_at
)
SELECT 
    id,
    first_name,
    last_name,
    avatar_url,
    created_at,
    updated_at
FROM ytempire.users
WHERE id IN (SELECT account_id FROM users.accounts)
ON CONFLICT DO NOTHING;

-- Migrate channels to content.channels
INSERT INTO content.channels (
    channel_id,
    account_id,
    youtube_channel_id,
    channel_name,
    description,
    thumbnail_url,
    status,
    created_at,
    updated_at
)
SELECT 
    id,
    user_id,
    youtube_channel_id,
    name,
    description,
    thumbnail_url,
    CASE 
        WHEN is_active THEN 'active'
        ELSE 'inactive'
    END as status,
    created_at,
    updated_at
FROM ytempire.channels
WHERE user_id IN (SELECT account_id FROM users.accounts)
ON CONFLICT (youtube_channel_id) DO NOTHING;

-- Migrate videos to content.videos
INSERT INTO content.videos (
    video_id,
    channel_id,
    youtube_video_id,
    title,
    description,
    tags,
    thumbnail_url,
    duration_seconds,
    published_at,
    privacy_status,
    upload_status,
    created_at,
    updated_at
)
SELECT 
    id,
    channel_id,
    youtube_video_id,
    title,
    description,
    tags,
    thumbnail_url,
    duration,
    published_at,
    CASE 
        WHEN status = 'published' THEN 'public'
        WHEN status = 'draft' THEN 'private'
        ELSE 'private'
    END as privacy_status,
    CASE 
        WHEN status = 'published' THEN 'processed'
        ELSE status
    END as upload_status,
    created_at,
    updated_at
FROM ytempire.videos
WHERE channel_id IN (SELECT channel_id FROM content.channels)
ON CONFLICT (youtube_video_id) DO NOTHING;

-- Migrate analytics to analytics.video_analytics
-- First, get the date range for partitions
DO $$
DECLARE
    min_date DATE;
    max_date DATE;
    curr_date DATE;
BEGIN
    SELECT MIN(date), MAX(date) INTO min_date, max_date FROM ytempire.analytics;
    
    IF min_date IS NOT NULL THEN
        curr_date := DATE_TRUNC('month', min_date);
        
        -- Create partitions for the date range
        WHILE curr_date <= DATE_TRUNC('month', max_date) + INTERVAL '1 month' LOOP
            PERFORM create_monthly_partition('video_analytics', curr_date);
            curr_date := curr_date + INTERVAL '1 month';
        END LOOP;
    END IF;
END $$;

-- Migrate analytics data
INSERT INTO analytics.video_analytics (
    video_id,
    date,
    views,
    watch_time_minutes,
    likes,
    comments,
    created_at
)
SELECT 
    video_id,
    date,
    views,
    watch_time / 60, -- Convert seconds to minutes
    likes,
    comments,
    created_at
FROM ytempire.analytics
WHERE video_id IN (SELECT video_id FROM content.videos)
ON CONFLICT (video_id, date) DO NOTHING;

-- Step 4: Update sequences to continue from old values
-- Get max values and update sequences
DO $$
DECLARE
    max_id UUID;
BEGIN
    -- Update any sequences if needed
    -- UUID columns don't use sequences, so this is mainly for any SERIAL columns
END $$;

-- Step 5: Create views for backward compatibility (optional)
CREATE OR REPLACE VIEW ytempire.users_view AS
SELECT 
    a.account_id as id,
    a.email,
    a.username,
    a.password_hash,
    p.first_name,
    p.last_name,
    p.avatar_url,
    a.email_verified,
    a.account_status = 'active' as is_active,
    CASE 
        WHEN a.account_type = 'admin' THEN 'admin'
        ELSE 'user'
    END as role,
    a.created_at,
    a.updated_at
FROM users.accounts a
LEFT JOIN users.profiles p ON a.account_id = p.account_id;

-- Step 6: Verify migration
DO $$
DECLARE
    old_user_count INTEGER;
    new_user_count INTEGER;
    old_channel_count INTEGER;
    new_channel_count INTEGER;
    old_video_count INTEGER;
    new_video_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_user_count FROM ytempire.users;
    SELECT COUNT(*) INTO new_user_count FROM users.accounts;
    
    SELECT COUNT(*) INTO old_channel_count FROM ytempire.channels;
    SELECT COUNT(*) INTO new_channel_count FROM content.channels;
    
    SELECT COUNT(*) INTO old_video_count FROM ytempire.videos;
    SELECT COUNT(*) INTO new_video_count FROM content.videos;
    
    RAISE NOTICE 'Migration Summary:';
    RAISE NOTICE 'Users: % old -> % new', old_user_count, new_user_count;
    RAISE NOTICE 'Channels: % old -> % new', old_channel_count, new_channel_count;
    RAISE NOTICE 'Videos: % old -> % new', old_video_count, new_video_count;
    
    IF old_user_count != new_user_count OR 
       old_channel_count != new_channel_count OR 
       old_video_count != new_video_count THEN
        RAISE EXCEPTION 'Migration counts do not match! Rolling back...';
    END IF;
END $$;

-- Step 7: Drop old tables (commented out for safety - run manually after verification)
-- DROP TABLE IF EXISTS ytempire.analytics CASCADE;
-- DROP TABLE IF EXISTS ytempire.videos CASCADE;
-- DROP TABLE IF EXISTS ytempire.channels CASCADE;
-- DROP TABLE IF EXISTS ytempire.users CASCADE;
-- DROP SCHEMA IF EXISTS ytempire CASCADE;

COMMIT;

-- Post-migration steps (run these after verifying the migration):
-- 1. Update application connection strings and queries
-- 2. Update any stored procedures or functions
-- 3. Run ANALYZE to update statistics
-- 4. Drop the old schema and tables
-- 5. Remove backward compatibility views if not needed