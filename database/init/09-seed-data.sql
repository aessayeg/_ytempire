-- YTEmpire Development Seed Data
-- Sample data for development and testing

-- Insert test accounts
INSERT INTO users.accounts (account_id, email, username, password_hash, account_type, account_status, subscription_tier, email_verified)
VALUES 
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid, 'admin@ytempire.com', 'admin', '$2b$10$K6L7hPMqE.5nDrzJvTbgcuVWUwD3NjQw4I6H1SSofbVGxH8wMJZ3.', 'admin', 'active', 'enterprise', true),
    ('b1ffcd11-1234-5678-9abc-def012345678'::uuid, 'creator@ytempire.com', 'testcreator', '$2b$10$K6L7hPMqE.5nDrzJvTbgcuVWUwD3NjQw4I6H1SSofbVGxH8wMJZ3.', 'creator', 'active', 'pro', true),
    ('c2eead22-2345-6789-abcd-ef0123456789'::uuid, 'manager@ytempire.com', 'testmanager', '$2b$10$K6L7hPMqE.5nDrzJvTbgcuVWUwD3NjQw4I6H1SSofbVGxH8wMJZ3.', 'manager', 'active', 'free', true)
ON CONFLICT (email) DO NOTHING;

-- Insert test profiles
INSERT INTO users.profiles (account_id, first_name, last_name, display_name, bio, timezone, language)
VALUES 
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid, 'Admin', 'User', 'YTEmpire Admin', 'Platform administrator', 'America/New_York', 'en'),
    ('b1ffcd11-1234-5678-9abc-def012345678'::uuid, 'Test', 'Creator', 'Creative Studio', 'Content creator and YouTube enthusiast', 'America/Los_Angeles', 'en'),
    ('c2eead22-2345-6789-abcd-ef0123456789'::uuid, 'Test', 'Manager', 'Channel Manager', 'Managing multiple YouTube channels', 'Europe/London', 'en')
ON CONFLICT DO NOTHING;

-- Insert test channels
INSERT INTO content.channels (channel_id, account_id, youtube_channel_id, channel_name, channel_handle, description, subscriber_count, video_count, view_count, country, language, category, status)
VALUES 
    ('d3ffbd33-3456-789a-bcde-f01234567890'::uuid, 'b1ffcd11-1234-5678-9abc-def012345678'::uuid, 'UCtest123456789', 'Tech Tutorials Channel', '@techtutorials', 'Programming and technology tutorials', 125000, 250, 15000000, 'US', 'en', 'Technology', 'active'),
    ('e4ffce44-4567-89ab-cdef-012345678901'::uuid, 'b1ffcd11-1234-5678-9abc-def012345678'::uuid, 'UCtest234567890', 'Gaming Adventures', '@gamingadv', 'Gaming content and walkthroughs', 50000, 180, 8000000, 'US', 'en', 'Gaming', 'active'),
    ('f5ffdf55-5678-9abc-def0-123456789012'::uuid, 'c2eead22-2345-6789-abcd-ef0123456789'::uuid, 'UCtest345678901', 'Cooking Masterclass', '@cookingmaster', 'Recipes and cooking techniques', 75000, 120, 10000000, 'UK', 'en', 'Food', 'active')
ON CONFLICT (youtube_channel_id) DO NOTHING;

-- Insert test videos
INSERT INTO content.videos (video_id, channel_id, youtube_video_id, title, description, duration_seconds, published_at, privacy_status, view_count, like_count, comment_count, tags)
VALUES 
    ('a6ffe066-6789-abcd-ef01-234567890123'::uuid, 'd3ffbd33-3456-789a-bcde-f01234567890'::uuid, 'vid_tech_001', 'Python Tutorial for Beginners', 'Complete Python programming tutorial', 1800, NOW() - INTERVAL '7 days', 'public', 50000, 2500, 150, ARRAY['python', 'programming', 'tutorial']),
    ('b7fff177-789a-bcde-f012-345678901234'::uuid, 'd3ffbd33-3456-789a-bcde-f01234567890'::uuid, 'vid_tech_002', 'React.js Crash Course', 'Learn React.js in 2 hours', 7200, NOW() - INTERVAL '5 days', 'public', 35000, 1800, 120, ARRAY['react', 'javascript', 'web development']),
    ('c8ff0288-89ab-cdef-0123-456789012345'::uuid, 'e4ffce44-4567-89ab-cdef-012345678901'::uuid, 'vid_game_001', 'Epic Gaming Moments Compilation', 'Best gaming moments of the month', 900, NOW() - INTERVAL '3 days', 'public', 75000, 5000, 300, ARRAY['gaming', 'compilation', 'highlights'])
ON CONFLICT (youtube_video_id) DO NOTHING;

-- Insert test playlists
INSERT INTO content.playlists (playlist_id, channel_id, youtube_playlist_id, title, description, privacy_status, video_count)
VALUES 
    ('d9ff1399-9abc-def0-1234-567890123456'::uuid, 'd3ffbd33-3456-789a-bcde-f01234567890'::uuid, 'PLtest123', 'Complete Programming Course', 'All programming tutorials in order', 'public', 25),
    ('eaff24aa-abcd-ef01-2345-678901234567'::uuid, 'e4ffce44-4567-89ab-cdef-012345678901'::uuid, 'PLtest234', 'Best Gaming Moments 2024', 'Collection of best gaming content', 'public', 15)
ON CONFLICT (youtube_playlist_id) DO NOTHING;

-- Insert test analytics data (last 30 days)
INSERT INTO analytics.channel_analytics (channel_id, date, views, watch_time_minutes, subscribers_gained, estimated_revenue, likes, comments, shares)
SELECT 
    'd3ffbd33-3456-789a-bcde-f01234567890'::uuid,
    CURRENT_DATE - (generate_series(0, 29) || ' days')::INTERVAL,
    FLOOR(RANDOM() * 10000 + 5000),  -- 5k-15k views
    FLOOR(RANDOM() * 50000 + 25000), -- 25k-75k minutes
    FLOOR(RANDOM() * 100 + 50),      -- 50-150 subscribers
    ROUND((RANDOM() * 100 + 50)::DECIMAL, 2), -- $50-$150
    FLOOR(RANDOM() * 500 + 250),     -- 250-750 likes
    FLOOR(RANDOM() * 50 + 25),       -- 25-75 comments
    FLOOR(RANDOM() * 100 + 50)       -- 50-150 shares
ON CONFLICT (channel_id, date) DO NOTHING;

-- Insert test video analytics
INSERT INTO analytics.video_analytics (video_id, date, views, watch_time_minutes, estimated_revenue, likes, comments, shares, audience_retention_percentage)
SELECT 
    'a6ffe066-6789-abcd-ef01-234567890123'::uuid,
    CURRENT_DATE - (generate_series(0, 6) || ' days')::INTERVAL,
    FLOOR(RANDOM() * 8000 + 2000),   -- 2k-10k views
    FLOOR(RANDOM() * 20000 + 10000), -- 10k-30k minutes
    ROUND((RANDOM() * 50 + 10)::DECIMAL, 2), -- $10-$60
    FLOOR(RANDOM() * 400 + 100),     -- 100-500 likes
    FLOOR(RANDOM() * 30 + 10),       -- 10-40 comments
    FLOOR(RANDOM() * 50 + 10),       -- 10-60 shares
    ROUND((RANDOM() * 30 + 50)::DECIMAL, 2) -- 50-80% retention
ON CONFLICT (video_id, date) DO NOTHING;

-- Insert test campaigns
INSERT INTO campaigns.campaigns (campaign_id, account_id, campaign_name, campaign_type, description, start_date, end_date, budget, status, target_metrics)
VALUES 
    ('fbff35bb-bcde-f012-3456-789012345678'::uuid, 'b1ffcd11-1234-5678-9abc-def012345678'::uuid, 
     'Summer Growth Campaign', 'growth', 'Increase subscriber base during summer', 
     CURRENT_DATE - INTERVAL '15 days', CURRENT_DATE + INTERVAL '15 days', 5000.00, 'active',
     '{"target_subscribers": 10000, "target_views": 500000}'::jsonb),
    ('fcff46cc-cdef-0123-4567-890123456789'::uuid, 'b1ffcd11-1234-5678-9abc-def012345678'::uuid, 
     'Product Launch Promotion', 'promotion', 'Promote new course launch', 
     CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '25 days', 3000.00, 'active',
     '{"target_conversions": 500, "target_engagement_rate": 0.05}'::jsonb)
ON CONFLICT DO NOTHING;

-- Link videos to campaigns
INSERT INTO campaigns.campaign_videos (campaign_id, video_id)
VALUES 
    ('fbff35bb-bcde-f012-3456-789012345678'::uuid, 'a6ffe066-6789-abcd-ef01-234567890123'::uuid),
    ('fbff35bb-bcde-f012-3456-789012345678'::uuid, 'b7fff177-789a-bcde-f012-345678901234'::uuid)
ON CONFLICT DO NOTHING;

-- Insert test API keys
INSERT INTO system.api_keys (account_id, key_name, api_key_hash, service_type, quota_limit, is_active)
VALUES 
    ('b1ffcd11-1234-5678-9abc-def012345678'::uuid, 'Primary YouTube Data API', '$2b$10$' || encode(gen_random_bytes(32), 'hex'), 'youtube_data', 10000, true),
    ('b1ffcd11-1234-5678-9abc-def012345678'::uuid, 'Analytics API Key', '$2b$10$' || encode(gen_random_bytes(32), 'hex'), 'youtube_analytics', 10000, true)
ON CONFLICT DO NOTHING;

-- Insert test sync logs
INSERT INTO system.sync_logs (entity_type, entity_id, sync_type, sync_status, records_processed, records_updated, records_created, completed_at, execution_time_ms)
VALUES 
    ('channel', 'd3ffbd33-3456-789a-bcde-f01234567890'::uuid, 'full', 'completed', 250, 245, 5, NOW() - INTERVAL '1 hour', 15234),
    ('video', 'a6ffe066-6789-abcd-ef01-234567890123'::uuid, 'incremental', 'completed', 1, 1, 0, NOW() - INTERVAL '30 minutes', 523)
ON CONFLICT DO NOTHING;

-- Refresh materialized views
REFRESH MATERIALIZED VIEW analytics.channel_overview;

-- Update statistics
ANALYZE;