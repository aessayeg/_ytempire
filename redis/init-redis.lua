-- Redis Initialization Script for YTEmpire
-- Sets up initial data structures and configurations

-- YouTube API Cache Configuration
-- Cache keys follow pattern: yt:api:{endpoint}:{params_hash}
-- Example: yt:api:channels:UC123456
redis.call('CONFIG', 'SET', 'maxmemory-policy', 'allkeys-lru')

-- Create cache statistics hash
redis.call('HSET', 'yt:cache:stats', 'hits', 0)
redis.call('HSET', 'yt:cache:stats', 'misses', 0)
redis.call('HSET', 'yt:cache:stats', 'evictions', 0)
redis.call('HSET', 'yt:cache:stats', 'api_calls_saved', 0)

-- Session configuration
-- Sessions follow pattern: session:{session_id}
redis.call('HSET', 'yt:config:session', 'ttl', 3600)  -- 1 hour default
redis.call('HSET', 'yt:config:session', 'extend_on_activity', 'true')
redis.call('HSET', 'yt:config:session', 'max_concurrent', 5)

-- Rate limiting configuration
-- Rate limit keys: ratelimit:{user_id}:{action}
redis.call('HSET', 'yt:config:ratelimit', 'api_calls_per_minute', 60)
redis.call('HSET', 'yt:config:ratelimit', 'uploads_per_hour', 10)
redis.call('HSET', 'yt:config:ratelimit', 'analytics_queries_per_minute', 30)

-- Real-time analytics pub/sub channels
redis.call('PUBLISH', 'yt:realtime:system', 'Redis initialized for YTEmpire')

-- Cache TTL configurations (in seconds)
redis.call('HSET', 'yt:config:cache_ttl', 'channel_data', 1800)        -- 30 minutes
redis.call('HSET', 'yt:config:cache_ttl', 'video_metadata', 3600)      -- 1 hour
redis.call('HSET', 'yt:config:cache_ttl', 'analytics_data', 300)       -- 5 minutes
redis.call('HSET', 'yt:config:cache_ttl', 'search_results', 900)       -- 15 minutes
redis.call('HSET', 'yt:config:cache_ttl', 'trending_data', 600)        -- 10 minutes
redis.call('HSET', 'yt:config:cache_ttl', 'user_profile', 7200)        -- 2 hours

-- Queue configurations for background jobs
redis.call('HSET', 'yt:config:queues', 'video_processing', 'active')
redis.call('HSET', 'yt:config:queues', 'analytics_update', 'active')
redis.call('HSET', 'yt:config:queues', 'thumbnail_generation', 'active')
redis.call('HSET', 'yt:config:queues', 'email_notifications', 'active')

-- Feature flags
redis.call('HSET', 'yt:features', 'real_time_analytics', 'enabled')
redis.call('HSET', 'yt:features', 'ai_recommendations', 'disabled')
redis.call('HSET', 'yt:features', 'bulk_upload', 'enabled')
redis.call('HSET', 'yt:features', 'advanced_search', 'enabled')

-- API quota tracking
redis.call('HSET', 'yt:api:quota', 'daily_limit', 10000)
redis.call('HSET', 'yt:api:quota', 'current_usage', 0)
redis.call('HSET', 'yt:api:quota', 'reset_time', os.time() + 86400)

return "YTEmpire Redis initialization completed"