-- 05-analytics-schema.sql: Analytics schema with time-series optimization
-- YTEmpire MVP Analytics Tables
-- Purpose: YouTube performance metrics and time-series data

\c ytempire_dev;

-- Analytics time granularity
CREATE TYPE analytics.time_granularity AS ENUM ('minute', 'hour', 'day', 'week', 'month');
CREATE TYPE analytics.metric_type AS ENUM ('views', 'watch_time', 'engagement', 'revenue', 'subscribers');

-- Channel analytics (partitioned by month)
CREATE TABLE analytics.channel_metrics (
    id BIGSERIAL,
    channel_id UUID NOT NULL REFERENCES content.channels(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    metric_hour INTEGER DEFAULT 0 CHECK (metric_hour >= 0 AND metric_hour <= 23),
    views BIGINT DEFAULT 0,
    watch_time_minutes BIGINT DEFAULT 0,
    subscribers_gained INTEGER DEFAULT 0,
    subscribers_lost INTEGER DEFAULT 0,
    estimated_revenue DECIMAL(10,2) DEFAULT 0,
    impressions BIGINT DEFAULT 0,
    click_through_rate DECIMAL(5,2) DEFAULT 0,
    average_view_duration INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    dislikes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (channel_id, metric_date, metric_hour)
) PARTITION BY RANGE (metric_date);

-- Create partitions for the next 12 months
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    end_date DATE;
    partition_name TEXT;
BEGIN
    FOR i IN 0..11 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'channel_metrics_' || TO_CHAR(start_date, 'YYYY_MM');
        
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS analytics.%I PARTITION OF analytics.channel_metrics
            FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
        
        start_date := end_date;
    END LOOP;
END $$;

-- Video analytics (partitioned by month)
CREATE TABLE analytics.video_metrics (
    id BIGSERIAL,
    video_id UUID NOT NULL REFERENCES content.videos(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    metric_hour INTEGER DEFAULT 0 CHECK (metric_hour >= 0 AND metric_hour <= 23),
    views BIGINT DEFAULT 0,
    watch_time_minutes BIGINT DEFAULT 0,
    average_view_percentage DECIMAL(5,2) DEFAULT 0,
    impressions BIGINT DEFAULT 0,
    click_through_rate DECIMAL(5,2) DEFAULT 0,
    unique_viewers BIGINT DEFAULT 0,
    shares INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    dislikes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    subscribers_from_video INTEGER DEFAULT 0,
    estimated_revenue DECIMAL(10,2) DEFAULT 0,
    end_screen_clicks INTEGER DEFAULT 0,
    card_clicks INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (video_id, metric_date, metric_hour)
) PARTITION BY RANGE (metric_date);

-- Create video metrics partitions
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    end_date DATE;
    partition_name TEXT;
BEGIN
    FOR i IN 0..11 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'video_metrics_' || TO_CHAR(start_date, 'YYYY_MM');
        
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS analytics.%I PARTITION OF analytics.video_metrics
            FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
        
        start_date := end_date;
    END LOOP;
END $$;

-- Real-time analytics (for live data)
CREATE TABLE analytics.realtime_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID REFERENCES content.channels(id) ON DELETE CASCADE,
    video_id UUID REFERENCES content.videos(id) ON DELETE CASCADE,
    metric_type analytics.metric_type NOT NULL,
    metric_value BIGINT NOT NULL,
    metadata JSONB DEFAULT '{}',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT either_channel_or_video CHECK (
        (channel_id IS NOT NULL AND video_id IS NULL) OR
        (channel_id IS NULL AND video_id IS NOT NULL)
    )
);

-- Audience demographics
CREATE TABLE analytics.audience_demographics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES content.channels(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    age_group VARCHAR(20),
    gender VARCHAR(20),
    country VARCHAR(2),
    device_type VARCHAR(50),
    viewer_percentage DECIMAL(5,2),
    watch_time_percentage DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(channel_id, metric_date, age_group, gender, country, device_type)
);

-- Traffic sources
CREATE TABLE analytics.traffic_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID REFERENCES content.channels(id) ON DELETE CASCADE,
    video_id UUID REFERENCES content.videos(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    source_type VARCHAR(100) NOT NULL,
    source_detail VARCHAR(255),
    views BIGINT DEFAULT 0,
    watch_time_minutes BIGINT DEFAULT 0,
    impressions BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT either_channel_or_video_traffic CHECK (
        (channel_id IS NOT NULL AND video_id IS NULL) OR
        (channel_id IS NULL AND video_id IS NOT NULL)
    )
);

-- Search terms analytics
CREATE TABLE analytics.search_terms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES content.channels(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    search_term VARCHAR(500) NOT NULL,
    impressions BIGINT DEFAULT 0,
    views BIGINT DEFAULT 0,
    average_position DECIMAL(5,2),
    click_through_rate DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes
CREATE INDEX idx_channel_metrics_channel_date ON analytics.channel_metrics(channel_id, metric_date DESC);
CREATE INDEX idx_video_metrics_video_date ON analytics.video_metrics(video_id, metric_date DESC);
CREATE INDEX idx_realtime_metrics_timestamp ON analytics.realtime_metrics(recorded_at DESC);
CREATE INDEX idx_realtime_metrics_channel ON analytics.realtime_metrics(channel_id) WHERE channel_id IS NOT NULL;
CREATE INDEX idx_realtime_metrics_video ON analytics.realtime_metrics(video_id) WHERE video_id IS NOT NULL;
CREATE INDEX idx_audience_demographics_channel ON analytics.audience_demographics(channel_id, metric_date DESC);
CREATE INDEX idx_traffic_sources_date ON analytics.traffic_sources(metric_date DESC);
CREATE INDEX idx_search_terms_channel_date ON analytics.search_terms(channel_id, metric_date DESC);

-- Materialized view for dashboard performance
CREATE MATERIALIZED VIEW analytics.channel_overview AS
SELECT 
    c.id as channel_id,
    c.channel_title,
    c.subscriber_count,
    c.video_count,
    COALESCE(SUM(cm.views), 0) as total_views_30d,
    COALESCE(SUM(cm.watch_time_minutes), 0) as total_watch_time_30d,
    COALESCE(AVG(cm.average_view_duration), 0) as avg_view_duration_30d,
    COALESCE(SUM(cm.estimated_revenue), 0) as total_revenue_30d
FROM content.channels c
LEFT JOIN analytics.channel_metrics cm ON c.id = cm.channel_id 
    AND cm.metric_date >= CURRENT_DATE - INTERVAL '30 days'
WHERE c.is_active = TRUE
GROUP BY c.id, c.channel_title, c.subscriber_count, c.video_count;

CREATE UNIQUE INDEX idx_channel_overview_channel ON analytics.channel_overview(channel_id);

-- Function to refresh materialized view
CREATE OR REPLACE FUNCTION analytics.refresh_channel_overview()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.channel_overview;
END;
$$ LANGUAGE plpgsql;