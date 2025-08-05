-- YTEmpire Redis Initialization Script
-- Sets up initial cache structures and Lua scripts

-- Initialize cache statistics
redis.call('HSET', 'yt:cache:stats', 'hits', 0)
redis.call('HSET', 'yt:cache:stats', 'misses', 0)
redis.call('HSET', 'yt:cache:stats', 'total_requests', 0)
redis.call('HSET', 'yt:cache:stats', 'initialized_at', os.time())

-- Create cache namespaces documentation
redis.call('SET', 'yt:namespaces:doc', [[
YTEmpire Cache Namespaces:
- yt:channel:{id} - Channel metadata cache (30min TTL)
- yt:video:{id} - Video metadata cache (30min TTL)
- yt:analytics:{type}:{id}:{period} - Analytics data cache (5min TTL)
- session:{id} - User session data (1hr TTL)
- rate:{user}:{endpoint} - Rate limiting counters (1min TTL)
- cache:query:{hash} - Query result cache (5min TTL)
]])

-- Rate limiting script
local rate_limit_script = [[
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local current_time = tonumber(ARGV[3])

-- Remove old entries outside the window
redis.call('ZREMRANGEBYSCORE', key, 0, current_time - window)

-- Count current entries
local current_count = redis.call('ZCARD', key)

if current_count < limit then
    -- Add new entry
    redis.call('ZADD', key, current_time, current_time)
    redis.call('EXPIRE', key, window)
    return 1
else
    -- Get oldest entry to calculate wait time
    local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
    if #oldest > 0 then
        local reset_time = oldest[2] + window
        return {0, reset_time - current_time}
    end
    return {0, window}
end
]]

-- Store the rate limiting script
redis.call('SET', 'yt:scripts:rate_limit', rate_limit_script)

-- Cache invalidation pattern script
local invalidate_pattern_script = [[
local pattern = KEYS[1]
local cursor = "0"
local count = 0

repeat
    local result = redis.call("SCAN", cursor, "MATCH", pattern, "COUNT", 100)
    cursor = result[1]
    local keys = result[2]
    
    if #keys > 0 then
        count = count + #keys
        redis.call("DEL", unpack(keys))
    end
until cursor == "0"

return count
]]

-- Store the invalidation script
redis.call('SET', 'yt:scripts:invalidate_pattern', invalidate_pattern_script)

-- Atomic cache update script
local cache_update_script = [[
local key = KEYS[1]
local value = ARGV[1]
local ttl = tonumber(ARGV[2])
local update_stats = ARGV[3] == "true"

-- Set the value with TTL
redis.call('SETEX', key, ttl, value)

-- Update cache statistics if requested
if update_stats then
    redis.call('HINCRBY', 'yt:cache:stats', 'writes', 1)
end

-- Add to cache index for tracking
local cache_type = string.match(key, "^([^:]+:[^:]+)")
if cache_type then
    redis.call('SADD', 'yt:cache:index:' .. cache_type, key)
    redis.call('EXPIRE', 'yt:cache:index:' .. cache_type, 86400) -- 24 hours
end

return "OK"
]]

-- Store the cache update script
redis.call('SET', 'yt:scripts:cache_update', cache_update_script)

-- Initialize configuration values
redis.call('HSET', 'yt:config', 'youtube_api_ttl', '1800')    -- 30 minutes
redis.call('HSET', 'yt:config', 'analytics_ttl', '300')       -- 5 minutes
redis.call('HSET', 'yt:config', 'session_ttl', '3600')        -- 1 hour
redis.call('HSET', 'yt:config', 'query_cache_ttl', '300')     -- 5 minutes
redis.call('HSET', 'yt:config', 'rate_limit_window', '60')    -- 1 minute
redis.call('HSET', 'yt:config', 'rate_limit_max', '100')      -- 100 requests per minute

-- Log initialization
redis.call('LPUSH', 'yt:logs:init', 'Redis initialized at ' .. os.date('%Y-%m-%d %H:%M:%S'))
redis.call('LTRIM', 'yt:logs:init', 0, 99) -- Keep last 100 logs

return "YTEmpire Redis initialization completed"