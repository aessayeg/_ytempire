# YTEmpire Database Schema Documentation

## Overview

YTEmpire uses a multi-schema PostgreSQL architecture with Redis caching layer. The database is designed for scalability, performance, and data integrity.

## Schema Organization

The database is organized into five main schemas:

1. **`users`** - User management and authentication
2. **`content`** - YouTube content metadata (channels, videos, playlists)
3. **`analytics`** - Performance metrics with time-series partitioning
4. **`campaigns`** - Marketing campaign management
5. **`system`** - System configuration and operational data

## Detailed Schema Reference

### Users Schema

#### users.accounts
Core user account management table.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| account_id | UUID | PRIMARY KEY | Unique account identifier |
| email | VARCHAR(255) | UNIQUE NOT NULL | User email address |
| username | VARCHAR(100) | UNIQUE NOT NULL | Display username |
| password_hash | VARCHAR(255) | NOT NULL | Bcrypt password hash |
| account_type | VARCHAR(50) | NOT NULL | 'creator', 'manager', 'admin' |
| account_status | VARCHAR(50) | DEFAULT 'active' | 'active', 'suspended', 'pending' |
| subscription_tier | VARCHAR(50) | DEFAULT 'free' | 'free', 'pro', 'enterprise' |
| created_at | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | Account creation time |
| updated_at | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | Last update time |
| last_login_at | TIMESTAMP WITH TIME ZONE | | Last login timestamp |
| email_verified | BOOLEAN | DEFAULT FALSE | Email verification status |
| two_factor_enabled | BOOLEAN | DEFAULT FALSE | 2FA status |

#### users.profiles
Extended user profile information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| profile_id | UUID | PRIMARY KEY | Profile identifier |
| account_id | UUID | REFERENCES users.accounts | Associated account |
| first_name | VARCHAR(100) | | User's first name |
| last_name | VARCHAR(100) | | User's last name |
| display_name | VARCHAR(150) | | Public display name |
| bio | TEXT | | User biography |
| avatar_url | VARCHAR(500) | | Profile picture URL |
| timezone | VARCHAR(50) | DEFAULT 'UTC' | User's timezone |
| language | VARCHAR(10) | DEFAULT 'en' | Preferred language |
| company_name | VARCHAR(200) | | Company/organization |
| website_url | VARCHAR(500) | | Personal/company website |

#### users.sessions
Active user sessions for authentication.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| session_id | UUID | PRIMARY KEY | Session identifier |
| account_id | UUID | REFERENCES users.accounts | User account |
| session_token | VARCHAR(255) | UNIQUE NOT NULL | Session token |
| ip_address | INET | | Client IP address |
| user_agent | TEXT | | Browser user agent |
| created_at | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | Session start |
| expires_at | TIMESTAMP WITH TIME ZONE | NOT NULL | Session expiration |
| is_active | BOOLEAN | DEFAULT TRUE | Session active status |

### Content Schema

#### content.channels
YouTube channel management.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| channel_id | UUID | PRIMARY KEY | Internal channel ID |
| account_id | UUID | REFERENCES users.accounts | Channel owner |
| youtube_channel_id | VARCHAR(100) | UNIQUE NOT NULL | YouTube channel ID |
| channel_name | VARCHAR(200) | NOT NULL | Channel display name |
| channel_handle | VARCHAR(100) | UNIQUE | YouTube @handle |
| description | TEXT | | Channel description |
| thumbnail_url | VARCHAR(500) | | Channel thumbnail |
| banner_url | VARCHAR(500) | | Channel banner image |
| subscriber_count | BIGINT | DEFAULT 0 | Current subscribers |
| video_count | INTEGER | DEFAULT 0 | Total videos |
| view_count | BIGINT | DEFAULT 0 | Total channel views |
| country | VARCHAR(10) | | Channel country |
| language | VARCHAR(10) | | Primary language |
| category | VARCHAR(100) | | Channel category |
| created_date | DATE | | Channel creation date |
| status | VARCHAR(50) | DEFAULT 'active' | Channel status |
| last_sync_at | TIMESTAMP WITH TIME ZONE | | Last API sync |

#### content.videos
Individual video metadata.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| video_id | UUID | PRIMARY KEY | Internal video ID |
| channel_id | UUID | REFERENCES content.channels | Parent channel |
| youtube_video_id | VARCHAR(100) | UNIQUE NOT NULL | YouTube video ID |
| title | VARCHAR(500) | NOT NULL | Video title |
| description | TEXT | | Video description |
| thumbnail_url | VARCHAR(500) | | Video thumbnail |
| duration_seconds | INTEGER | | Video duration |
| published_at | TIMESTAMP WITH TIME ZONE | | Publication time |
| privacy_status | VARCHAR(50) | | 'public', 'unlisted', 'private' |
| category_id | INTEGER | | YouTube category ID |
| category_name | VARCHAR(100) | | Category name |
| view_count | BIGINT | DEFAULT 0 | Current views |
| like_count | INTEGER | DEFAULT 0 | Current likes |
| comment_count | INTEGER | DEFAULT 0 | Current comments |
| tags | TEXT[] | | Array of video tags |

#### content.playlists
YouTube playlist organization.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| playlist_id | UUID | PRIMARY KEY | Internal playlist ID |
| channel_id | UUID | REFERENCES content.channels | Parent channel |
| youtube_playlist_id | VARCHAR(100) | UNIQUE NOT NULL | YouTube playlist ID |
| title | VARCHAR(200) | NOT NULL | Playlist title |
| description | TEXT | | Playlist description |
| privacy_status | VARCHAR(50) | | 'public', 'unlisted', 'private' |
| video_count | INTEGER | DEFAULT 0 | Videos in playlist |

### Analytics Schema (Partitioned)

#### analytics.channel_analytics
Daily channel performance metrics. **Partitioned by month**.

| Column | Type | Description |
|--------|------|-------------|
| analytics_id | UUID | Record identifier |
| channel_id | UUID | Channel reference |
| date | DATE | Metric date |
| views | BIGINT | Daily views |
| watch_time_minutes | BIGINT | Total watch time |
| subscribers_gained | INTEGER | New subscribers |
| subscribers_lost | INTEGER | Lost subscribers |
| estimated_revenue | DECIMAL(10,2) | Revenue estimate |
| impressions | BIGINT | Video impressions |
| click_through_rate | DECIMAL(5,4) | CTR percentage |
| comments | INTEGER | New comments |
| likes | INTEGER | New likes |
| shares | INTEGER | Video shares |

#### analytics.video_analytics
Daily video performance metrics. **Partitioned by month**.

| Column | Type | Description |
|--------|------|-------------|
| analytics_id | UUID | Record identifier |
| video_id | UUID | Video reference |
| date | DATE | Metric date |
| views | BIGINT | Daily views |
| watch_time_minutes | BIGINT | Watch time |
| estimated_revenue | DECIMAL(10,2) | Revenue estimate |
| audience_retention_percentage | DECIMAL(5,2) | Retention % |
| likes | INTEGER | New likes |
| comments | INTEGER | New comments |
| subscribers_gained | INTEGER | Subscribers from video |

#### analytics.audience_demographics
Audience demographic breakdown. **Partitioned by month**.

| Column | Type | Description |
|--------|------|-------------|
| demographic_id | UUID | Record identifier |
| channel_id | UUID | Channel reference |
| date | DATE | Analysis date |
| age_group | VARCHAR(20) | Age range |
| gender | VARCHAR(20) | Gender category |
| country_code | VARCHAR(10) | Country ISO code |
| percentage | DECIMAL(5,2) | Audience percentage |
| view_percentage | DECIMAL(5,2) | Views percentage |

### Campaigns Schema

#### campaigns.campaigns
Marketing campaign definitions.

| Column | Type | Description |
|--------|------|-------------|
| campaign_id | UUID | Campaign identifier |
| account_id | UUID | Campaign owner |
| campaign_name | VARCHAR(200) | Campaign name |
| campaign_type | VARCHAR(50) | 'promotion', 'monetization', 'growth' |
| start_date | DATE | Campaign start |
| end_date | DATE | Campaign end |
| budget | DECIMAL(10,2) | Campaign budget |
| status | VARCHAR(50) | Campaign status |
| target_metrics | JSONB | Flexible metric targets |

### System Schema

#### system.api_keys
YouTube API key management.

| Column | Type | Description |
|--------|------|-------------|
| api_key_id | UUID | Key identifier |
| account_id | UUID | Key owner |
| key_name | VARCHAR(100) | Key description |
| api_key_hash | VARCHAR(255) | Encrypted key |
| service_type | VARCHAR(50) | 'youtube_data', 'youtube_analytics' |
| quota_limit | INTEGER | Daily quota limit |
| quota_used | INTEGER | Current usage |
| is_active | BOOLEAN | Key active status |

#### system.sync_logs
Data synchronization tracking.

| Column | Type | Description |
|--------|------|-------------|
| sync_id | UUID | Sync operation ID |
| entity_type | VARCHAR(50) | 'channel', 'video', 'analytics' |
| entity_id | UUID | Entity reference |
| sync_type | VARCHAR(50) | 'full', 'incremental' |
| sync_status | VARCHAR(50) | Operation status |
| records_processed | INTEGER | Records processed |
| error_message | TEXT | Error details if failed |
| execution_time_ms | INTEGER | Sync duration |

## Partitioning Strategy

Analytics tables are partitioned by month for optimal performance:

```sql
-- Example partition for January 2024
CREATE TABLE analytics.channel_analytics_2024_01 
PARTITION OF analytics.channel_analytics 
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

New partitions are created automatically via the `auto_create_monthly_partitions()` function.

## Key Indexes

### Performance-Critical Indexes
- `idx_channels_youtube_id` - Fast channel lookup
- `idx_videos_channel_published` - Video listing by date
- `idx_channel_analytics_date` - Time-series queries
- `idx_sessions_token` - Session validation

### Full-Text Search Indexes
- `idx_channels_search` - Channel name/description search
- `idx_videos_search` - Video title/description search

### Specialized Indexes
- GIN index on `videos.tags` for tag searches
- BRIN indexes on analytics date columns for space efficiency
- Partial indexes for active records only

## Materialized Views

### analytics.channel_overview
Pre-aggregated channel metrics for dashboard performance:
- 30-day views, revenue, and engagement
- Refreshed via `refresh_analytics_views()` function

## Data Types and Standards

- **UUIDs**: All primary keys use UUID v4
- **Timestamps**: All with timezone (TIMESTAMP WITH TIME ZONE)
- **Money**: DECIMAL(10,2) for currency values
- **Percentages**: DECIMAL(5,2) or DECIMAL(5,4) for rates
- **Arrays**: PostgreSQL native arrays for tags
- **JSON**: JSONB for flexible/extensible data

## Security Considerations

1. **Row-Level Security**: Ready for implementation per tenant
2. **Encryption**: Password hashes use bcrypt
3. **API Keys**: Stored as hashes, never plain text
4. **Audit Trail**: All tables have created_at/updated_at
5. **Permissions**: Least privilege principle via PostgreSQL roles

## Migration Path

For existing installations, use the migration script:
```bash
psql -U ytempire_user -d ytempire_dev -f database/migrations/migrate-to-new-schema.sql
```

## Best Practices

1. **Always use UUIDs** for new entities
2. **Include timezone** in all timestamps
3. **Use transactions** for multi-table operations
4. **Partition analytics tables** monthly
5. **Create indexes** for foreign keys and common queries
6. **Use JSONB** sparingly for truly dynamic data
7. **Implement soft deletes** where appropriate