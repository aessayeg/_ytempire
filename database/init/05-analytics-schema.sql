-- YTEmpire Analytics Schema
-- Performance metrics and analytics data tables with partitioning

-- Create partition functions
CREATE OR REPLACE FUNCTION create_monthly_partition(
    table_name TEXT,
    start_date DATE
) RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    end_date DATE;
BEGIN
    partition_name := table_name || '_' || TO_CHAR(start_date, 'YYYY_MM');
    end_date := start_date + INTERVAL '1 month';
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS analytics.%I PARTITION OF analytics.%I 
                    FOR VALUES FROM (%L) TO (%L)',
                    partition_name, table_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;

-- analytics.channel_analytics table (partitioned)
CREATE TABLE analytics.channel_analytics (
    analytics_id       UUID DEFAULT gen_random_uuid(),
    channel_id         UUID NOT NULL,
    date               DATE NOT NULL,
    views              BIGINT DEFAULT 0,
    watch_time_minutes BIGINT DEFAULT 0,
    subscribers_gained INTEGER DEFAULT 0,
    subscribers_lost   INTEGER DEFAULT 0,
    estimated_revenue  DECIMAL(10,2) DEFAULT 0.00,
    impressions        BIGINT DEFAULT 0,
    click_through_rate DECIMAL(5,4) DEFAULT 0.0000,
    average_view_duration_seconds INTEGER DEFAULT 0,
    comments           INTEGER DEFAULT 0,
    likes              INTEGER DEFAULT 0,
    dislikes           INTEGER DEFAULT 0,
    shares             INTEGER DEFAULT 0,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (analytics_id, date),
    UNIQUE(channel_id, date),
    FOREIGN KEY (channel_id) REFERENCES content.channels(channel_id) ON DELETE CASCADE
) PARTITION BY RANGE (date);

-- analytics.video_analytics table (partitioned)
CREATE TABLE analytics.video_analytics (
    analytics_id       UUID DEFAULT gen_random_uuid(),
    video_id           UUID NOT NULL,
    date               DATE NOT NULL,
    views              BIGINT DEFAULT 0,
    watch_time_minutes BIGINT DEFAULT 0,
    estimated_revenue  DECIMAL(10,2) DEFAULT 0.00,
    impressions        BIGINT DEFAULT 0,
    click_through_rate DECIMAL(5,4) DEFAULT 0.0000,
    average_view_duration_seconds INTEGER DEFAULT 0,
    audience_retention_percentage DECIMAL(5,2) DEFAULT 0.00,
    comments           INTEGER DEFAULT 0,
    likes              INTEGER DEFAULT 0,
    dislikes           INTEGER DEFAULT 0,
    shares             INTEGER DEFAULT 0,
    subscribers_gained INTEGER DEFAULT 0,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (analytics_id, date),
    UNIQUE(video_id, date),
    FOREIGN KEY (video_id) REFERENCES content.videos(video_id) ON DELETE CASCADE
) PARTITION BY RANGE (date);

-- analytics.audience_demographics table (partitioned)
CREATE TABLE analytics.audience_demographics (
    demographic_id     UUID DEFAULT gen_random_uuid(),
    channel_id         UUID NOT NULL,
    date               DATE NOT NULL,
    age_group          VARCHAR(20) NOT NULL, -- '13-17', '18-24', '25-34', etc.
    gender             VARCHAR(20) NOT NULL, -- 'male', 'female', 'other'
    country_code       VARCHAR(10) NOT NULL,
    percentage         DECIMAL(5,2) NOT NULL,
    view_percentage    DECIMAL(5,2) DEFAULT 0.00,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (demographic_id, date),
    UNIQUE(channel_id, date, age_group, gender, country_code),
    FOREIGN KEY (channel_id) REFERENCES content.channels(channel_id) ON DELETE CASCADE
) PARTITION BY RANGE (date);

-- analytics.traffic_sources table (partitioned)
CREATE TABLE analytics.traffic_sources (
    traffic_id         UUID DEFAULT gen_random_uuid(),
    channel_id         UUID NOT NULL,
    video_id           UUID,
    date               DATE NOT NULL,
    source_type        VARCHAR(100) NOT NULL, -- 'search', 'suggested', 'external', etc.
    source_detail      VARCHAR(200),
    views              BIGINT DEFAULT 0,
    watch_time_minutes BIGINT DEFAULT 0,
    percentage         DECIMAL(5,2) DEFAULT 0.00,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (traffic_id, date),
    FOREIGN KEY (channel_id) REFERENCES content.channels(channel_id) ON DELETE CASCADE,
    FOREIGN KEY (video_id) REFERENCES content.videos(video_id) ON DELETE CASCADE
) PARTITION BY RANGE (date);

-- Create initial partitions for the current and next 3 months
DO $$
DECLARE
    curr_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    i INTEGER;
BEGIN
    FOR i IN 0..3 LOOP
        PERFORM create_monthly_partition('channel_analytics', curr_date + (i || ' months')::INTERVAL);
        PERFORM create_monthly_partition('video_analytics', curr_date + (i || ' months')::INTERVAL);
        PERFORM create_monthly_partition('audience_demographics', curr_date + (i || ' months')::INTERVAL);
        PERFORM create_monthly_partition('traffic_sources', curr_date + (i || ' months')::INTERVAL);
    END LOOP;
END $$;

-- Create indexes on partitioned tables
CREATE INDEX idx_channel_analytics_channel_date ON analytics.channel_analytics(channel_id, date DESC);
CREATE INDEX idx_channel_analytics_date ON analytics.channel_analytics(date DESC);

CREATE INDEX idx_video_analytics_video_date ON analytics.video_analytics(video_id, date DESC);
CREATE INDEX idx_video_analytics_date ON analytics.video_analytics(date DESC);
CREATE INDEX idx_video_analytics_channel ON analytics.video_analytics(video_id, date) 
    INCLUDE (views, watch_time_minutes, estimated_revenue);

CREATE INDEX idx_demographics_channel_date ON analytics.audience_demographics(channel_id, date DESC);
CREATE INDEX idx_demographics_country ON analytics.audience_demographics(country_code, date DESC);

CREATE INDEX idx_traffic_channel_date ON analytics.traffic_sources(channel_id, date DESC);
CREATE INDEX idx_traffic_video_date ON analytics.traffic_sources(video_id, date DESC) WHERE video_id IS NOT NULL;
CREATE INDEX idx_traffic_source_type ON analytics.traffic_sources(source_type, date DESC);

-- Create function to automatically create new partitions
CREATE OR REPLACE FUNCTION auto_create_monthly_partitions()
RETURNS VOID AS $$
DECLARE
    next_month DATE;
    tables TEXT[] := ARRAY['channel_analytics', 'video_analytics', 'audience_demographics', 'traffic_sources'];
    tbl TEXT;
BEGIN
    next_month := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '3 months');
    
    FOREACH tbl IN ARRAY tables LOOP
        PERFORM create_monthly_partition(tbl, next_month);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to create partitions (requires pg_cron extension or external scheduler)
-- This is a placeholder - actual implementation depends on your scheduling solution

-- Comments
COMMENT ON TABLE analytics.channel_analytics IS 'Daily channel performance metrics';
COMMENT ON TABLE analytics.video_analytics IS 'Daily video performance metrics';
COMMENT ON TABLE analytics.audience_demographics IS 'Audience demographic breakdown';
COMMENT ON TABLE analytics.traffic_sources IS 'Traffic source analysis';

-- Grants
GRANT ALL ON SCHEMA analytics TO ytempire_user;
GRANT ALL ON ALL TABLES IN SCHEMA analytics TO ytempire_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA analytics TO ytempire_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA analytics TO ytempire_user;