-- 04-content-schema.sql: Content management schema
-- YTEmpire MVP Content Tables
-- Purpose: YouTube channel and video metadata management

\c ytempire_dev;

-- Content status enums
CREATE TYPE content.content_status AS ENUM ('draft', 'scheduled', 'published', 'unlisted', 'private', 'deleted');
CREATE TYPE content.video_category AS ENUM ('education', 'entertainment', 'gaming', 'music', 'news', 'sports', 'technology', 'other');

-- YouTube channels table
CREATE TABLE content.channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id),
    youtube_channel_id VARCHAR(255) UNIQUE NOT NULL,
    channel_title VARCHAR(500) NOT NULL,
    channel_description TEXT,
    channel_thumbnail_url VARCHAR(500),
    channel_banner_url VARCHAR(500),
    custom_url VARCHAR(255),
    country VARCHAR(2),
    published_at TIMESTAMP WITH TIME ZONE,
    view_count BIGINT DEFAULT 0,
    subscriber_count BIGINT DEFAULT 0,
    video_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_synced_at TIMESTAMP WITH TIME ZONE,
    youtube_api_quota_used INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- YouTube videos table
CREATE TABLE content.videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES content.channels(id) ON DELETE CASCADE,
    youtube_video_id VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    thumbnail_url VARCHAR(500),
    duration INTEGER, -- in seconds
    status content.content_status DEFAULT 'published',
    category content.video_category DEFAULT 'other',
    tags TEXT[],
    published_at TIMESTAMP WITH TIME ZONE,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    view_count BIGINT DEFAULT 0,
    like_count BIGINT DEFAULT 0,
    dislike_count BIGINT DEFAULT 0,
    comment_count BIGINT DEFAULT 0,
    is_live_content BOOLEAN DEFAULT FALSE,
    is_shorts BOOLEAN DEFAULT FALSE,
    language VARCHAR(10),
    captions_available BOOLEAN DEFAULT FALSE,
    age_restricted BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Video thumbnails management
CREATE TABLE content.thumbnails (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID NOT NULL REFERENCES content.videos(id) ON DELETE CASCADE,
    url VARCHAR(500) NOT NULL,
    width INTEGER,
    height INTEGER,
    quality VARCHAR(50),
    is_custom BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Content playlists
CREATE TABLE content.playlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES content.channels(id) ON DELETE CASCADE,
    youtube_playlist_id VARCHAR(255) UNIQUE,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    thumbnail_url VARCHAR(500),
    video_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    position INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Playlist videos mapping
CREATE TABLE content.playlist_videos (
    playlist_id UUID NOT NULL REFERENCES content.playlists(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES content.videos(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (playlist_id, video_id)
);

-- Content comments (for tracking)
CREATE TABLE content.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID NOT NULL REFERENCES content.videos(id) ON DELETE CASCADE,
    youtube_comment_id VARCHAR(255) UNIQUE NOT NULL,
    author_name VARCHAR(255),
    author_channel_id VARCHAR(255),
    text_content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_hearted BOOLEAN DEFAULT FALSE,
    is_reply BOOLEAN DEFAULT FALSE,
    parent_comment_id UUID REFERENCES content.comments(id),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes
CREATE INDEX idx_channels_user ON content.channels(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_channels_youtube_id ON content.channels(youtube_channel_id);
CREATE INDEX idx_videos_channel ON content.videos(channel_id);
CREATE INDEX idx_videos_youtube_id ON content.videos(youtube_video_id);
CREATE INDEX idx_videos_published ON content.videos(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_videos_status ON content.videos(status);
CREATE INDEX idx_videos_tags ON content.videos USING gin(tags);
CREATE INDEX idx_videos_metadata ON content.videos USING gin(metadata);
CREATE INDEX idx_comments_video ON content.comments(video_id);
CREATE INDEX idx_comments_published ON content.comments(published_at DESC);
CREATE INDEX idx_playlist_videos_playlist ON content.playlist_videos(playlist_id);
CREATE INDEX idx_playlist_videos_video ON content.playlist_videos(video_id);

-- Full text search indexes
CREATE INDEX idx_videos_title_search ON content.videos USING gin(to_tsvector('english', title));
CREATE INDEX idx_videos_description_search ON content.videos USING gin(to_tsvector('english', description));
CREATE INDEX idx_channels_title_search ON content.channels USING gin(to_tsvector('english', channel_title));

-- Update triggers
CREATE TRIGGER update_channels_updated_at
    BEFORE UPDATE ON content.channels
    FOR EACH ROW
    EXECUTE FUNCTION users.update_updated_at();

CREATE TRIGGER update_videos_updated_at
    BEFORE UPDATE ON content.videos
    FOR EACH ROW
    EXECUTE FUNCTION users.update_updated_at();

CREATE TRIGGER update_playlists_updated_at
    BEFORE UPDATE ON content.playlists
    FOR EACH ROW
    EXECUTE FUNCTION users.update_updated_at();