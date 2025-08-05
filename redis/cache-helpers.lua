-- Redis Cache Helper Functions for YTEmpire
-- Lua scripts for atomic cache operations

-- Function: Cache YouTube API Response with TTL
-- KEYS[1] = cache key, ARGV[1] = data (JSON), ARGV[2] = ttl, ARGV[3] = endpoint_type
local cache_api_response = [[
    local key = KEYS[1]
    local data = ARGV[1]
    local ttl = tonumber(ARGV[2])
    local endpoint_type = ARGV[3]
    
    -- Store the data
    redis.call('SETEX', key, ttl, data)
    
    -- Update cache statistics
    redis.call('HINCRBY', 'yt:cache:stats', 'cached_items', 1)
    redis.call('HINCRBY', 'yt:cache:stats:' .. endpoint_type, 'count', 1)
    
    -- Track cache key in set for bulk operations
    redis.call('SADD', 'yt:cache:keys:' .. endpoint_type, key)
    redis.call('EXPIRE', 'yt:cache:keys:' .. endpoint_type, 86400)
    
    return 'OK'
]]

-- Function: Get Cached Data with Hit/Miss Tracking
-- KEYS[1] = cache key, ARGV[1] = endpoint_type
local get_cached_data = [[
    local key = KEYS[1]
    local endpoint_type = ARGV[1]
    local data = redis.call('GET', key)
    
    if data then
        -- Cache hit
        redis.call('HINCRBY', 'yt:cache:stats', 'hits', 1)
        redis.call('HINCRBY', 'yt:cache:stats:' .. endpoint_type, 'hits', 1)
        
        -- Extend TTL on access (optional LRU behavior)
        local ttl = redis.call('TTL', key)
        if ttl > 0 and ttl < 300 then
            redis.call('EXPIRE', key, 300)
        end
        
        return data
    else
        -- Cache miss
        redis.call('HINCRBY', 'yt:cache:stats', 'misses', 1)
        redis.call('HINCRBY', 'yt:cache:stats:' .. endpoint_type, 'misses', 1)
        
        return nil
    end
]]

-- Function: Session Management with Activity Tracking
-- KEYS[1] = session key, ARGV[1] = user_data (JSON), ARGV[2] = ttl
local manage_session = [[
    local session_key = KEYS[1]
    local user_data = ARGV[1]
    local ttl = tonumber(ARGV[2]) or 3600
    
    -- Parse user data to get user_id
    local user_info = cjson.decode(user_data)
    local user_id = user_info.user_id
    
    -- Check concurrent sessions
    local user_sessions_key = 'yt:user:sessions:' .. user_id
    local current_sessions = redis.call('SCARD', user_sessions_key)
    local max_concurrent = tonumber(redis.call('HGET', 'yt:config:session', 'max_concurrent') or 5)
    
    if current_sessions >= max_concurrent then
        -- Remove oldest session
        local sessions = redis.call('SMEMBERS', user_sessions_key)
        local oldest_session = sessions[1]
        local oldest_time = redis.call('HGET', oldest_session, 'last_activity')
        
        for i, session in ipairs(sessions) do
            local activity_time = redis.call('HGET', session, 'last_activity')
            if activity_time < oldest_time then
                oldest_session = session
                oldest_time = activity_time
            end
        end
        
        redis.call('DEL', oldest_session)
        redis.call('SREM', user_sessions_key, oldest_session)
    end
    
    -- Create session
    redis.call('HSET', session_key, 'user_data', user_data)
    redis.call('HSET', session_key, 'created_at', os.time())
    redis.call('HSET', session_key, 'last_activity', os.time())
    redis.call('EXPIRE', session_key, ttl)
    
    -- Track session
    redis.call('SADD', user_sessions_key, session_key)
    redis.call('EXPIRE', user_sessions_key, ttl)
    
    return 'OK'
]]

-- Function: Rate Limiting with Sliding Window
-- KEYS[1] = rate limit key, ARGV[1] = limit, ARGV[2] = window (seconds)
local check_rate_limit = [[
    local key = KEYS[1]
    local limit = tonumber(ARGV[1])
    local window = tonumber(ARGV[2])
    local now = redis.call('TIME')
    local timestamp = now[1] * 1000 + math.floor(now[2] / 1000)
    
    -- Remove old entries
    redis.call('ZREMRANGEBYSCORE', key, 0, timestamp - window * 1000)
    
    -- Count current entries
    local current = redis.call('ZCARD', key)
    
    if current < limit then
        -- Add new entry
        redis.call('ZADD', key, timestamp, timestamp)
        redis.call('EXPIRE', key, window)
        return {1, limit - current - 1}  -- {allowed, remaining}
    else
        -- Get oldest entry to calculate retry time
        local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
        local retry_after = math.ceil((oldest[2] + window * 1000 - timestamp) / 1000)
        return {0, 0, retry_after}  -- {allowed, remaining, retry_after}
    end
]]

-- Function: Invalidate Cache by Pattern
-- KEYS[1] = pattern, ARGV[1] = endpoint_type
local invalidate_cache = [[
    local pattern = KEYS[1]
    local endpoint_type = ARGV[1]
    local cursor = "0"
    local count = 0
    
    repeat
        local result = redis.call('SCAN', cursor, 'MATCH', pattern, 'COUNT', 100)
        cursor = result[1]
        local keys = result[2]
        
        for i, key in ipairs(keys) do
            redis.call('DEL', key)
            redis.call('SREM', 'yt:cache:keys:' .. endpoint_type, key)
            count = count + 1
        end
    until cursor == "0"
    
    redis.call('HINCRBY', 'yt:cache:stats', 'invalidations', count)
    return count
]]

-- Function: Get Real-time Analytics
-- KEYS[1] = metric_key, ARGV[1] = time_window (seconds)
local get_realtime_metrics = [[
    local metric_key = KEYS[1]
    local window = tonumber(ARGV[1]) or 300  -- 5 minutes default
    local now = redis.call('TIME')
    local timestamp = now[1]
    
    -- Get all metrics within window
    local metrics = redis.call('ZRANGEBYSCORE', metric_key, 
                              timestamp - window, timestamp, 'WITHSCORES')
    
    -- Calculate aggregates
    local count = 0
    local sum = 0
    local min = nil
    local max = nil
    
    for i = 1, #metrics, 2 do
        local value = tonumber(metrics[i])
        count = count + 1
        sum = sum + value
        
        if not min or value < min then min = value end
        if not max or value > max then max = value end
    end
    
    local avg = count > 0 and sum / count or 0
    
    return cjson.encode({
        count = count,
        sum = sum,
        avg = avg,
        min = min or 0,
        max = max or 0,
        window = window
    })
]]

-- Register all scripts
redis.call('SCRIPT', 'LOAD', cache_api_response)
redis.call('SCRIPT', 'LOAD', get_cached_data)
redis.call('SCRIPT', 'LOAD', manage_session)
redis.call('SCRIPT', 'LOAD', check_rate_limit)
redis.call('SCRIPT', 'LOAD', invalidate_cache)
redis.call('SCRIPT', 'LOAD', get_realtime_metrics)

return "Cache helper scripts loaded successfully"