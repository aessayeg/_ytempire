-- YTEmpire Campaigns Schema
-- Marketing campaign management tables

-- campaigns.campaigns table
CREATE TABLE campaigns.campaigns (
    campaign_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id         UUID NOT NULL REFERENCES users.accounts(account_id),
    campaign_name      VARCHAR(200) NOT NULL,
    campaign_type      VARCHAR(50) NOT NULL CHECK (campaign_type IN ('promotion', 'monetization', 'growth')),
    description        TEXT,
    start_date         DATE NOT NULL,
    end_date           DATE,
    budget             DECIMAL(10,2),
    currency           VARCHAR(10) DEFAULT 'USD',
    status             VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed')),
    target_metrics     JSONB, -- Flexible target metrics storage
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- campaigns.campaign_videos table
CREATE TABLE campaigns.campaign_videos (
    campaign_video_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id        UUID NOT NULL REFERENCES campaigns.campaigns(campaign_id) ON DELETE CASCADE,
    video_id           UUID NOT NULL REFERENCES content.videos(video_id) ON DELETE CASCADE,
    added_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(campaign_id, video_id)
);

-- campaigns.campaign_performance table
CREATE TABLE campaigns.campaign_performance (
    performance_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id        UUID NOT NULL REFERENCES campaigns.campaigns(campaign_id) ON DELETE CASCADE,
    date               DATE NOT NULL,
    total_views        BIGINT DEFAULT 0,
    total_watch_time   BIGINT DEFAULT 0,
    total_revenue      DECIMAL(10,2) DEFAULT 0.00,
    cost_per_view      DECIMAL(8,4) DEFAULT 0.0000,
    return_on_investment DECIMAL(8,4) DEFAULT 0.0000,
    subscriber_growth  INTEGER DEFAULT 0,
    engagement_rate    DECIMAL(5,4) DEFAULT 0.0000,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(campaign_id, date)
);

-- Create indexes
CREATE INDEX idx_campaigns_account ON campaigns.campaigns(account_id);
CREATE INDEX idx_campaigns_status ON campaigns.campaigns(status) WHERE status IN ('active', 'paused');
CREATE INDEX idx_campaigns_dates ON campaigns.campaigns(start_date, end_date);
CREATE INDEX idx_campaigns_type ON campaigns.campaigns(campaign_type);

CREATE INDEX idx_campaign_videos_campaign ON campaigns.campaign_videos(campaign_id);
CREATE INDEX idx_campaign_videos_video ON campaigns.campaign_videos(video_id);

CREATE INDEX idx_campaign_performance_campaign_date ON campaigns.campaign_performance(campaign_id, date DESC);
CREATE INDEX idx_campaign_performance_date ON campaigns.campaign_performance(date DESC);

-- Create triggers
CREATE TRIGGER update_campaigns_timestamp 
    BEFORE UPDATE ON campaigns.campaigns 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Comments
COMMENT ON TABLE campaigns.campaigns IS 'Marketing campaign management';
COMMENT ON TABLE campaigns.campaign_videos IS 'Videos associated with campaigns';
COMMENT ON TABLE campaigns.campaign_performance IS 'Campaign performance tracking';
COMMENT ON COLUMN campaigns.campaigns.target_metrics IS 'JSONB field for flexible metric targets like {"views": 100000, "engagement_rate": 0.05}';

-- Grants
GRANT ALL ON SCHEMA campaigns TO ytempire_user;
GRANT ALL ON ALL TABLES IN SCHEMA campaigns TO ytempire_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA campaigns TO ytempire_user;