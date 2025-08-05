-- YTEmpire Content Schema
-- Video and channel content management tables

-- content.channels table
CREATE TABLE content.channels (
    channel_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id         UUID NOT NULL REFERENCES users.accounts(account_id),
    youtube_channel_id VARCHAR(100) UNIQUE NOT NULL,
    channel_name       VARCHAR(200) NOT NULL,
    channel_handle     VARCHAR(100) UNIQUE,
    description        TEXT,
    thumbnail_url      VARCHAR(500),
    banner_url         VARCHAR(500),
    subscriber_count   BIGINT DEFAULT 0,
    video_count        INTEGER DEFAULT 0,
    view_count         BIGINT DEFAULT 0,
    country            VARCHAR(10),
    language           VARCHAR(10),
    category           VARCHAR(100),
    created_date       DATE,
    status             VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    last_sync_at       TIMESTAMP WITH TIME ZONE,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- content.videos table
CREATE TABLE content.videos (
    video_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id         UUID NOT NULL REFERENCES content.channels(channel_id) ON DELETE CASCADE,
    youtube_video_id   VARCHAR(100) UNIQUE NOT NULL,
    title              VARCHAR(500) NOT NULL,
    description        TEXT,
    thumbnail_url      VARCHAR(500),
    duration_seconds   INTEGER,
    published_at       TIMESTAMP WITH TIME ZONE,
    privacy_status     VARCHAR(50) CHECK (privacy_status IN ('public', 'unlisted', 'private')),
    category_id        INTEGER,
    category_name      VARCHAR(100),
    language           VARCHAR(10),
    caption_status     VARCHAR(50),
    definition         VARCHAR(10) CHECK (definition IN ('hd', 'sd')),
    dimension          VARCHAR(10) CHECK (dimension IN ('2d', '3d')),
    licensed_content   BOOLEAN DEFAULT FALSE,
    upload_status      VARCHAR(50) DEFAULT 'processed',
    view_count         BIGINT DEFAULT 0,
    like_count         INTEGER DEFAULT 0,
    comment_count      INTEGER DEFAULT 0,
    favorite_count     INTEGER DEFAULT 0,
    tags               TEXT[], -- Array of tags
    last_sync_at       TIMESTAMP WITH TIME ZONE,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- content.playlists table
CREATE TABLE content.playlists (
    playlist_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id         UUID NOT NULL REFERENCES content.channels(channel_id) ON DELETE CASCADE,
    youtube_playlist_id VARCHAR(100) UNIQUE NOT NULL,
    title              VARCHAR(200) NOT NULL,
    description        TEXT,
    thumbnail_url      VARCHAR(500),
    privacy_status     VARCHAR(50) CHECK (privacy_status IN ('public', 'unlisted', 'private')),
    video_count        INTEGER DEFAULT 0,
    published_at       TIMESTAMP WITH TIME ZONE,
    last_sync_at       TIMESTAMP WITH TIME ZONE,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- content.playlist_videos table
CREATE TABLE content.playlist_videos (
    playlist_video_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playlist_id        UUID NOT NULL REFERENCES content.playlists(playlist_id) ON DELETE CASCADE,
    video_id           UUID NOT NULL REFERENCES content.videos(video_id) ON DELETE CASCADE,
    position           INTEGER NOT NULL,
    added_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(playlist_id, video_id)
);

-- Create indexes
CREATE INDEX idx_channels_youtube_id ON content.channels(youtube_channel_id);
CREATE INDEX idx_channels_account ON content.channels(account_id);
CREATE INDEX idx_channels_status ON content.channels(status) WHERE status = 'active';
CREATE INDEX idx_channels_handle ON content.channels(channel_handle) WHERE channel_handle IS NOT NULL;

CREATE INDEX idx_videos_youtube_id ON content.videos(youtube_video_id);
CREATE INDEX idx_videos_channel_published ON content.videos(channel_id, published_at DESC);
CREATE INDEX idx_videos_privacy ON content.videos(privacy_status);
CREATE INDEX idx_videos_tags ON content.videos USING GIN(tags);
CREATE INDEX idx_videos_published ON content.videos(published_at DESC) WHERE privacy_status = 'public';

CREATE INDEX idx_playlists_channel ON content.playlists(channel_id);
CREATE INDEX idx_playlists_youtube_id ON content.playlists(youtube_playlist_id);

CREATE INDEX idx_playlist_videos_playlist ON content.playlist_videos(playlist_id);
CREATE INDEX idx_playlist_videos_video ON content.playlist_videos(video_id);
CREATE INDEX idx_playlist_videos_position ON content.playlist_videos(playlist_id, position);

-- Create triggers
CREATE TRIGGER update_channels_timestamp 
    BEFORE UPDATE ON content.channels 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_videos_timestamp 
    BEFORE UPDATE ON content.videos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_playlists_timestamp 
    BEFORE UPDATE ON content.playlists 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Comments
COMMENT ON TABLE content.channels IS 'YouTube channel management';
COMMENT ON TABLE content.videos IS 'Individual video content management';
COMMENT ON TABLE content.playlists IS 'YouTube playlist management';
COMMENT ON TABLE content.playlist_videos IS 'Many-to-many relationship between playlists and videos';

-- Grants
GRANT ALL ON SCHEMA content TO ytempire_user;
GRANT ALL ON ALL TABLES IN SCHEMA content TO ytempire_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA content TO ytempire_user;