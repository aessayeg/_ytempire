-- 06-campaigns-schema.sql: Marketing campaigns schema
-- YTEmpire MVP Campaign Tables
-- Purpose: Campaign tracking, ROI metrics, and performance analysis

\c ytempire_dev;

-- Campaign enums
CREATE TYPE campaigns.campaign_status AS ENUM ('draft', 'active', 'paused', 'completed', 'cancelled');
CREATE TYPE campaigns.campaign_type AS ENUM ('brand_awareness', 'product_launch', 'engagement', 'subscriber_growth', 'monetization');
CREATE TYPE campaigns.budget_type AS ENUM ('fixed', 'daily', 'monthly', 'performance_based');

-- Marketing campaigns table
CREATE TABLE campaigns.campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type campaigns.campaign_type NOT NULL,
    status campaigns.campaign_status DEFAULT 'draft',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget_amount DECIMAL(12,2),
    budget_type campaigns.budget_type DEFAULT 'fixed',
    target_audience JSONB DEFAULT '{}',
    objectives JSONB DEFAULT '[]',
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Campaign channels association
CREATE TABLE campaigns.campaign_channels (
    campaign_id UUID NOT NULL REFERENCES campaigns.campaigns(id) ON DELETE CASCADE,
    channel_id UUID NOT NULL REFERENCES content.channels(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    budget_allocation_percentage DECIMAL(5,2),
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (campaign_id, channel_id)
);

-- Campaign videos association
CREATE TABLE campaigns.campaign_videos (
    campaign_id UUID NOT NULL REFERENCES campaigns.campaigns(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES content.videos(id) ON DELETE CASCADE,
    is_sponsored BOOLEAN DEFAULT FALSE,
    performance_bonus DECIMAL(10,2),
    custom_tracking_code VARCHAR(100),
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (campaign_id, video_id)
);

-- Campaign performance metrics
CREATE TABLE campaigns.campaign_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns.campaigns(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    impressions BIGINT DEFAULT 0,
    views BIGINT DEFAULT 0,
    clicks BIGINT DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    engagement_rate DECIMAL(5,2),
    cost_per_view DECIMAL(10,4),
    cost_per_conversion DECIMAL(10,2),
    roi_percentage DECIMAL(10,2),
    spend_amount DECIMAL(10,2) DEFAULT 0,
    revenue_generated DECIMAL(10,2) DEFAULT 0,
    new_subscribers INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(campaign_id, metric_date)
);

-- Campaign goals and KPIs
CREATE TABLE campaigns.campaign_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns.campaigns(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    target_value DECIMAL(12,2) NOT NULL,
    current_value DECIMAL(12,2) DEFAULT 0,
    unit VARCHAR(50),
    deadline DATE,
    is_achieved BOOLEAN DEFAULT FALSE,
    achieved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Campaign budget tracking
CREATE TABLE campaigns.budget_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns.campaigns(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    vendor_name VARCHAR(255),
    invoice_number VARCHAR(100),
    transaction_date DATE NOT NULL,
    created_by UUID REFERENCES users.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- A/B testing for campaigns
CREATE TABLE campaigns.ab_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns.campaigns(id) ON DELETE CASCADE,
    test_name VARCHAR(255) NOT NULL,
    variant_a JSONB NOT NULL,
    variant_b JSONB NOT NULL,
    metric_to_optimize VARCHAR(100) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    winner_variant CHAR(1),
    confidence_level DECIMAL(5,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes
CREATE INDEX idx_campaigns_user ON campaigns.campaigns(user_id);
CREATE INDEX idx_campaigns_status ON campaigns.campaigns(status) WHERE status != 'completed';
CREATE INDEX idx_campaigns_dates ON campaigns.campaigns(start_date, end_date);
CREATE INDEX idx_campaign_channels_campaign ON campaigns.campaign_channels(campaign_id);
CREATE INDEX idx_campaign_videos_campaign ON campaigns.campaign_videos(campaign_id);
CREATE INDEX idx_campaign_videos_video ON campaigns.campaign_videos(video_id);
CREATE INDEX idx_campaign_metrics_campaign_date ON campaigns.campaign_metrics(campaign_id, metric_date DESC);
CREATE INDEX idx_campaign_goals_campaign ON campaigns.campaign_goals(campaign_id) WHERE is_achieved = FALSE;
CREATE INDEX idx_budget_transactions_campaign ON campaigns.budget_transactions(campaign_id, transaction_date DESC);
CREATE INDEX idx_ab_tests_campaign ON campaigns.ab_tests(campaign_id) WHERE is_active = TRUE;

-- Update triggers
CREATE TRIGGER update_campaigns_updated_at
    BEFORE UPDATE ON campaigns.campaigns
    FOR EACH ROW
    EXECUTE FUNCTION users.update_updated_at();

-- Function to calculate campaign ROI
CREATE OR REPLACE FUNCTION campaigns.calculate_campaign_roi(
    p_campaign_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_spend DECIMAL(10,2),
    total_revenue DECIMAL(10,2),
    roi_percentage DECIMAL(10,2),
    cost_per_conversion DECIMAL(10,2),
    conversion_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(cm.spend_amount), 0) as total_spend,
        COALESCE(SUM(cm.revenue_generated), 0) as total_revenue,
        CASE 
            WHEN SUM(cm.spend_amount) > 0 THEN
                ((SUM(cm.revenue_generated) - SUM(cm.spend_amount)) / SUM(cm.spend_amount) * 100)
            ELSE 0
        END as roi_percentage,
        CASE 
            WHEN SUM(cm.conversions) > 0 THEN
                SUM(cm.spend_amount) / SUM(cm.conversions)
            ELSE 0
        END as cost_per_conversion,
        COALESCE(SUM(cm.conversions), 0) as conversion_count
    FROM campaigns.campaign_metrics cm
    WHERE cm.campaign_id = p_campaign_id
        AND (p_start_date IS NULL OR cm.metric_date >= p_start_date)
        AND (p_end_date IS NULL OR cm.metric_date <= p_end_date);
END;
$$ LANGUAGE plpgsql;