-- YTEmpire Performance Indexes
-- Additional performance-critical indexes and constraints

-- Full-text search indexes
CREATE INDEX idx_channels_search ON content.channels 
    USING GIN(to_tsvector('english', channel_name || ' ' || COALESCE(description, '')));

CREATE INDEX idx_videos_search ON content.videos 
    USING GIN(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Composite indexes for common queries
CREATE INDEX idx_videos_channel_views ON content.videos(channel_id, view_count DESC)
    WHERE privacy_status = 'public';

CREATE INDEX idx_videos_published_views ON content.videos(published_at DESC, view_count DESC)
    WHERE privacy_status = 'public';

-- Partial indexes for active records
CREATE INDEX idx_active_channels ON content.channels(created_at DESC)
    WHERE status = 'active';

CREATE INDEX idx_active_campaigns ON campaigns.campaigns(start_date, end_date)
    WHERE status = 'active';

-- BRIN indexes for time-series data (space-efficient for large tables)
CREATE INDEX idx_channel_analytics_date_brin ON analytics.channel_analytics 
    USING BRIN(date) WITH (pages_per_range = 128);

CREATE INDEX idx_video_analytics_date_brin ON analytics.video_analytics 
    USING BRIN(date) WITH (pages_per_range = 128);

-- Function-based indexes
CREATE INDEX idx_videos_duration_minutes ON content.videos((duration_seconds / 60))
    WHERE duration_seconds IS NOT NULL;

CREATE INDEX idx_channels_engagement_rate ON analytics.channel_analytics(
    channel_id,
    ((likes + comments + shares)::DECIMAL / NULLIF(views, 0))
) WHERE views > 0;

-- Constraints for data integrity
ALTER TABLE content.channels 
    ADD CONSTRAINT check_positive_counts 
    CHECK (subscriber_count >= 0 AND video_count >= 0 AND view_count >= 0);

ALTER TABLE content.videos 
    ADD CONSTRAINT check_positive_metrics 
    CHECK (view_count >= 0 AND like_count >= 0 AND comment_count >= 0 AND favorite_count >= 0);

ALTER TABLE analytics.channel_analytics
    ADD CONSTRAINT check_valid_rates
    CHECK (click_through_rate >= 0 AND click_through_rate <= 1);

ALTER TABLE analytics.video_analytics
    ADD CONSTRAINT check_retention_percentage
    CHECK (audience_retention_percentage >= 0 AND audience_retention_percentage <= 100);

-- Create materialized views for dashboard queries
CREATE MATERIALIZED VIEW analytics.channel_overview AS
SELECT 
    c.channel_id,
    c.channel_name,
    c.youtube_channel_id,
    c.subscriber_count,
    c.video_count,
    c.view_count,
    COALESCE(ca.total_views_30d, 0) as views_last_30_days,
    COALESCE(ca.total_revenue_30d, 0) as revenue_last_30_days,
    COALESCE(ca.avg_engagement_rate, 0) as engagement_rate_30d
FROM content.channels c
LEFT JOIN LATERAL (
    SELECT 
        SUM(views) as total_views_30d,
        SUM(estimated_revenue) as total_revenue_30d,
        AVG((likes + comments + shares)::DECIMAL / NULLIF(views, 0)) as avg_engagement_rate
    FROM analytics.channel_analytics
    WHERE channel_id = c.channel_id
        AND date >= CURRENT_DATE - INTERVAL '30 days'
) ca ON true
WHERE c.status = 'active';

-- Index for materialized view
CREATE UNIQUE INDEX idx_channel_overview_id ON analytics.channel_overview(channel_id);
CREATE INDEX idx_channel_overview_views ON analytics.channel_overview(views_last_30_days DESC);

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.channel_overview;
END;
$$ LANGUAGE plpgsql;

-- Table statistics update function
CREATE OR REPLACE FUNCTION update_table_statistics()
RETURNS VOID AS $$
BEGIN
    ANALYZE content.channels;
    ANALYZE content.videos;
    ANALYZE analytics.channel_analytics;
    ANALYZE analytics.video_analytics;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON MATERIALIZED VIEW analytics.channel_overview IS 'Pre-aggregated channel metrics for dashboard performance';

-- Grants
GRANT SELECT ON analytics.channel_overview TO ytempire_user;
GRANT EXECUTE ON FUNCTION refresh_analytics_views() TO ytempire_user;
GRANT EXECUTE ON FUNCTION update_table_statistics() TO ytempire_user;