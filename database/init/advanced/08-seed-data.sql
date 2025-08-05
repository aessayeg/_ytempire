-- 08-seed-data.sql: Development seed data
-- YTEmpire MVP Test Data
-- Purpose: Provide realistic test data for development

\c ytempire_dev;

-- Disable triggers temporarily for faster inserts
SET session_replication_role = 'replica';

-- Insert test users
INSERT INTO users.users (id, email, username, password_hash, full_name, role, status, email_verified) VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'admin@ytempire.test', 'admin', '$2b$10$YNV3YJwAhZRPh7T.kgRJhO6iBgL5E2vIXxrFhxe8pq.x4Z5yYVGLO', 'Admin User', 'admin', 'active', true),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'creator1@ytempire.test', 'techcreator', '$2b$10$YNV3YJwAhZRPh7T.kgRJhO6iBgL5E2vIXxrFhxe8pq.x4Z5yYVGLO', 'Tech Creator', 'creator', 'active', true),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'creator2@ytempire.test', 'gamingpro', '$2b$10$YNV3YJwAhZRPh7T.kgRJhO6iBgL5E2vIXxrFhxe8pq.x4Z5yYVGLO', 'Gaming Pro', 'creator', 'active', true),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', 'analyst@ytempire.test', 'dataanalyst', '$2b$10$YNV3YJwAhZRPh7T.kgRJhO6iBgL5E2vIXxrFhxe8pq.x4Z5yYVGLO', 'Data Analyst', 'analyst', 'active', true);

-- Insert test channels
INSERT INTO content.channels (id, user_id, youtube_channel_id, channel_title, channel_description, subscriber_count, view_count, video_count, is_verified) VALUES
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'UCtech123456', 'Tech Tutorials Hub', 'Learn programming and technology with easy tutorials', 125000, 15000000, 450, true),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'UCgame789012', 'Gaming Masters', 'Epic gaming content and walkthroughs', 500000, 75000000, 1200, true);

-- Insert test videos
INSERT INTO content.videos (id, channel_id, youtube_video_id, title, description, duration, view_count, like_count, comment_count, published_at, tags) VALUES
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', 'vid_python_001', 'Python Tutorial for Beginners - Complete Course', 'Learn Python programming from scratch', 7200, 250000, 15000, 1200, '2024-01-15 10:00:00+00', ARRAY['python', 'programming', 'tutorial', 'beginners']),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c12', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', 'vid_react_001', 'React JS Crash Course 2024', 'Master React JS in 2 hours', 7200, 180000, 12000, 800, '2024-02-01 14:00:00+00', ARRAY['react', 'javascript', 'web development', 'frontend']),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c13', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', 'vid_game_001', 'Call of Duty: Ultimate Guide', 'Pro tips and strategies for COD', 3600, 500000, 45000, 3500, '2024-01-20 18:00:00+00', ARRAY['gaming', 'call of duty', 'fps', 'guide']),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c14', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', 'vid_game_002', 'Minecraft: Building Epic Structures', 'Learn to build amazing structures in Minecraft', 5400, 750000, 62000, 4200, '2024-02-10 16:00:00+00', ARRAY['minecraft', 'gaming', 'building', 'tutorial']);

-- Insert analytics data for the last 30 days
DO $$
DECLARE
    v_date DATE;
    v_channel_id UUID;
    v_video_id UUID;
BEGIN
    -- Generate daily metrics for channels
    FOR v_channel_id IN SELECT id FROM content.channels LOOP
        FOR i IN 0..29 LOOP
            v_date := CURRENT_DATE - i;
            
            INSERT INTO analytics.channel_metrics (
                channel_id, metric_date, views, watch_time_minutes, 
                subscribers_gained, subscribers_lost, estimated_revenue,
                impressions, click_through_rate, likes, comments
            ) VALUES (
                v_channel_id, v_date,
                (random() * 50000 + 10000)::BIGINT,  -- views
                (random() * 100000 + 50000)::BIGINT,  -- watch time
                (random() * 500 + 100)::INTEGER,      -- subs gained
                (random() * 50 + 10)::INTEGER,        -- subs lost
                (random() * 500 + 100)::DECIMAL,      -- revenue
                (random() * 100000 + 50000)::BIGINT,  -- impressions
                (random() * 10 + 2)::DECIMAL,         -- CTR
                (random() * 5000 + 1000)::INTEGER,    -- likes
                (random() * 500 + 100)::INTEGER       -- comments
            );
        END LOOP;
    END LOOP;
    
    -- Generate daily metrics for videos
    FOR v_video_id IN SELECT id FROM content.videos LOOP
        FOR i IN 0..29 LOOP
            v_date := CURRENT_DATE - i;
            
            INSERT INTO analytics.video_metrics (
                video_id, metric_date, views, watch_time_minutes,
                average_view_percentage, impressions, click_through_rate,
                likes, comments, estimated_revenue
            ) VALUES (
                v_video_id, v_date,
                (random() * 10000 + 1000)::BIGINT,    -- views
                (random() * 20000 + 5000)::BIGINT,    -- watch time
                (random() * 50 + 30)::DECIMAL,        -- avg view %
                (random() * 50000 + 10000)::BIGINT,   -- impressions
                (random() * 15 + 5)::DECIMAL,         -- CTR
                (random() * 1000 + 100)::INTEGER,     -- likes
                (random() * 100 + 10)::INTEGER,       -- comments
                (random() * 50 + 10)::DECIMAL         -- revenue
            );
        END LOOP;
    END LOOP;
END $$;

-- Insert test campaigns
INSERT INTO campaigns.campaigns (id, user_id, name, description, type, status, start_date, end_date, budget_amount, budget_type) VALUES
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'Spring Tech Series', 'Promote new programming tutorial series', 'engagement', 'active', '2024-03-01', '2024-05-31', 5000.00, 'monthly'),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d12', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'Gaming Tournament Coverage', 'Live coverage of major gaming tournaments', 'brand_awareness', 'active', '2024-02-15', '2024-04-15', 10000.00, 'fixed');

-- Link campaigns to channels
INSERT INTO campaigns.campaign_channels (campaign_id, channel_id, is_primary, budget_allocation_percentage) VALUES
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', true, 100.00),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d12', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', true, 100.00);

-- Insert campaign metrics
INSERT INTO campaigns.campaign_metrics (campaign_id, metric_date, impressions, views, clicks, conversions, spend_amount, revenue_generated) VALUES
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d11', CURRENT_DATE - 1, 50000, 25000, 2500, 150, 166.67, 450.00),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d11', CURRENT_DATE - 2, 48000, 24000, 2400, 145, 166.67, 435.00),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d12', CURRENT_DATE - 1, 100000, 50000, 5000, 300, 333.33, 900.00),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d12', CURRENT_DATE - 2, 95000, 47500, 4750, 285, 333.33, 855.00);

-- Insert audience demographics
INSERT INTO analytics.audience_demographics (channel_id, metric_date, age_group, gender, country, device_type, viewer_percentage, watch_time_percentage) VALUES
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', CURRENT_DATE - 1, '18-24', 'male', 'US', 'desktop', 35.5, 38.2),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', CURRENT_DATE - 1, '25-34', 'male', 'US', 'mobile', 28.3, 26.5),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', CURRENT_DATE - 1, '18-24', 'female', 'US', 'desktop', 15.2, 14.8),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', CURRENT_DATE - 1, '13-17', 'male', 'US', 'mobile', 42.1, 45.3),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', CURRENT_DATE - 1, '18-24', 'male', 'US', 'desktop', 31.5, 29.7);

-- Re-enable triggers
SET session_replication_role = 'origin';

-- Refresh materialized view
REFRESH MATERIALIZED VIEW analytics.channel_overview;

-- Output summary
DO $$
DECLARE
    v_user_count INTEGER;
    v_channel_count INTEGER;
    v_video_count INTEGER;
    v_campaign_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_user_count FROM users.users;
    SELECT COUNT(*) INTO v_channel_count FROM content.channels;
    SELECT COUNT(*) INTO v_video_count FROM content.videos;
    SELECT COUNT(*) INTO v_campaign_count FROM campaigns.campaigns;
    
    RAISE NOTICE 'Seed data loaded successfully:';
    RAISE NOTICE '  - Users: %', v_user_count;
    RAISE NOTICE '  - Channels: %', v_channel_count;
    RAISE NOTICE '  - Videos: %', v_video_count;
    RAISE NOTICE '  - Campaigns: %', v_campaign_count;
    RAISE NOTICE '  - Analytics data: 30 days of metrics';
    RAISE NOTICE '';
    RAISE NOTICE 'Test credentials (password for all: password123):';
    RAISE NOTICE '  - Admin: admin@ytempire.test';
    RAISE NOTICE '  - Creator 1: creator1@ytempire.test';
    RAISE NOTICE '  - Creator 2: creator2@ytempire.test';
    RAISE NOTICE '  - Analyst: analyst@ytempire.test';
END $$;