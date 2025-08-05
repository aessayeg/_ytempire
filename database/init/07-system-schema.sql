-- YTEmpire System Schema
-- System configuration and operational tables

-- system.api_keys table
CREATE TABLE system.api_keys (
    api_key_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id         UUID NOT NULL REFERENCES users.accounts(account_id),
    key_name           VARCHAR(100) NOT NULL,
    api_key_hash       VARCHAR(255) NOT NULL,
    service_type       VARCHAR(50) NOT NULL CHECK (service_type IN ('youtube_data', 'youtube_analytics')),
    quota_limit        INTEGER DEFAULT 10000,
    quota_used         INTEGER DEFAULT 0,
    quota_reset_date   DATE,
    is_active          BOOLEAN DEFAULT TRUE,
    expires_at         TIMESTAMP WITH TIME ZONE,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- system.sync_logs table
CREATE TABLE system.sync_logs (
    sync_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type        VARCHAR(50) NOT NULL, -- 'channel', 'video', 'analytics'
    entity_id          UUID NOT NULL,
    sync_type          VARCHAR(50) NOT NULL CHECK (sync_type IN ('full', 'incremental')),
    sync_status        VARCHAR(50) NOT NULL CHECK (sync_status IN ('pending', 'running', 'completed', 'failed')),
    records_processed  INTEGER DEFAULT 0,
    records_updated    INTEGER DEFAULT 0,
    records_created    INTEGER DEFAULT 0,
    error_message      TEXT,
    started_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at       TIMESTAMP WITH TIME ZONE,
    execution_time_ms  INTEGER
);

-- Create indexes
CREATE INDEX idx_api_keys_account ON system.api_keys(account_id);
CREATE INDEX idx_api_keys_service_active ON system.api_keys(service_type, is_active);
CREATE INDEX idx_api_keys_expires ON system.api_keys(expires_at) WHERE is_active = true;

CREATE INDEX idx_sync_logs_entity ON system.sync_logs(entity_type, entity_id);
CREATE INDEX idx_sync_logs_status ON system.sync_logs(sync_status) WHERE sync_status IN ('pending', 'running');
CREATE INDEX idx_sync_logs_started ON system.sync_logs(started_at DESC);

-- Create triggers
CREATE TRIGGER update_api_keys_timestamp 
    BEFORE UPDATE ON system.api_keys 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to calculate sync execution time
CREATE OR REPLACE FUNCTION calculate_sync_execution_time()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.sync_status = 'completed' OR NEW.sync_status = 'failed' THEN
        NEW.completed_at = NOW();
        NEW.execution_time_ms = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at)) * 1000;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_sync_execution_time 
    BEFORE UPDATE ON system.sync_logs 
    FOR EACH ROW 
    WHEN (OLD.sync_status IN ('pending', 'running') AND NEW.sync_status IN ('completed', 'failed'))
    EXECUTE FUNCTION calculate_sync_execution_time();

-- Comments
COMMENT ON TABLE system.api_keys IS 'API key management for YouTube API';
COMMENT ON TABLE system.sync_logs IS 'Data synchronization tracking';

-- Grants
GRANT ALL ON SCHEMA system TO ytempire_user;
GRANT ALL ON ALL TABLES IN SCHEMA system TO ytempire_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA system TO ytempire_user;